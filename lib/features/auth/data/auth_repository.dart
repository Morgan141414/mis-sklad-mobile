import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  final ApiClient _api;
  final TokenStorage _tokens;

  AuthRepository({ApiClient? api, TokenStorage? tokens})
      : _api = api ?? ApiClient(),
        _tokens = tokens ?? TokenStorage();

  /// Login to MIS, then exchange MIS JWT for a sklad JWT.
  /// [orgId] is the active organization UUID from the MIS user's profile.
  Future<SkladActor> login({
    required String email,
    required String password,
    required String orgId,
  }) async {
    await _api.misLogin(email, password);
    await _api.exchangeForSkladToken(orgId);
    return actor();
  }

  /// Re-exchange an existing MIS token for a fresh sklad token.
  Future<void> refreshSkladToken(String orgId) =>
      _api.exchangeForSkladToken(orgId);

  Future<SkladActor> actor() async {
    final me = await _api.skladGet('/me');
    return SkladActor.fromJson(me);
  }

  Future<bool> isLoggedIn() async {
    final t = await _tokens.getSkladToken();
    return t != null;
  }

  Future<void> logout() => _tokens.clearAll();
}

class SkladActor {
  final String actorId;
  final List<String> roles;
  final List<int> warehouseIds;
  final List<String> permissions;

  const SkladActor({
    required this.actorId,
    required this.roles,
    required this.warehouseIds,
    required this.permissions,
  });

  factory SkladActor.fromJson(Map<String, dynamic> j) => SkladActor(
        actorId: j['actor_id'] as String,
        roles: List<String>.from(j['roles'] as List),
        warehouseIds: List<int>.from(j['warehouse_ids'] as List),
        permissions: List<String>.from(j['permissions'] as List),
      );

  bool get isManager => roles.contains('warehouse_manager');
  bool get isHeadNurse => roles.contains('head_nurse');
  bool get canReceive =>
      isManager || isHeadNurse || roles.contains('head_nurse');
  bool get canWriteOff =>
      isManager || isHeadNurse || roles.contains('nurse') ||
      roles.contains('other');
}
