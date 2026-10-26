import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../account/controllers/account_controller.dart';
import '../../orders/controllers/orders_controller.dart';

class AuthController extends GetxController {
  static const demoVerificationCode = '123456';

  final isSubmitting = false.obs;
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final signupNameController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPhoneController = TextEditingController();
  final signupPasswordController = TextEditingController();
  final signupConfirmPasswordController = TextEditingController();
  final resetEmailController = TextEditingController();
  final resetCodeController = TextEditingController();
  final resetPasswordController = TextEditingController();
  final resetConfirmPasswordController = TextEditingController();
  final signupCodeController = TextEditingController();

  final loginPasswordVisible = false.obs;
  final signupPasswordVisible = false.obs;
  final signupConfirmPasswordVisible = false.obs;

  final rememberMe = false.obs;
  final agreeToTerms = false.obs;
  final resetCodeSent = false.obs;
  final resetPasswordVisible = false.obs;
  final resetConfirmPasswordVisible = false.obs;
  final signupCodeSent = false.obs;

  @override
  void onInit() {
    super.onInit();
    final email = Get.arguments;
    if (email is String && email.trim().isNotEmpty) {
      resetEmailController.text = email.trim();
    }
  }

  Future<void> requestPasswordReset() async {
    final email = resetEmailController.text.trim();
    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Email chưa hợp lệ',
        'Vui lòng nhập địa chỉ email chính xác.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      resetCodeSent.value = true;
      Get.snackbar(
        'Mã demo đã sẵn sàng',
        'Nhập mã $demoVerificationCode để xem tiếp quy trình đặt lại mật khẩu.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Chưa gửi được mã',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> submitPasswordReset() async {
    final email = resetEmailController.text.trim();
    final code = resetCodeController.text.trim();
    final password = resetPasswordController.text;
    if (code.length != 6 || int.tryParse(code) == null) {
      Get.snackbar(
        'Mã chưa hợp lệ',
        'Nhập mã xác thực gồm 6 chữ số.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (password.length < 8) {
      Get.snackbar(
        'Mật khẩu quá ngắn',
        'Mật khẩu mới cần ít nhất 8 ký tự.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (password != resetConfirmPasswordController.text) {
      Get.snackbar(
        'Mật khẩu không khớp',
        'Vui lòng nhập lại mật khẩu xác nhận.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Email chưa hợp lệ',
        'Vui lòng nhập email hợp lệ trước khi xác nhận mã demo.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      if (!resetCodeSent.value || code != demoVerificationCode) {
        throw Exception('Mã demo không đúng. Hãy dùng $demoVerificationCode.');
      }
      Get.snackbar(
        'Đổi mật khẩu demo thành công',
        'Quy trình đã hoàn tất. Thông tin chỉ dùng trong phiên xem trước.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offNamed(AppRoutes.login);
    } catch (error) {
      Get.snackbar(
        'Không thể đổi mật khẩu',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void toggleLoginPassword() {
    loginPasswordVisible.toggle();
  }

  void toggleSignupPassword() {
    signupPasswordVisible.toggle();
  }

  void toggleSignupConfirmPassword() {
    signupConfirmPasswordVisible.toggle();
  }

  Future<void> login() async {
    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng nhập email và mật khẩu.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      if (!GetUtils.isEmail(email)) {
        throw Exception('Vui lòng nhập email hợp lệ.');
      }
      _setSignedInUser({
        'name': _nameFromEmail(email),
        'email': email,
        'phone': '0900000000',
        'membershipTier': 'GOLD',
        'loyaltyPoints': 1250,
      });
      Get.offAllNamed(AppRoutes.main);
    } catch (error) {
      Get.snackbar(
        'Đăng nhập thất bại',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> signup() async {
    final name = signupNameController.text.trim();
    final email = signupEmailController.text.trim();
    final phone = signupPhoneController.text.trim();
    final password = signupPasswordController.text;
    final confirmPassword = signupConfirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng điền đầy đủ thông tin.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        'Mật khẩu không khớp',
        'Vui lòng kiểm tra lại mật khẩu xác nhận.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!agreeToTerms.value) {
      Get.snackbar(
        'Chưa đồng ý điều khoản',
        'Vui lòng đồng ý với điều khoản sử dụng.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Email chưa hợp lệ',
        'Vui lòng nhập địa chỉ email chính xác.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!signupCodeSent.value) {
      await requestSignupCode();
      return;
    }

    final code = signupCodeController.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      Get.snackbar(
        'Mã chưa hợp lệ',
        'Nhập mã xác thực gồm 6 chữ số.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      if (code != demoVerificationCode) {
        throw Exception('Mã demo không đúng. Hãy dùng $demoVerificationCode.');
      }
      _setSignedInUser({
        'name': name,
        'email': email,
        'phone': phone,
        'membershipTier': 'BRONZE',
        'loyaltyPoints': 120,
      });
      signupCodeSent.value = false;
      Get.offAllNamed(AppRoutes.main);
    } catch (error) {
      Get.snackbar(
        'Đăng ký thất bại',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> requestSignupCode() async {
    final name = signupNameController.text.trim();
    final email = signupEmailController.text.trim();
    final phone = signupPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Thiếu thông tin',
        'Nhập họ tên, email hợp lệ và số điện thoại trước.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      signupCodeSent.value = true;
      Get.snackbar(
        'Mã demo đã sẵn sàng',
        'Nhập mã $demoVerificationCode để hoàn tất đăng ký xem trước.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Chưa gửi được mã',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _setSignedInUser(Map user) {
    if (!Get.isRegistered<AccountController>()) {
      Get.put<AccountController>(
        AccountController(),
        permanent: true,
      );
    }
    Get.find<AccountController>().setProfile(
      username: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString() ?? '',
      id: '',
      tier: user['membershipTier']?.toString() ?? 'BRONZE',
      points: (user['loyaltyPoints'] as num?)?.toInt() ?? 0,
      birthday: user['birthday']?.toString(),
      gender: user['gender']?.toString() ?? 'unspecified',
    );
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().loadMyOrders();
    }
  }

  String _nameFromEmail(String email) {
    final localPart = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    if (localPart.isEmpty) return 'Khách MAXKO';
    return localPart
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();

    signupNameController.dispose();
    signupEmailController.dispose();
    signupPhoneController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();
    resetEmailController.dispose();
    resetCodeController.dispose();
    resetPasswordController.dispose();
    resetConfirmPasswordController.dispose();
    signupCodeController.dispose();

    super.onClose();
  }
}
