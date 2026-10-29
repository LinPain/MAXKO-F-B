import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../main/controllers/main_controller.dart';
import '../controllers/account_controller.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  late final AccountController controller;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  Worker? _nameWorker;
  Worker? _phoneWorker;
  int _selectedTab = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AccountController>();
    _name.text = controller.username.value;
    _phone.text = controller.phone.value;
    _nameWorker = ever<String>(
      controller.username,
      (value) => _name.text = value,
    );
    _phoneWorker = ever<String>(
      controller.phone,
      (value) => _phone.text = value,
    );
  }

  @override
  void dispose() {
    _nameWorker?.dispose();
    _phoneWorker?.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final signedIn = controller.isLoggedIn.value;
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                primary: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _pageHeader(),
                    const SizedBox(height: 8),
                    _memberCard(signedIn),
                    const SizedBox(height: 14),
                    if (!signedIn) ...[
                      _signInPrompt(),
                    ] else ...[
                      _tabs(),
                      const SizedBox(height: 14),
                      if (_selectedTab == 0)
                        _profileForm()
                      else
                        _securitySettings(),
                    ],
                    if (signedIn) ...[
                      const SizedBox(height: 14),
                      _logoutButton(),
                    ],
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'MAXKO F&B · Phiên bản 1.0.0',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _pageHeader() => Row(
    children: [
      const Expanded(
        child: Row(
          children: [
            Icon(Icons.local_cafe_rounded, color: AppColors.primary, size: 23),
            SizedBox(width: 8),
            Text(
              'MAXKO F&B GROUP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: _openNotifications,
        tooltip: 'Thông báo',
        icon: const Icon(Icons.notifications_none_rounded),
      ),
      IconButton(
        onPressed: Get.back,
        tooltip: 'Đóng',
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );

  Widget _memberCard(bool signedIn) {
    final tier = controller.membershipTierLabel;
    final points = controller.loyaltyPoints.value;
    final name = controller.username.value.isNotEmpty
        ? controller.username.value
        : 'Thành viên MAXKO';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E232A), Color(0xFF2C323B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signedIn ? name : 'Khách vãng lai',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      signedIn
                          ? (controller.phone.value.isNotEmpty
                              ? controller.phone.value
                              : controller.email.value)
                          : 'Đăng nhập để tích điểm',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (signedIn)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tier,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if (signedIn) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điểm tích lũy',
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                      Text(
                        '$points điểm',
                        style: const TextStyle(
                          color: Color(0xFFFFB59F),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddresses,
                  icon: const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Địa chỉ (${controller.savedAddresses.length})',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabs() => Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Center(child: Text('Thông tin cá nhân')),
              selected: _selectedTab == 0,
              onSelected: (_) => setState(() => _selectedTab = 0),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: _selectedTab == 0 ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              shape: const StadiumBorder(),
              side: BorderSide.none,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ChoiceChip(
              label: const Center(child: Text('Bảo mật & Mật khẩu')),
              selected: _selectedTab == 1,
              onSelected: (_) => setState(() => _selectedTab = 1),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: _selectedTab == 1 ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              shape: const StadiumBorder(),
              side: BorderSide.none,
            ),
          ),
        ],
      );

  Widget _profileForm() => _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Họ và tên'),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'Nhập họ và tên',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Số điện thoại'),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Nhập số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Email'),
            TextField(
              controller: TextEditingController(text: controller.email.value),
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Ngày sinh'),
            InkWell(
              onTap: _pickBirthday,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cake_outlined,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.birthday.value != null
                            ? _formatDate(controller.birthday.value!)
                            : 'Chưa cập nhật ngày sinh',
                        style: TextStyle(
                          color: controller.birthday.value != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Đang lưu...' : 'Cập nhật hồ sơ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _securitySettings() => _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đổi mật khẩu',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cập nhật mật khẩu để bảo mật tài khoản tốt hơn.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed('/change-password'),
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Đổi mật khẩu tài khoản'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _signInPrompt() => _panel(
    child: Column(
      children: [
        const Icon(
          Icons.lock_person_outlined,
          color: AppColors.primary,
          size: 42,
        ),
        const SizedBox(height: 8),
        const Text(
          'Đăng nhập để quản lý hồ sơ',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Thông tin cá nhân, điểm thưởng và cài đặt sẽ được đồng bộ với tài khoản.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: controller.login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBright,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng nhập'),
          ),
        ),
        TextButton(
          onPressed: controller.signup,
          child: const Text('Tạo tài khoản'),
        ),
      ],
    ),
  );

  Widget _logoutButton() => SizedBox(
    height: 48,
    child: OutlinedButton.icon(
      onPressed: controller.logout,
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Đăng xuất tài khoản'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: .25)),
        shape: const StadiumBorder(),
      ),
    ),
  );

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border.withValues(alpha: .7)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: .025),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Future<void> _saveProfile() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng nhập họ tên và số điện thoại.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await controller.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        birthday: controller.birthday.value,
        clearBirthday: controller.birthday.value == null,
        gender: controller.gender.value,
      );
      Get.snackbar(
        'Đã lưu hồ sơ',
        'Thông tin tài khoản đã được cập nhật.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Chưa lưu được hồ sơ',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthday() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.birthday.value ?? DateTime(today.year - 18),
      firstDate: DateTime(1900),
      lastDate: today,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) controller.birthday.value = picked;
  }

  void _showAddresses() {
    final input = TextEditingController();
    final addresses = controller.savedAddresses
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Địa chỉ giao hàng'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (addresses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Bạn chưa lưu địa chỉ nào.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: addresses.length,
                      itemBuilder: (context, index) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          addresses[index]['label']?.toString() ?? 'Địa chỉ',
                        ),
                        subtitle: Text(
                          addresses[index]['address']?.toString() ?? '',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () =>
                              setDialogState(() => addresses.removeAt(index)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.add_location_alt_outlined),
                    hintText: 'Thêm địa chỉ mới',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Đóng')),
            FilledButton(
              onPressed: () async {
                final value = input.text.trim();
                if (value.isNotEmpty) {
                  addresses.add({'label': 'Nhà', 'address': value});
                }
                try {
                  await controller.updateSavedAddresses(addresses);
                  Get.back();
                  Get.snackbar(
                    'Đã lưu địa chỉ',
                    'Danh sách địa chỉ giao hàng đã được cập nhật.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } catch (error) {
                  Get.snackbar(
                    'Chưa lưu được địa chỉ',
                    error.toString().replaceFirst('Exception: ', ''),
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    ).whenComplete(input.dispose);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _openNotifications() {
    Get.find<MainController>().openNotifications();
    Get.back();
  }
}

