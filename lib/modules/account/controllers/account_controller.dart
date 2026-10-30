import 'package:get/get.dart';

import '../../../data/providers/api_client.dart';

class AccountController extends GetxController {
  AccountController({required this.apiProvider});

  final ApiClient apiProvider;
  final isLoggedIn = false.obs;

  final username = ''.obs;
  final phone = ''.obs;
  final email = ''.obs;
  final birthday = Rxn<DateTime>();
  final gender = 'unspecified'.obs;
  final notificationPreferences = <String, bool>{
    'push': true,
    'email': true,
    'sms': false,
  }.obs;
  final password = ''.obs;
  final customerId = ''.obs;
  final membershipTier = 'BRONZE'.obs;
  final loyaltyPoints = 0.obs;
  final pointsHistory = <Map<String, dynamic>>[].obs;
  final vouchers = <Map<String, dynamic>>[].obs;
  final savedAddresses = <Map<String, dynamic>>[].obs;

  String get membershipTierLabel {
    switch (membershipTier.value.toUpperCase()) {
      case 'BRONZE':
        return 'ĐỒNG';
      case 'SILVER':
        return 'BẠC';
      case 'GOLD':
        return 'VÀNG';
      case 'PLATINUM':
        return 'BẠCH KIM';
      default:
        return membershipTier.value;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
    loadVouchers();
  }

  Future<void> _restoreSession() async {
    if (!await apiProvider.hasAccessToken() &&
        !await apiProvider.refreshSession()) {
      return;
    }
    try {
      final response = await apiProvider.get('/api/auth/me');
      final user = response is Map && response['user'] is Map
          ? response['user'] as Map
          : response;
      if (user is Map) {
        setProfile(
          username: user['name']?.toString() ?? '',
          email: user['email']?.toString() ?? '',
          phone: user['phone']?.toString() ?? '',
          id: user['id']?.toString() ?? user['_id']?.toString() ?? '',
          tier: user['membershipTier']?.toString() ?? 'BRONZE',
          points: (user['loyaltyPoints'] as num?)?.toInt() ?? 0,
          birthday: user['birthday']?.toString(),
          gender: user['gender']?.toString() ?? 'unspecified',
        );
      }
    } catch (_) {
      await apiProvider.clearTokens();
    }
  }

  void login() {
    Get.toNamed('/login');
  }

  void signup() {
    Get.toNamed('/signup');
  }

  void loginUser({
    required String username,
    required String email,
    required String phone,
    required String password,
  }) {
    this.username.value = username;
    this.email.value = email;
    this.phone.value = phone;
    this.password.value = '';
    isLoggedIn.value = true;
  }

  void setProfile({
    required String username,
    required String email,
    required String phone,
    String id = '',
    String tier = 'BRONZE',
    int points = 0,
    String? birthday,
    String gender = 'unspecified',
  }) {
    this.username.value = username;
    this.email.value = email;
    this.phone.value = phone;
    customerId.value = id;
    membershipTier.value = tier;
    loyaltyPoints.value = points;
    this.birthday.value = DateTime.tryParse(birthday ?? '');
    this.gender.value = gender;
    password.value = '';
    isLoggedIn.value = true;
    loadMembershipDetails();
    loadNotificationPreferences();
    loadSavedAddresses();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    DateTime? birthday,
    bool clearBirthday = false,
    String? gender,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (phone != null) updates['phone'] = phone.trim();
    if (gender != null) updates['gender'] = gender;
    if (birthday != null || clearBirthday) {
      updates['birthday'] = clearBirthday ? null : birthday!.toIso8601String();
    }
    if (updates.isEmpty) return;
    try {
      final response = await apiProvider.put('/api/auth/me', body: updates);
      final user = response is Map && response['user'] is Map
          ? Map<String, dynamic>.from(response['user'] as Map)
          : response is Map
          ? Map<String, dynamic>.from(response)
          : updates;
      username.value = user['name']?.toString() ?? username.value;
      this.phone.value = user['phone']?.toString() ?? this.phone.value;
      if (user.containsKey('birthday')) {
        this.birthday.value = DateTime.tryParse(
          user['birthday']?.toString() ?? '',
        );
      }
      if (user['gender'] != null) this.gender.value = user['gender'].toString();
      Get.snackbar('Đã cập nhật', 'Thông tin cá nhân đã được lưu.');
    } catch (_) {
      Get.snackbar(
        'Không thể lưu',
        'Thông tin cá nhân chưa được cập nhật trên máy chủ.',
      );
    }
  }

  Future<void> loadNotificationPreferences() async {
    if (!isLoggedIn.value) return;
    try {
      final data = await apiProvider.get(
        '/api/customers/me/notification-preferences',
      );
      if (data is Map) {
        notificationPreferences.assignAll(
          Map<String, bool>.from(
            data.map((key, value) => MapEntry(key.toString(), value == true)),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    try {
      final data = await apiProvider.put(
        '/api/customers/me/notification-preferences',
        body: preferences,
      );
      notificationPreferences.assignAll(
        data is Map
            ? Map<String, bool>.from(
                data.map(
                  (key, value) => MapEntry(key.toString(), value == true),
                ),
              )
            : preferences,
      );
    } catch (_) {
      Get.snackbar(
        'Không thể lưu',
        'Cài đặt thông báo chưa được cập nhật trên máy chủ.',
      );
    }
  }

  Future<void> loadSavedAddresses() async {
    if (!isLoggedIn.value) return;
    try {
      final data = await apiProvider.get('/api/customers/me/addresses');
      savedAddresses.assignAll(
        data is List
            ? data.whereType<Map>().map(
                (item) => Map<String, dynamic>.from(item),
              )
            : const <Map<String, dynamic>>[],
      );
    } catch (_) {
      savedAddresses.clear();
    }
  }

  Future<void> updateSavedAddresses(
    List<Map<String, dynamic>> addresses,
  ) async {
    try {
      final response = await apiProvider.put(
        '/api/customers/me/addresses',
        body: {'addresses': addresses},
      );
      final data = response is Map
          ? response['addresses'] ?? response
          : response;
      savedAddresses.assignAll(
        data is List
            ? data.whereType<Map>().map(
                (item) => Map<String, dynamic>.from(item),
              )
            : addresses,
      );
    } catch (_) {
      Get.snackbar('Không thể lưu', 'Địa chỉ chưa được cập nhật trên máy chủ.');
    }
  }

  Future<void> loadMembershipDetails() async {
    if (!isLoggedIn.value) {
      pointsHistory.clear();
      return;
    }
    try {
      final data = await apiProvider.get('/api/customers/me/membership');
      if (data is Map) {
        loyaltyPoints.value =
            (data['loyaltyPoints'] as num?)?.toInt() ?? loyaltyPoints.value;
        final history = data['pointsHistory'];
        if (history is List) {
          pointsHistory.assignAll(
            history.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
        }
        final membershipVouchers = data['vouchers'];
        if (membershipVouchers is List) {
          vouchers.assignAll(
            membershipVouchers.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> loadVouchers() async {
    if (!isLoggedIn.value) {
      vouchers.clear();
      return;
    }
    try {
      final response = await apiProvider.get(
        '/api/customers/vouchers?brandId=brand-legia',
      );
      final data = response is List
          ? response
          : response is Map && response['vouchers'] is List
          ? response['vouchers'] as List
          : const [];
      vouchers.assignAll(
        data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
      );
    } catch (_) {
      vouchers.clear();
    }
  }

  bool authenticate({required String identifier, required String password}) {
    final matchesUsername = username.value == identifier;
    final matchesEmail = email.value == identifier;
    final isValid =
        (matchesUsername || matchesEmail) && this.password.value == password;

    if (isValid) {
      isLoggedIn.value = true;
    }

    return isValid;
  }

  Future<void> logout() async {
    try {
      await apiProvider.logout();
    } catch (_) {
      await apiProvider.clearTokens();
    }
    isLoggedIn.value = false;
    username.value = '';
    phone.value = '';
    email.value = '';
    birthday.value = null;
    gender.value = 'unspecified';
    notificationPreferences.assignAll({
      'push': true,
      'email': true,
      'sms': false,
    });
    customerId.value = '';
    membershipTier.value = 'BRONZE';
    loyaltyPoints.value = 0;
    pointsHistory.clear();
    savedAddresses.clear();
    loadVouchers();
  }
}
