abstract interface class ApiClient {
  Future<dynamic> get(String path);
  Future<dynamic> post(String path, {Map<String, dynamic>? body});
  Future<dynamic> patch(String path, {Map<String, dynamic>? body});
  Future<dynamic> put(String path, {Map<String, dynamic>? body});
  Future<void> clearTokens();
  Future<void> logout();
  Future<bool> hasAccessToken();
  Future<bool> refreshSession();
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String code,
    required String password,
  });
  Future<void> requestSignupCode({
    required String name,
    required String phone,
    required String email,
  });
  Future<void> requestPasswordReset({required String email});
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });
}
