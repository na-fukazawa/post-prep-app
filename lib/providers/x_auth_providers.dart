import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/x_api_service.dart';
import '../services/x_auth_service.dart';
import '../services/x_auth_store.dart';

class XAuthState {
  final bool isConnected;
  final bool isBusy;
  final String? error;
  final List<XAccount> accounts;
  final XAccount? activeAccount;

  const XAuthState({
    required this.isConnected,
    required this.isBusy,
    required this.accounts,
    this.activeAccount,
    this.error,
  });

  factory XAuthState.initial() => const XAuthState(
        isConnected: false,
        isBusy: false,
        accounts: <XAccount>[],
        activeAccount: null,
        error: null,
      );

  XAuthState copyWith({
    bool? isConnected,
    bool? isBusy,
    String? error,
    List<XAccount>? accounts,
    XAccount? activeAccount,
  }) {
    return XAuthState(
      isConnected: isConnected ?? this.isConnected,
      isBusy: isBusy ?? this.isBusy,
      accounts: accounts ?? this.accounts,
      activeAccount: activeAccount ?? this.activeAccount,
      error: error,
    );
  }
}

final xAuthStoreProvider = Provider<XAuthStore>((ref) => XAuthStore());
final xAuthServiceProvider = Provider<XAuthService>(
  (ref) => XAuthService(ref.read(xAuthStoreProvider), AppLinks()),
);
final xApiServiceProvider = Provider<XApiService>(
  (ref) => XApiService(ref.read(xAuthServiceProvider)),
);

class XAuthNotifier extends StateNotifier<XAuthState> {
  XAuthNotifier(this._service, this._api, this._store) : super(XAuthState.initial());

  final XAuthService _service;
  final XApiService _api;
  final XAuthStore _store;

  Future<void> init() async {
    final accounts = await _store.readAccounts();
    final active = await _store.readActiveAccount();
    if (active != null && active.userId == 'legacy') {
      await _upgradeLegacyAccount(active);
    }
    final refreshedAccounts = await _store.readAccounts();
    final refreshedActive = await _store.readActiveAccount();
    state = state.copyWith(
      isConnected: refreshedActive != null && !refreshedActive.token.isExpired,
      accounts: refreshedAccounts,
      activeAccount: refreshedActive,
      isBusy: false,
      error: null,
    );
  }

  Future<bool> signIn() async {
    state = state.copyWith(isBusy: true, error: null);
    try {
      final token = await _service.signIn();
      final me = await _api.getCurrentUser(accessToken: token.accessToken);
      final account = XAccount(
        userId: me.id,
        username: me.username,
        name: me.name,
        profileImageUrl: me.profileImageUrl,
        token: token,
      );
      await _store.saveAccount(account, makeActive: true);
      final accounts = await _store.readAccounts();
      state = state.copyWith(
        isConnected: true,
        isBusy: false,
        error: null,
        accounts: accounts,
        activeAccount: account,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isConnected: false, isBusy: false, error: error.toString());
      return false;
    }
  }

  Future<void> switchAccount(String userId) async {
    await _store.setActiveUser(userId);
    final active = await _store.readActiveAccount();
    state = state.copyWith(
      isConnected: active != null && !active.token.isExpired,
      activeAccount: active,
      error: null,
    );
  }

  Future<void> removeAccount(String userId) async {
    await _store.removeAccount(userId);
    final accounts = await _store.readAccounts();
    final active = await _store.readActiveAccount();
    state = state.copyWith(
      accounts: accounts,
      activeAccount: active,
      isConnected: active != null && !active.token.isExpired,
      error: null,
    );
  }

  Future<void> signOut() async {
    final active = await _store.readActiveAccount();
    if (active != null) {
      await _store.removeAccount(active.userId);
    } else {
      await _service.signOut();
    }
    final accounts = await _store.readAccounts();
    final nextActive = await _store.readActiveAccount();
    state = state.copyWith(
      isConnected: nextActive != null && !nextActive.token.isExpired,
      accounts: accounts,
      activeAccount: nextActive,
      isBusy: false,
      error: null,
    );
  }

  Future<void> _upgradeLegacyAccount(XAccount legacy) async {
    try {
      final me = await _api.getCurrentUser();
      final upgraded = XAccount(
        userId: me.id,
        username: me.username,
        name: me.name,
        profileImageUrl: me.profileImageUrl,
        token: legacy.token,
      );
      await _store.removeAccount('legacy');
      await _store.saveAccount(upgraded, makeActive: true);
    } catch (_) {
      // keep legacy account if upgrade fails
    }
  }
}

final xAuthProvider = StateNotifierProvider<XAuthNotifier, XAuthState>(
  (ref) => XAuthNotifier(
    ref.read(xAuthServiceProvider),
    ref.read(xApiServiceProvider),
    ref.read(xAuthStoreProvider),
  ),
);
