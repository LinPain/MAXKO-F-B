import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class SignupView extends GetView<AuthController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 28,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 28),

                  const Text(
                    'Tạo tài khoản',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Tham gia MAXKO F&B ngay hôm nay',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildLabel('Họ và tên'),

                  const SizedBox(height: 8),

                  TextField(
                    controller: controller.signupNameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hintText: 'Nhập họ và tên',
                      icon: Icons.person_outline,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildLabel('Email'),

                  const SizedBox(height: 8),

                  Obx(() => TextField(
                        controller: controller.signupEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        readOnly: controller.signupCodeSent.value,
                        decoration: _inputDecoration(
                          hintText: 'Nhập email',
                          icon: Icons.email_outlined,
                        ),
                      )),

                  Obx(() {
                    if (!controller.signupCodeSent.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        _buildLabel('Mã xác thực demo'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller.signupCodeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => controller.signup(),
                          autofillHints: const [AutofillHints.oneTimeCode],
                          maxLength: 6,
                          decoration: _inputDecoration(
                            hintText: 'Nhập mã demo 123456',
                            icon: Icons.verified_user_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  controller.signupCodeSent.value = false;
                                  controller.signupCodeController.clear();
                                },
                                child: const Text('Đổi email'),
                              ),
                              TextButton(
                                onPressed: controller.requestSignupCode,
                                child: const Text('Gửi lại mã'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  _buildLabel('Số điện thoại'),

                  const SizedBox(height: 8),

                  TextField(
                    controller: controller.signupPhoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hintText: 'Nhập số điện thoại',
                      icon: Icons.phone_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildLabel('Mật khẩu'),

                  const SizedBox(height: 8),

                  Obx(
                        () => TextField(
                      controller: controller.signupPasswordController,
                      obscureText:
                      !controller.signupPasswordVisible.value,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hintText: 'Tạo mật khẩu',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed:
                          controller.toggleSignupPassword,
                          icon: Icon(
                            controller.signupPasswordVisible.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildLabel('Xác nhận mật khẩu'),

                  const SizedBox(height: 8),

                  Obx(
                        () => TextField(
                      controller:
                      controller.signupConfirmPasswordController,
                      obscureText:
                      !controller.signupConfirmPasswordVisible.value,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.signup(),
                      decoration: _inputDecoration(
                        hintText: 'Nhập lại mật khẩu',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed:
                          controller.toggleSignupConfirmPassword,
                          icon: Icon(
                            controller.signupConfirmPasswordVisible.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Obx(
                        () => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: controller.agreeToTerms.value,
                          onChanged: (value) {
                            controller.agreeToTerms.value =
                                value ?? false;
                          },
                          activeColor: AppColors.primary,
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 11),
                            child: Text(
                              'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Obx(() => SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : controller.signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  controller.signupCodeSent.value
                                      ? 'Tạo tài khoản'
                                      : 'Gửi mã xác thực',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () {
                      Get.offNamed(AppRoutes.main);
                    },
                    child: const Text(
                      'Tiếp tục với tư cách khách',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(
            child: Text(
              'LG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'MAXKO F&B GROUP',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'PREMIUM TEA & BOBA',
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}
