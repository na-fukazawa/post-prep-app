import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'x_auth_store.dart';
import 'x_oauth_config.dart';

class XAuthException implements Exception {
  final String message;
  const XAuthException(this.message);

  @override
  String toString() => message;
}

class XAuthService {
  XAuthService(this._store, this._appLinks);

  final XAuthStore _store;
  final AppLinks _appLinks;

  Future<XAuthToken?> loadToken() => _store.readToken();

  Future<bool> hasSession() async {
    final account = await _store.readActiveAccount();
    return account != null && !account.token.isExpired;
  }

  Future<void> signOut() => _store.clear();

  Future<String?> getValidAccessToken() async {
    final account = await _store.readActiveAccount();
    if (account == null) return null;
    final token = account.token;
    if (!token.isExpired) return token.accessToken;
    if (token.refreshToken.isEmpty) return null;
    final refreshed = await _refreshToken(token.refreshToken);
    await _store.updateToken(account.userId, refreshed);
    return refreshed.accessToken;
  }

  Future<XAuthToken> signIn() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _codeChallenge(codeVerifier);
    final state = _randomString(16);
    final authorizationUri = Uri.parse(XOAuthConfig.authorizeEndpoint).replace(
      queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': XOAuthConfig.clientId,
        'redirect_uri': XOAuthConfig.redirectUri,
        'scope': XOAuthConfig.scopes.join(' '),
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    final completer = Completer<Uri>();
    StreamSubscription<Uri>? subscription;

    Future<void> tryComplete(Uri uri) async {
      if (completer.isCompleted) return;
      if (!_matchesRedirect(uri)) return;
      final returnedState = uri.queryParameters['state'];
      if (returnedState == null || returnedState.isEmpty || returnedState != state) {
        return;
      }
      completer.complete(uri);
      await subscription?.cancel();
    }

    subscription = _appLinks.uriLinkStream.listen((uri) {
      tryComplete(uri);
    });

    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      await tryComplete(initial);
    }

    final launched = await launchUrl(authorizationUri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await subscription?.cancel();
      throw const XAuthException('ブラウザを開けませんでした。');
    }

    final redirectUri = await completer.future.timeout(const Duration(minutes: 2), onTimeout: () async {
      await subscription?.cancel();
      throw const XAuthException('認証がタイムアウトしました。');
    });

    final error = redirectUri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      throw XAuthException('認証に失敗しました: $error');
    }
    final returnedState = redirectUri.queryParameters['state'];
    if (returnedState != state) {
      throw const XAuthException('認証状態が一致しません。');
    }
    final code = redirectUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const XAuthException('認証コードを取得できませんでした。');
    }

    final token = await _exchangeCodeForToken(code, codeVerifier);
    return token;
  }

  bool _matchesRedirect(Uri uri) {
    return uri.scheme == Uri.parse(XOAuthConfig.redirectUri).scheme &&
        uri.host == Uri.parse(XOAuthConfig.redirectUri).host &&
        uri.path == Uri.parse(XOAuthConfig.redirectUri).path;
  }

  Future<XAuthToken> _exchangeCodeForToken(String code, String verifier) async {
    final body = _encodeForm(<String, String>{
      'client_id': XOAuthConfig.clientId,
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': XOAuthConfig.redirectUri,
      'code_verifier': verifier,
    });
    return _requestToken(body);
  }

  Future<XAuthToken> _refreshToken(String refreshToken) async {
    final body = _encodeForm(<String, String>{
      'client_id': XOAuthConfig.clientId,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    });
    return _requestToken(body);
  }

  Future<XAuthToken> _requestToken(String body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(XOAuthConfig.tokenEndpoint));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded');
      request.add(utf8.encode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw XAuthException('トークン取得に失敗しました: ${response.statusCode}');
      }
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final accessToken = decoded['access_token'] as String?;
      final refreshToken = decoded['refresh_token'] as String?;
      final expiresIn = (decoded['expires_in'] as num?)?.toInt();
      final scope = decoded['scope'] as String? ?? '';
      final tokenType = decoded['token_type'] as String? ?? 'bearer';
      if (accessToken == null || refreshToken == null || expiresIn == null) {
        throw const XAuthException('トークン応答が不完全です。');
      }
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
      return XAuthToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        scope: scope,
        tokenType: tokenType,
      );
    } on SocketException {
      throw const XAuthException('ネットワークに接続できません。');
    } finally {
      client.close(force: true);
    }
  }

  String _encodeForm(Map<String, String> params) {
    return params.entries
        .map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
  }

  String _generateCodeVerifier() {
    final bytes = List<int>.generate(64, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _codeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
