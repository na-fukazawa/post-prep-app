import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class XAuthToken {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String scope;
  final String tokenType;

  const XAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.scope,
    required this.tokenType,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class XAuthStore {
  static const _accountsKey = 'x_oauth_accounts_v2';
  static const _activeUserIdKey = 'x_oauth_active_user_id';
  static const _accessTokenKey = 'x_oauth_access_token';
  static const _refreshTokenKey = 'x_oauth_refresh_token';
  static const _expiresAtKey = 'x_oauth_expires_at';
  static const _scopeKey = 'x_oauth_scope';
  static const _tokenTypeKey = 'x_oauth_token_type';

  final FlutterSecureStorage _storage;

  XAuthStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<List<XAccount>> readAccounts() async {
    final raw = await _storage.read(key: _accountsKey);
    if (raw == null || raw.isEmpty) {
      final legacy = await _readLegacyToken();
      if (legacy == null) return <XAccount>[];
      final legacyAccount = XAccount(
        userId: 'legacy',
        username: 'linked',
        name: 'Linked account',
        profileImageUrl: null,
        token: legacy,
      );
      await _storage.write(
        key: _accountsKey,
        value: jsonEncode([legacyAccount.toJson()]),
      );
      await setActiveUser(legacyAccount.userId);
      return <XAccount>[legacyAccount];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => XAccount.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <XAccount>[];
    }
  }

  Future<XAccount?> readActiveAccount() async {
    final accounts = await readAccounts();
    if (accounts.isEmpty) return null;
    final activeId = await _storage.read(key: _activeUserIdKey);
    if (activeId == null || activeId.isEmpty) {
      await setActiveUser(accounts.first.userId);
      return accounts.first;
    }
    final match = accounts.where((account) => account.userId == activeId).toList();
    if (match.isEmpty) {
      await setActiveUser(accounts.first.userId);
      return accounts.first;
    }
    return match.first;
  }

  Future<void> setActiveUser(String userId) async {
    await _storage.write(key: _activeUserIdKey, value: userId);
  }

  Future<void> saveAccount(
    XAccount account, {
    bool makeActive = true,
    bool clearLegacy = true,
  }) async {
    final accounts = await readAccounts();
    final next = [...accounts];
    final idx = next.indexWhere((item) => item.userId == account.userId);
    if (idx >= 0) {
      next[idx] = account;
    } else {
      next.add(account);
    }
    await _storage.write(key: _accountsKey, value: jsonEncode(next.map((e) => e.toJson()).toList()));
    if (makeActive) {
      await setActiveUser(account.userId);
    }
    if (clearLegacy) {
      await _clearLegacyToken();
    }
  }

  Future<void> updateToken(String userId, XAuthToken token) async {
    final accounts = await readAccounts();
    final idx = accounts.indexWhere((account) => account.userId == userId);
    if (idx < 0) return;
    final account = accounts[idx];
    accounts[idx] = account.copyWith(token: token);
    await _storage.write(key: _accountsKey, value: jsonEncode(accounts.map((e) => e.toJson()).toList()));
  }

  Future<void> removeAccount(String userId) async {
    final accounts = await readAccounts();
    accounts.removeWhere((account) => account.userId == userId);
    await _storage.write(key: _accountsKey, value: jsonEncode(accounts.map((e) => e.toJson()).toList()));
    final activeId = await _storage.read(key: _activeUserIdKey);
    if (activeId == userId) {
      if (accounts.isNotEmpty) {
        await setActiveUser(accounts.first.userId);
      } else {
        await _storage.delete(key: _activeUserIdKey);
      }
    }
  }

  Future<XAuthToken?> readToken() async {
    final account = await readActiveAccount();
    return account?.token;
  }

  Future<XAuthToken?> _readLegacyToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final scope = await _storage.read(key: _scopeKey);
    final tokenType = await _storage.read(key: _tokenTypeKey);
    if (accessToken == null || refreshToken == null || expiresAtRaw == null || scope == null || tokenType == null) {
      return null;
    }
    final expiresAtMillis = int.tryParse(expiresAtRaw);
    if (expiresAtMillis == null) return null;
    return XAuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMillis),
      scope: scope,
      tokenType: tokenType,
    );
  }

  Future<void> _clearLegacyToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _scopeKey);
    await _storage.delete(key: _tokenTypeKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accountsKey);
    await _storage.delete(key: _activeUserIdKey);
    await _clearLegacyToken();
  }
}

class XAccount {
  final String userId;
  final String username;
  final String name;
  final String? profileImageUrl;
  final XAuthToken token;

  const XAccount({
    required this.userId,
    required this.username,
    required this.name,
    required this.profileImageUrl,
    required this.token,
  });

  XAccount copyWith({
    String? userId,
    String? username,
    String? name,
    String? profileImageUrl,
    XAuthToken? token,
  }) {
    return XAccount(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'name': name,
        'profileImageUrl': profileImageUrl,
        'accessToken': token.accessToken,
        'refreshToken': token.refreshToken,
        'expiresAt': token.expiresAt.millisecondsSinceEpoch,
        'scope': token.scope,
        'tokenType': token.tokenType,
      };

  factory XAccount.fromJson(Map<String, dynamic> json) {
    return XAccount(
      userId: json['userId'] as String,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      token: XAuthToken(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
        scope: json['scope'] as String? ?? '',
        tokenType: json['tokenType'] as String? ?? 'bearer',
      ),
    );
  }
}
