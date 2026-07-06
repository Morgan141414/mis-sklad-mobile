import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final TokenStorage _tokens;
  final http.Client _http;

  ApiClient({TokenStorage? tokenStorage, http.Client? httpClient})
      : _tokens = tokenStorage ?? TokenStorage(),
        _http = httpClient ?? http.Client();

  // ── MIS auth ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> misLogin(String email, String password) async {
    final resp = await _http.post(
      Uri.parse('${AppConfig.misBaseUrl}${AppConfig.misLoginPath}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    final body = _decode(resp);
    await _tokens.saveMisTokens(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
    );
    return body;
  }

  Future<void> refreshMisToken() async {
    final refresh = await _tokens.getMisRefreshToken();
    if (refresh == null) throw const ApiException(401, 'No refresh token');
    final resp = await _http.post(
      Uri.parse('${AppConfig.misBaseUrl}${AppConfig.misRefreshPath}'),
      headers: {'Authorization': 'Bearer $refresh'},
    );
    final body = _decode(resp);
    await _tokens.saveMisTokens(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String? ?? refresh,
    );
  }

  // ── Sklad SSO exchange ────────────────────────────────────────────────────

  Future<String> exchangeForSkladToken(String orgId) async {
    final misToken = await _tokens.getMisAccessToken();
    if (misToken == null) throw const ApiException(401, 'Not logged in');
    final resp = await _http.post(
      Uri.parse('${AppConfig.misBaseUrl}${AppConfig.skladTokenExchangePath}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $misToken',
      },
      body: jsonEncode({'org_id': orgId}),
    );
    final body = _decode(resp);
    final token = body['access_token'] as String;
    await _tokens.saveSkladToken(token);
    return token;
  }

  // ── Sklad API ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> skladGet(String path) async {
    final token = await _ensureSkladToken();
    final resp = await _http.get(
      Uri.parse('${AppConfig.skladBaseUrl}${AppConfig.skladApiBase}$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> skladPost(
      String path, Map<String, dynamic> body) async {
    final token = await _ensureSkladToken();
    final resp = await _http.post(
      Uri.parse('${AppConfig.skladBaseUrl}${AppConfig.skladApiBase}$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _decode(resp);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> _ensureSkladToken() async {
    final token = await _tokens.getSkladToken();
    if (token == null) throw const ApiException(401, 'Sklad token missing');
    return token;
  }

  Map<String, dynamic> _decode(http.Response resp) {
    final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (resp.statusCode >= 400) {
      final msg = body['detail'] is String
          ? body['detail'] as String
          : (body['detail'] as Map?)?.values.first?.toString() ?? 'Error';
      throw ApiException(resp.statusCode, msg);
    }
    return body;
  }
}
