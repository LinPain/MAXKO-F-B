import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../widgets/app_section_title.dart';
import '../../account/controllers/account_controller.dart';
import '../../../data/providers/api_client.dart';
import 'lucky_wheel_view.dart';

class MembershipView extends StatelessWidget {
  const MembershipView({super.key});

  @override
  Widget build(BuildContext context) {
    final account = Get.find<AccountController>();
    return Obx(() {
      final signedIn = account.isLoggedIn.value;
      final history = account.pointsHistory.toList();
      final vouchers = account.vouchers.toList();
      final points = signedIn ? account.loyaltyPoints.value : 0;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MembershipPass(
              signedIn: signedIn,
              name: signedIn ? account.username.value : 'Khách hàng',
              contact: signedIn ? account.phone.value : '',
              tier: signedIn ? account.membershipTierLabel : 'HỘI VIÊN',
              points: points,
              onLogin: account.login,
            ),
            if (!signedIn) ...[
              const SizedBox(height: 7),
              const Text(
                'Đăng nhập để xem điểm và ưu đãi của bạn',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            _LuckyWheelEntry(onTap: openLuckyWheel),
            const SizedBox(height: 18),
            _MembershipQuickActions(
              onTap: (index) {
                if (index == 1) {
                  Get.toNamed(AppRoutes.orderHistory);
                } else if (index == 2) {
                  Get.snackbar(
                    'Đặc quyền MAXKO',
                    'Tích điểm, voucher riêng và ưu đãi sinh nhật.',
                  );
                } else if (index == 3) {
                  Get.snackbar(
                    'Mời bạn bè',
                    'Chức năng mời bạn bè hiện chưa khả dụng.',
                  );
                } else {
                  Get.snackbar(
                    'Đổi điểm',
                    'Chọn quà trong MAXKO Point Store bên dưới.',
                  );
                }
              },
            ),
            const SizedBox(height: 17),
            const AppSectionTitle(
              title: 'Chương trình hội viên',
              subtitle: 'Thông tin điểm và phần thưởng từ tài khoản của bạn',
            ),
            const SizedBox(height: 9),
            _PointStoreSection(points: points, signedIn: signedIn),
            const SizedBox(height: 18),
            const AppSectionTitle(
              title: 'Lịch sử điểm gần đây',
              subtitle: 'Giao dịch thưởng và đổi quà',
            ),
            const SizedBox(height: 9),
            _PointsHistoryCard(
              points: points,
              history: history,
              signedIn: signedIn,
            ),
            const SizedBox(height: 20),
            AppSectionTitle(
              title: 'Voucher của bạn',
              subtitle: 'Ưu đãi hiện có trong tài khoản',
              actionLabel: '${vouchers.length} mã',
            ),
            const SizedBox(height: 10),
            _VoucherList(vouchers: vouchers),
            const SizedBox(height: 16),
            const _MembershipFaq(),
            const SizedBox(height: 14),
            _AccountActions(signedIn: signedIn),
          ],
        ),
      );
    });
  }
}

class _LuckyWheelEntry extends StatelessWidget {
  const _LuckyWheelEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF1D6),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Icon(Icons.casino_rounded, color: AppColors.primary, size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vòng quay may mắn', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Thử vận may với quà tặng MAXKO', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.primary),
          ],
        ),
      ),
    ),
  );
}

class _MembershipQuickActions extends StatelessWidget {
  const _MembershipQuickActions({required this.onTap});
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.redeem_rounded, 'Đổi điểm'),
      (Icons.receipt_long_rounded, 'Đơn hàng'),
      (Icons.workspace_premium_rounded, 'Đặc quyền'),
      (Icons.card_giftcard_rounded, 'Mời bạn bè'),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7DC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        items[i].$1,
                        color: AppColors.primary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      items[i].$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PointStoreSection extends StatefulWidget {
  const _PointStoreSection({required this.points, required this.signedIn});

  final int points;
  final bool signedIn;

  @override
  State<_PointStoreSection> createState() => _PointStoreSectionState();
}

