import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_client.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSubmitting = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final apiProvider = Get.find<ApiClient>();
      await apiProvider.post(
        '/api/auth/change-password',
        body: {
          'currentPassword': _currentPassword.text,
          'newPassword': _newPassword.text,
        },
      );
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (!mounted) return;
      Get.snackbar(
        'Đổi mật khẩu thành công',
        'Mật khẩu tài khoản của bạn đã được cập nhật.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Chưa đổi được mật khẩu',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Cập nhật mật khẩu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Nhập mật khẩu hiện tại và mật khẩu mới để bảo mật tài khoản.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _passwordField(
                  label: 'Mật khẩu hiện tại',
                  controller: _currentPassword,
                  visible: _showCurrent,
                  toggle: () => setState(() => _showCurrent = !_showCurrent),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  label: 'Mật khẩu mới',
                  controller: _newPassword,
                  visible: _showNew,
                  toggle: () => setState(() => _showNew = !_showNew),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Mật khẩu mới cần ít nhất 8 ký tự.';
                    }
                    if (value == _currentPassword.text) {
                      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _passwordField(
                  label: 'Xác nhận mật khẩu mới',
                  controller: _confirmPassword,
                  visible: _showConfirm,
                  toggle: () => setState(() => _showConfirm = !_showConfirm),
                  validator: (value) => value != _newPassword.text
                      ? 'Mật khẩu xác nhận không khớp.'
                      : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Lưu mật khẩu mới',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator:
          validator ??
          (value) => value == null || value.isEmpty
              ? 'Vui lòng nhập mật khẩu hiện tại.'
              : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.primary,
        ),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
