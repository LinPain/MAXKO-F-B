import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildLogo(),
                  const SizedBox(height: 28),
                  Obx(() => Text(
                        controller.resetCodeSent.value
                            ? 'Xác thực email'
                            : 'Quên mật khẩu?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      )),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                        controller.resetCodeSent.value
                            ? 'Nhập mã demo 123456 và tạo mật khẩu mới để xem trước quy trình.'
                            : 'Nhập email đăng ký để tạo mã xác thực demo. Không gửi email trong chế độ xem trước.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      )),
                  const SizedBox(height: 28),
                  _label('Email'),
                  const SizedBox(height: 8),
                  Obx(() => TextField(
                        controller: controller.resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: controller.resetCodeSent.value
                            ? TextInputAction.next
                            : TextInputAction.done,
                        readOnly: controller.resetCodeSent.value,
                        onSubmitted: (_) {
                          if (!controller.resetCodeSent.value) {
                            controller.requestPasswordReset();
                          }
                        },
                        decoration: _inputDecoration(
                          hintText: 'name@example.com',
                          icon: Icons.email_outlined,
                        ),
                      )),
                  Obx(() {
                    if (!controller.resetCodeSent.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        _label('Mã xác thực'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller.resetCodeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          maxLength: 6,
                          decoration: _inputDecoration(
                            hintText: 'Nhập mã gồm 6 chữ số',
                            icon: Icons.verified_user_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 14),
                        _label('Mật khẩu mới'),
                        const SizedBox(height: 8),
                        Obx(() => TextField(
                              controller: controller.resetPasswordController,
                              obscureText:
                                  !controller.resetPasswordVisible.value,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hintText: 'Ít nhất 8 ký tự',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  onPressed: controller
                                      .resetPasswordVisible.toggle,
                                  icon: Icon(
                                    controller.resetPasswordVisible.value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 14),
                        _label('Xác nhận mật khẩu mới'),
                        const SizedBox(height: 8),
                        Obx(() => TextField(
                              controller:
                                  controller.resetConfirmPasswordController,
                              obscureText: !controller
                                  .resetConfirmPasswordVisible.value,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  controller.submitPasswordReset(),
                              decoration: _inputDecoration(
                                hintText: 'Nhập lại mật khẩu mới',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  onPressed: controller
                                      .resetConfirmPasswordVisible.toggle,
                                  icon: Icon(
                                    controller.resetConfirmPasswordVisible
                                            .value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            )),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: controller.requestPasswordReset,
                            child: const Text(
                              'Gửi lại mã',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 18),
                  Obx(() => SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : controller.resetCodeSent.value
                                  ? controller.submitPasswordReset
                                  : controller.requestPasswordReset,
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
                                  controller.resetCodeSent.value
                                      ? 'Đặt lại mật khẩu'
                                      : 'Gửi mã xác thực',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: Get.back,
                    child: const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
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

  Widget _buildLogo() => Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Center(
              child: Text(
                'LG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}
