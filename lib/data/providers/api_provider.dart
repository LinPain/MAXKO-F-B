import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_http_client.dart';

class ApiProvider implements ApiClient {
  ApiProvider({required this.baseUrl, http.Client? client})
    : _client = client ?? createApiHttpClient();

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _refreshCookieKey = 'maxkoRefreshCookie';
  String? _accessToken;
  Future<bool>? _refreshInProgress;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Client-Platform': 'mobile',
  };

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<dynamic> get(String path) => _request('GET', path);

  Future<List<dynamic>> getProducts() async {
    final data = await get('/api/products');
    if (data is! List) throw Exception('Danh sách sản phẩm không hợp lệ.');
    return data;
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _request('POST', path, body: body);
  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) =>
      _request('PATCH', path, body: body);
  @override
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _request('PUT', path, body: body);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    final headers = <String, String>{..._headers};
    if (_accessToken?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (method == 'POST' && path == '/api/orders/batch-checkout') {
      final idempotencyKey = body?['idempotencyKey']?.toString();
      if (idempotencyKey?.isNotEmpty == true) {
        headers['Idempotency-Key'] = idempotencyKey!;
      }
    }
    if (!kIsWeb) {
      final refreshCookie = await _storage.read(key: _refreshCookieKey);
      if (refreshCookie?.isNotEmpty == true) {
        headers['Cookie'] = refreshCookie!;
      }
    }

    http.Response response;
    try {
      final uri = _uri(path);
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 15));
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw UnsupportedError('Unsupported method $method');
      }
    } on http.ClientException catch (error) {
      throw Exception('Không thể kết nối máy chủ: ${error.message}');
    } on TimeoutException {
      throw Exception('Kết nối máy chủ quá thời gian chờ.');
    }

    _captureSessionHeaders(response);
    if (response.statusCode == 401 && retry) {
      final refreshed = await refreshSession();
      if (refreshed) return _request(method, path, body: body, retry: false);
    }

    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['error'] ?? decoded['message'])
          : null;
      throw Exception(
        message?.toString() ?? 'API lỗi HTTP ${response.statusCode}.',
      );
    }
    if (decoded is Map && decoded['success'] == false) {
      throw Exception(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'Thao tác thất bại.',
      );
    }
    return decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw Exception(
        'Máy chủ trả về dữ liệu không hợp lệ (HTTP ${response.statusCode}).',
      );
    }
  }

  void _captureSessionHeaders(http.Response response) {
    final token = response.headers['x-access-token'];
    if (token != null && token.isNotEmpty) _accessToken = token;
    if (kIsWeb) return;
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;
    final match = RegExp(r'(?:^|,\s*)(?:refreshToken|refresh_token)=([^;]+)')
        .firstMatch(setCookie);
    if (match != null) {
      unawaited(_storage.write(
        key: _refreshCookieKey,
        value: 'refreshToken=${match.group(1)}',
      ));
    }
  }

  @override
  Future<bool> refreshSession() async {
    final pending = _refreshInProgress;
    if (pending != null) return pending;
    final completer = Completer<bool>();
    _refreshInProgress = completer.future;
    try {
      final headers = <String, String>{..._headers};
      if (!kIsWeb) {
        final cookie = await _storage.read(key: _refreshCookieKey);
        if (cookie == null || cookie.isEmpty) {
          completer.complete(false);
          return false;
        }
        headers['Cookie'] = cookie;
      }
      final response = await _client
          .post(_uri('/api/auth/refresh'), headers: headers, body: '{}')
          .timeout(const Duration(seconds: 20));
      _captureSessionHeaders(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await clearTokens();
        completer.complete(false);
        return false;
      }
      final body = _decode(response);
      final data = body is Map ? body['data'] : null;
      if (_accessToken == null && data is Map) {
        _accessToken = data['accessToken']?.toString();
      }
      final refreshed = _accessToken?.isNotEmpty == true;
      if (!refreshed) await clearTokens();
      completer.complete(refreshed);
      return refreshed;
    } catch (_) {
      await clearTokens();
      completer.complete(false);
      return false;
    } finally {
      _refreshInProgress = null;
    }
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    await _storage.delete(key: _refreshCookieKey);
  }

  @override
  Future<void> logout() async {
    try {
      await post('/api/auth/logout');
    } finally {
      await clearTokens();
    }
  }

  @override
  Future<bool> hasAccessToken() async =>
      _accessToken?.isNotEmpty == true;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/api/auth/login',
      body: {'email': email, 'password': password},
      retry: false,
    );
    if (_accessToken == null && data is Map) {
      _accessToken = data['accessToken']?.toString();
    }
    if (_accessToken?.isNotEmpty != true) {
      throw Exception('API không trả header X-Access-Token.');
    }
    if (data is! Map) throw Exception('Phản hồi đăng nhập không đúng định dạng.');
    final result = Map<String, dynamic>.from(data);
    result['accessToken'] = _accessToken;
    result['user'] ??= result['customer'] ?? result;
    return result;
  }

  @override
  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String code,
    required String password,
  }) async {
    final data = await post('/api/auth/register', body: {
      'name': name,
      'phone': phone,
      'email': email,
      'code': code,
      'password': password,
    });
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Phản hồi đăng ký hội viên không đúng định dạng.');
  }

  @override
  Future<void> requestSignupCode({
    required String name,
    required String phone,
    required String email,
  }) async {
    await post('/api/auth/register/request-code', body: {
      'name': name,
      'phone': phone,
      'email': email,
    });
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await post('/api/auth/forgot-password', body: {'email': email});
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await post(
      '/api/auth/reset-password',
      body: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }
}
