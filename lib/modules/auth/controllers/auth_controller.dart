import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/providers/api_client.dart';
import '../../account/controllers/account_controller.dart';
import '../../orders/controllers/orders_controller.dart';

class AuthController extends GetxController {
  AuthController({required this.apiProvider});

  final ApiClient apiProvider;

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
      await apiProvider.requestPasswordReset(email: email);
      resetCodeSent.value = true;
      Get.snackbar(
        'Đã gửi yêu cầu',
        'Kiểm tra email để lấy reset token từ máy chủ.',
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
    if (code.isEmpty) {
      Get.snackbar(
        'Thiếu reset token',
        'Dán reset token đầy đủ đã nhận từ máy chủ.',
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
        'Vui lòng nhập email hợp lệ để xác nhận yêu cầu đặt lại mật khẩu.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      if (!resetCodeSent.value || code.isEmpty) {
        throw Exception('Nhập reset token đã nhận trong email.');
      }
      await apiProvider.resetPassword(
        resetToken: code,
        newPassword: password,
      );
      Get.snackbar(
        'Đổi mật khẩu thành công',
        'Bạn có thể đăng nhập bằng mật khẩu mới.',
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
      final response = await apiProvider.login(email: email, password: password);
      final user = response['user'];
      if (user is Map) _setSignedInUser(user);
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

  Future<void> requestSignupCode() async {
    final name = signupNameController.text.trim();
    final email = signupEmailController.text.trim();
    final phone = signupPhoneController.text.trim();
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng điền đầy đủ thông tin.',
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

    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      await apiProvider.requestSignupCode(name: name, phone: phone, email: email);
      signupCodeSent.value = true;
      Get.snackbar(
        'Đã gửi mã xác nhận',
        'Nhập mã trong email để hoàn tất đăng ký MAXKO.',
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

  Future<void> signup() async {
    final name = signupNameController.text.trim();
    final email = signupEmailController.text.trim();
    final phone = signupPhoneController.text.trim();
    if (!signupCodeSent.value) {
      await requestSignupCode();
      return;
    }
    if (signupCodeController.text.trim().length != 6) {
      Get.snackbar('Thiếu mã xác nhận', 'Nhập mã gồm 6 chữ số trong email.');
      return;
    }
    if (signupPasswordController.text.length < 8) {
      Get.snackbar('Mật khẩu quá ngắn', 'Mật khẩu cần ít nhất 8 ký tự.');
      return;
    }
    if (signupPasswordController.text != signupConfirmPasswordController.text) {
      Get.snackbar('Mật khẩu không khớp', 'Vui lòng nhập lại mật khẩu xác nhận.');
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final customer = await apiProvider.registerCustomer(
        name: name,
        phone: phone,
        email: email,
        code: signupCodeController.text.trim(),
        password: signupPasswordController.text,
      );
      final profile = customer['user'] is Map
          ? customer['user'] as Map
          : customer['customer'] is Map
          ? customer['customer'] as Map
          : customer;
      _setSignedInUser(profile);
      Get.snackbar(
        'Đăng ký thành công',
        'Tài khoản MAXKO của bạn đã sẵn sàng.',
        snackPosition: SnackPosition.BOTTOM,
      );
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

  void _setSignedInUser(Map user) {
    if (!Get.isRegistered<AccountController>()) {
      Get.put<AccountController>(
        AccountController(apiProvider: apiProvider),
        permanent: true,
      );
    }
    Get.find<AccountController>().setProfile(
      username: user['name']?.toString() ?? user['fullName']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString() ?? '',
      id: user['id']?.toString() ?? user['_id']?.toString() ?? user['customerId']?.toString() ?? '',
      tier: user['membershipTier']?.toString() ?? user['tier']?.toString() ?? 'BRONZE',
      points: (user['loyaltyPoints'] as num?)?.toInt() ?? (user['points'] as num?)?.toInt() ?? 0,
      birthday: user['birthday']?.toString(),
      gender: user['gender']?.toString() ?? 'unspecified',
    );
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().loadMyOrders();
    }
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

