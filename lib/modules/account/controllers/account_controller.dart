import 'package:get/get.dart';

class AccountController extends GetxController {
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
    loadVouchers();
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
    if (name != null) username.value = name;
    if (phone != null) this.phone.value = phone;
    if (birthday != null || clearBirthday) this.birthday.value = clearBirthday ? null : birthday;
    if (gender != null) this.gender.value = gender;
  }

  Future<void> loadNotificationPreferences() async {
    // Demo preferences are held in memory until an account service is connected.
  }

  Future<void> updateNotificationPreferences(Map<String, bool> preferences) async {
    notificationPreferences.assignAll(preferences);
  }

  Future<void> loadSavedAddresses() async {
    if (savedAddresses.isEmpty) {
      savedAddresses.assignAll([
        {'label': 'Nhà', 'address': '128 Cầu Giấy, Hà Nội'},
        {'label': 'Công ty', 'address': 'Tòa nhà Keangnam, Hà Nội'},
      ]);
    }
  }

  Future<void> updateSavedAddresses(List<Map<String, dynamic>> addresses) async {
    savedAddresses.assignAll(
      addresses.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  Future<void> loadMembershipDetails() async {
    if (pointsHistory.isEmpty) {
      pointsHistory.assignAll([
        {'title': 'Đơn hàng MAXKO', 'points': 24, 'date': 'Hôm nay'},
        {'title': 'Ưu đãi thành viên', 'points': 50, 'date': 'Tuần này'},
      ]);
    }
  }

  Future<void> loadVouchers() async {
    vouchers.assignAll([
      {'code': 'MAXKO20', 'title': 'Giảm 20%', 'description': 'Đơn từ 80.000đ'},
      {'code': 'FREESHIP', 'title': 'Miễn phí giao hàng', 'description': 'Đơn từ 100.000đ'},
    ]);
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
    isLoggedIn.value = false;
    username.value = '';
    phone.value = '';
    email.value = '';
    birthday.value = null;
    gender.value = 'unspecified';
    notificationPreferences.assignAll({'push': true, 'email': true, 'sms': false});
    customerId.value = '';
    membershipTier.value = 'BRONZE';
    loyaltyPoints.value = 0;
    pointsHistory.clear();
    savedAddresses.clear();
    loadVouchers();
  }
}
