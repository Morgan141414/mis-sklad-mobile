import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _misTokenKey = 'mis_access_token';
  static const _misRefreshKey = 'mis_refresh_token';
  static const _skladTokenKey = 'sklad_token';

  Future<void> saveMisTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _misTokenKey, value: accessToken),
      _storage.write(key: _misRefreshKey, value: refreshToken),
    ]);
  }

  Future<void> saveSkladToken(String token) =>
      _storage.write(key: _skladTokenKey, value: token);

  Future<String?> getMisAccessToken() => _storage.read(key: _misTokenKey);
  Future<String?> getMisRefreshToken() => _storage.read(key: _misRefreshKey);
  Future<String?> getSkladToken() => _storage.read(key: _skladTokenKey);

  Future<void> clearAll() => _storage.deleteAll();
}