class _PointStoreSectionState extends State<_PointStoreSection> {
  final _api = Get.find<ApiClient>();
  List<Map<String, dynamic>> _rewards = [];
  String? _redeemingCode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      final response = await _api.get('/api/customers/rewards?brandId=brand-legia');
      if (!mounted) return;
      setState(() {
        _rewards = response is List
            ? response.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
            : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _redeem(Map<String, dynamic> reward) async {
    final code = reward['code']?.toString() ?? '';
    if (!widget.signedIn || code.isEmpty || _redeemingCode != null) return;
    setState(() => _redeemingCode = code);
    try {
      final response = await _api.post(
        '/api/customers/redeem-voucher',
        body: {'code': code},
      );
      if (Get.isRegistered<AccountController>()) {
        final account = Get.find<AccountController>();
        await account.loadMembershipDetails();
        await account.loadVouchers();
      }
      final voucher = response is Map && response['voucher'] is Map
          ? response['voucher'] as Map
          : const <String, dynamic>{};
      Get.snackbar(
        'Đổi quà thành công',
        'Mã ưu đãi: ${voucher['code'] ?? ''}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Chưa đổi được quà',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _redeemingCode = null);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppSectionTitle(
        title: 'MAXKO Point Store',
        subtitle: 'Bạn có ${_formatNumber(widget.points)} điểm',
      ),
      const SizedBox(height: 9),
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        )
      else if (_rewards.isEmpty)
        const _SurfaceCard(child: _MutedMessage('Chưa có phần thưởng khả dụng.'))
      else
        for (final reward in _rewards)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: const Color(0xFFFFE7DC), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reward['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text('${_formatNumber((reward['pointsCost'] as num?)?.toInt() ?? 0)} điểm', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: !widget.signedIn || _redeemingCode != null
                        ? null
                        : () => _redeem(reward),
                    style: FilledButton.styleFrom(minimumSize: const Size(68, 36), padding: const EdgeInsets.symmetric(horizontal: 10)),
                    child: Text(_redeemingCode == reward['code'] ? '...' : 'Đổi'),
                  ),
                ],
              ),
            ),
          ),
      if (!widget.signedIn)
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text('Đăng nhập để đổi điểm lấy voucher.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ),
    ],
  );
}
class _MembershipFaq extends StatelessWidget {
  const _MembershipFaq();
  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Câu hỏi thường gặp',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const _FaqTile(
          question: 'Làm thế nào để tích điểm?',
          answer: 'Điểm thưởng được cộng sau khi đơn hàng hoàn tất và tài khoản của bạn đã đăng nhập.',
        ),
        const _FaqTile(
          question: 'Điểm có thời hạn không?',
          answer: 'Thời hạn điểm sẽ hiển thị trong điều khoản chương trình hội viên.',
        ),
      ],
    ),
  );
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 9),
    title: Text(
      question,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          answer,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ),
    ],
  );
}

class _MembershipPass extends StatelessWidget {
  const _MembershipPass({
    required this.signedIn,
    required this.name,
    required this.contact,
    required this.tier,
    required this.points,
    required this.onLogin,
  });

  final bool signedIn;
  final String name;
  final String contact;
  final String tier;
  final int points;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E232A), Color(0xFF3A342F), Color(0xFF8F3A11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  color: Color(0xFFFFB77D),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAXKO F&B GROUP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'MEMBERSHIP CLUB',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9A6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  tier,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              contact,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 19),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ĐIỂM KHẢ DỤNG',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatNumber(points)} điểm',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (signedIn)
                OutlinedButton.icon(
                  onPressed: () => Get.snackbar(
                    'Mã thành viên',
                    'Mã QR thành viên sẽ được kết nối sau.',
                    snackPosition: SnackPosition.BOTTOM,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_rounded, size: 17),
                  label: const Text('Mã thành viên'),
                )
              else
                FilledButton.tonal(
                  onPressed: onLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Đăng nhập'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsHistoryCard extends StatelessWidget {
  const _PointsHistoryCard({
    required this.points,
    required this.history,
    required this.signedIn,
  });

  final int points;
  final List<Map<String, dynamic>> history;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số dư điểm',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Text(
                '${_formatNumber(points)} điểm',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (!signedIn)
            const _MutedMessage('Đăng nhập để xem lịch sử điểm của bạn.')
          else if (history.isEmpty)
            const _MutedMessage('Chưa có giao dịch điểm gần đây.')
          else
            ...history.take(4).map((entry) {
              final delta = (entry['points'] as num?)?.toInt() ?? 0;
              final date = entry['date']?.toString();
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: AppColors.amber,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry['description']?.toString() ??
                                'Giao dịch điểm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (date != null)
                            Text(
                              date,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${delta > 0 ? '+' : ''}$delta',
                      style: TextStyle(
                        color: delta >= 0
                            ? AppColors.matcha
                            : AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _VoucherList extends StatelessWidget {
  const _VoucherList({required this.vouchers});

  final List<Map<String, dynamic>> vouchers;

  @override
  Widget build(BuildContext context) {
    if (vouchers.isEmpty) {
      return const _SurfaceCard(
        child: _MutedMessage('Hiện chưa có voucher khả dụng.'),
      );
    }
    return Column(
      children: vouchers.map((voucher) {
        final percent = (voucher['discountPercent'] as num?)?.toInt() ?? 0;
        final amount = (voucher['discountAmount'] as num?)?.toInt() ?? 0;
        final maxDiscount = (voucher['maxDiscount'] as num?)?.toInt() ?? 0;
        final detail = percent > 0
            ? 'Giảm $percent%${maxDiscount > 0 ? ' · tối đa ${_formatNumber(maxDiscount)}đ' : ''}'
            : amount > 0
            ? 'Giảm ${_formatNumber(amount)}đ'
            : 'Ưu đãi dành cho khách hàng';
        final code = voucher['code']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _VoucherTile(
            title: voucher['title']?.toString() ?? 'Ưu đãi MAXKO',
            detail: detail,
            code: code,
          ),
        );
      }).toList(),
    );
  }
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({
    required this.title,
    required this.detail,
    required this.code,
  });

  final String title;
  final String detail;
  final String code;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (code.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Mã: $code',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tài khoản',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          _AccountActionTile(
            icon: Icons.person_outline_rounded,
            title: 'Thông tin cá nhân',
            onTap: () => Get.toNamed('/account'),
          ),
          _AccountActionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Đổi mật khẩu',
            onTap: () {
              if (signedIn) {
                Get.toNamed(AppRoutes.changePassword);
              } else {
                Get.snackbar(
                  'Cần đăng nhập',
                  'Đăng nhập để đổi mật khẩu.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MutedMessage extends StatelessWidget {
  const _MutedMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: AppColors.textSecondary),
    );
  }
}

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
}
