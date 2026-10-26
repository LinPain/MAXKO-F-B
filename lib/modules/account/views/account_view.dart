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
                      _tabs(),
                      const SizedBox(height: 12),
                      if (_selectedTab == 0)
                        _mockProfilePreview()
                      else
                        _mockSecurityPreview(),
                      const SizedBox(height: 12),
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

  Widget _mockProfilePreview() => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin tài khoản',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Cập nhật hồ sơ để nhận ưu đãi hội viên.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _previewBadge(),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFFFE3D9),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ảnh đại diện',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tối đa 5 MB · JPG, PNG',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _requireLogin,
                child: const Text('Chọn ảnh', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _mockField(
          'Họ và tên',
          'Nguyễn Hoàng Nam',
          Icons.person_outline_rounded,
        ),
        _mockField(
          'Tên hiển thị / Biệt danh',
          'Nam Nguyen',
          Icons.alternate_email_rounded,
        ),
        _mockField(
          'Số điện thoại tích điểm',
          '+84 0912 345 678',
          Icons.phone_android_rounded,
          badge: 'Đã xác thực OTP',
        ),
        _mockField(
          'Email nhận hóa đơn điện tử',
          'hoangnam@example.com',
          Icons.mail_outline_rounded,
        ),
        _mockField(
          'Ngày sinh',
          '15/10/1995',
          Icons.calendar_month_outlined,
          badge: 'Tặng voucher sinh nhật',
        ),
        _mockField(
          'Tỉnh / Thành phố sinh sống',
          'TP. Hồ Chí Minh',
          Icons.location_city_outlined,
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Giới tính',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        Wrap(
          spacing: 7,
          children: [
            _mockGender('Nam', selected: true),
            _mockGender('Nữ'),
            _mockGender('Khác'),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _requireLogin,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu thay đổi hồ sơ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _requireLogin,
          child: const Text(
            'Hủy bỏ',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );

  Widget _previewBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE3D9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'BẢN XEM TRƯỚC',
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _mockField(
    String label,
    String value,
    IconData icon, {
    String? badge,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (badge != null)
              Text(
                badge,
                style: const TextStyle(
                  color: AppColors.matcha,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _mockGender(String label, {bool selected = false}) => ChoiceChip(
    selected: selected,
    onSelected: (_) => _requireLogin(),
    avatar: Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_off,
      size: 14,
      color: selected ? AppColors.primary : AppColors.textSecondary,
    ),
    label: Text(label),
    labelStyle: const TextStyle(fontSize: 10),
    selectedColor: const Color(0xFFFFE3D9),
    backgroundColor: AppColors.surfaceMuted,
    side: BorderSide.none,
  );

  Widget _mockSecurityPreview() => _panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tiện ích & Bảo mật',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            _previewBadge(),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Các tiện ích hội viên trong bản xem trước.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        _settingRow(
          Icons.lock_outline_rounded,
          'Mật khẩu tài khoản',
          'Đổi mật khẩu để bảo vệ tài khoản',
          onTap: _requireLogin,
          trailing: 'Đổi',
        ),
        _settingRow(
          Icons.location_on_outlined,
          'Địa chỉ giao hàng',
          '3 địa chỉ đã lưu (Nhà riêng, Văn phòng)',
          onTap: _requireLogin,
          trailing: 'Quản lý',
        ),
        _settingRow(
          Icons.notifications_none_rounded,
          'Cài đặt thông báo',
          'Trạng thái đơn hàng, ưu đãi sinh nhật',
          onTap: _requireLogin,
        ),
        const Divider(height: 20),
        const Text(
          'Kênh nhận thông báo',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 7),
        const _PreviewAccountRow(
          icon: Icons.notifications_active_outlined,
          label: 'Thông báo ứng dụng',
          value: 'Đang bật',
        ),
        const _PreviewAccountRow(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: 'Đang bật',
        ),
        const _PreviewAccountRow(
          icon: Icons.sms_outlined,
          label: 'SMS OTP',
          value: 'Đang tắt',
          isLast: true,
        ),
        const SizedBox(height: 8),
        _settingRow(
          Icons.support_agent_rounded,
          'Tổng đài hỗ trợ MAXKO',
          '1900 6868 · 08:00–22:00 hàng ngày',
          onTap: _requireLogin,
          trailing: 'Gọi ngay',
        ),
      ],
    ),
  );

  void _requireLogin() {
    Get.snackbar(
      'Bản xem trước',
      'Đăng nhập để sử dụng và lưu thay đổi.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Widget _memberCard(bool signedIn) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, Color(0xFF55301F), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .35),
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signedIn ? controller.username.value : 'Nguyễn Hoàng Nam',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      signedIn
                          ? controller.email.value
                          : 'hoangnam.design@gmail.com',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .74),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _tierBadge(signedIn ? controller.membershipTierLabel : 'GOLD'),
            ],
          ),
          if (!signedIn) ...[
            const SizedBox(height: 10),
            Text(
              'ID: #MK-88921  ·  Hạng Vàng',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .78),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Điểm tích lũy: 3.850 / 5.000 điểm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '77%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                value: .77,
                minHeight: 7,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(Color(0xFFFFC15A)),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Còn 1.150 điểm để chạm hạng VIP Black',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .78),
                fontSize: 9,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: .2)),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFFD18A),
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                signedIn
                    ? '${controller.loyaltyPoints.value} điểm thưởng'
                    : '3.850 điểm tích lũy',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!signedIn)
                TextButton(
                  onPressed: controller.login,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Đăng nhập'),
                ),
            ],
          ),
          if (!signedIn) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: .14)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFFFFD18A),
                    size: 27,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã QR thành viên',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quét tích điểm tại quầy MAXKO',
                          style: TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _requireLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Xem mã',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tierBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFD9A6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _tabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _tab('Hồ sơ cá nhân', Icons.person_outline_rounded, 0),
        const SizedBox(width: 8),
        _tab('Mật khẩu & bảo mật', Icons.shield_outlined, 1),
      ],
    ),
  );

  Widget _tab(String label, IconData icon, int index) {
    final selected = _selectedTab == index;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedTab = index),
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceMuted,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    );
  }

  Widget _profileForm() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Thông tin tài khoản',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cập nhật hồ sơ để nhận ưu đãi hội viên.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ảnh đại diện',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _fieldLabel('Họ và tên'),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded),
              hintText: 'Nhập họ và tên',
            ),
          ),
          const SizedBox(height: 13),
          _fieldLabel('Số điện thoại'),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: 'Nhập số điện thoại',
            ),
          ),
          const SizedBox(height: 13),
          _fieldLabel('Email'),
          InputDecorator(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              helperText: 'Liên hệ hỗ trợ để thay đổi email.',
            ),
            child: Text(
              controller.email.value.isEmpty
                  ? 'Chưa có email'
                  : controller.email.value,
            ),
          ),
          const SizedBox(height: 13),
          _fieldLabel('Ngày sinh'),
          Obx(
            () => InkWell(
              onTap: _pickBirthday,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  hintText: 'Chọn ngày sinh',
                ),
                child: Text(
                  controller.birthday.value == null
                      ? 'Chọn ngày sinh'
                      : _formatDate(controller.birthday.value!),
                  style: TextStyle(
                    color: controller.birthday.value == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          _fieldLabel('Giới tính'),
          Obx(
            () => Wrap(
              spacing: 8,
              children: [
                _genderOption('Nam', 'male'),
                _genderOption('Nữ', 'female'),
                _genderOption('Khác', 'other'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
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
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi hồ sơ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBright,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _name.text = controller.username.value;
              _phone.text = controller.phone.value;
            },
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderOption(String label, String value) {
    final selected = controller.gender.value == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => controller.gender.value = value,
      label: Text(label),
      avatar: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        size: 15,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      selectedColor: AppColors.primary.withValues(alpha: .1),
      backgroundColor: AppColors.surfaceMuted,
      side: BorderSide(
        color: selected
            ? AppColors.primary.withValues(alpha: .35)
            : Colors.transparent,
      ),
    );
  }

  Widget _securitySettings() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiện ích & bảo mật',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _settingRow(
              Icons.lock_outline_rounded,
              'Mật khẩu tài khoản',
              'Đổi mật khẩu để bảo vệ tài khoản',
              onTap: () => Get.toNamed('/change-password'),
              trailing: 'Đổi',
            ),
            _settingRow(
              Icons.location_on_outlined,
              'Địa chỉ giao hàng',
              'Quản lý địa chỉ đã lưu',
              onTap: () => _showAddresses(),
            ),
            _settingRow(
              Icons.notifications_none_rounded,
              'Cài đặt thông báo',
              'Chọn kênh nhận thông tin',
              trailing: 'BẬT',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kênh nhận thông báo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _preferenceSwitch('Thông báo trong ứng dụng', 'push'),
            _preferenceSwitch('Email', 'email'),
            _preferenceSwitch('SMS', 'sms'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _panel(
        child: _settingRow(
          Icons.support_agent_rounded,
          'Hỗ trợ khách hàng',
          'Liên hệ cửa hàng để được trợ giúp',
          onTap: () => Get.snackbar(
            'Hỗ trợ',
            'Vui lòng liên hệ trực tiếp với cửa hàng.',
            snackPosition: SnackPosition.BOTTOM,
          ),
        ),
      ),
    ],
  );

  Widget _preferenceSwitch(String label, String key) => Obx(
    () => SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      value: controller.notificationPreferences[key] ?? false,
      activeThumbColor: AppColors.primary,
      onChanged: (value) => _savePreference(key, value),
    ),
  );

  Future<void> _savePreference(String key, bool value) async {
    final updated = Map<String, bool>.from(controller.notificationPreferences)
      ..[key] = value;
    try {
      await controller.updateNotificationPreferences(updated);
    } catch (error) {
      Get.snackbar(
        'Chưa lưu được',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _settingRow(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    String? trailing,
  }) => Material(
    color: Colors.transparent,
    child: ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
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

class _PreviewAccountRow extends StatelessWidget {
  const _PreviewAccountRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
