import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_client.dart';
import '../../account/controllers/account_controller.dart';

void openLuckyWheel() {
  Get.to(() => const _LuckyWheelPage());
}

class _LuckyWheelPage extends StatelessWidget {
  const _LuckyWheelPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vòng quay may mắn')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(child: const LuckyWheelView()),
      ),
    ),
  );
}

class LuckyWheelView extends StatefulWidget {
  const LuckyWheelView({super.key});

  @override
  State<LuckyWheelView> createState() => _LuckyWheelViewState();
}

class _LuckyWheelViewState extends State<LuckyWheelView>
    with SingleTickerProviderStateMixin {
  static const _colors = <Color>[
    Color(0xFFAB2F00),
    Color(0xFFFFC857),
    Color(0xFF39734B),
    Color(0xFFFFE4C2),
    Color(0xFFD53E02),
    Color(0xFFFFD889),
    Color(0xFF7C3F28),
    Color(0xFFFFF3E2),
  ];

  late final AnimationController _controller;
  Animation<double>? _rotation;
  List<Map<String, dynamic>> _prizeOptions = [];
  List<Map<String, dynamic>> _spinHistory = [];
  double _turns = 0;
  bool _isLoading = true;
  bool _isHistoryLoading = false;
  bool _isSubmitting = false;
  int _spinsRemaining = 0;
  Map<String, dynamic>? _pendingPrize;
  Map<String, dynamic>? _prizeResult;
  String _voucherCode = '';
  int _pointsAwarded = 0;
  String? _loadError;

  List<String> get _prizes => _prizeOptions
      .map((prize) => prize['label']?.toString() ?? '')
      .where((label) => label.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 4800),
          )
          ..addListener(() {
            if (_rotation != null) setState(() => _turns = _rotation!.value);
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _prizeResult = _pendingPrize);
            }
          });
    _loadConfig();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final response = await Get.find<ApiClient>().get(
        '/api/marketing/lucky-wheel/config',
      );
      if (response is! Map || response['prizes'] is! List) {
        throw Exception('Cấu hình vòng quay không hợp lệ.');
      }
      if (!mounted) return;
      setState(() {
        _prizeOptions = (response['prizes'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _spinsRemaining = (response['spinsRemaining'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadHistory() async {
    final account = Get.isRegistered<AccountController>()
        ? Get.find<AccountController>()
        : null;
    if (account?.isLoggedIn.value != true) return;
    if (mounted) setState(() => _isHistoryLoading = true);
    try {
      final response = await Get.find<ApiClient>().get(
        '/api/marketing/lucky-wheel/history',
      );
      if (!mounted) return;
      setState(() {
        _spinHistory = response is List
            ? response
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        _isHistoryLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _spin() async {
    if (_isLoading || _isSubmitting || _controller.isAnimating || _spinsRemaining <= 0) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await Get.find<ApiClient>().post(
        '/api/marketing/lucky-wheel/spin',
      );
      if (response is! Map || response['prize'] is! Map) {
        throw Exception('Máy chủ không trả kết quả vòng quay hợp lệ.');
      }
      final prize = Map<String, dynamic>.from(response['prize'] as Map);
      final prizeIndex = (response['prizeIndex'] as num?)?.toInt() ?? -1;
      if (prizeIndex < 0 || prizeIndex >= _prizes.length) {
        throw Exception('Phần thưởng không khớp với cấu hình vòng quay.');
      }
      final segment = 1 / _prizes.length;
      final targetFraction = (1 - (prizeIndex + .5) * segment) % 1;
      final currentFraction = _turns % 1;
      final random = math.Random();
      final extraTurns = 5 + random.nextInt(3);
      final delta = extraTurns + ((targetFraction - currentFraction + 1) % 1);
      _rotation = Tween<double>(begin: _turns, end: _turns + delta).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      setState(() {
        _pendingPrize = prize;
        _prizeResult = null;
        _voucherCode = response['voucher'] is Map
            ? (response['voucher']['code']?.toString() ?? '')
            : '';
        _pointsAwarded = (response['pointsAwarded'] as num?)?.toInt() ?? 0;
        _spinsRemaining = (response['spinsRemaining'] as num?)?.toInt() ?? 0;
      });
      _controller.forward(from: 0);
      _loadHistory();
      if (Get.isRegistered<AccountController>()) {
        final account = Get.find<AccountController>();
        await account.loadMembershipDetails();
        await account.loadVouchers();
      }
    } catch (error) {
      if (mounted) {
        Get.snackbar(
          'Chưa thể quay',
          error.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vòng quay may mắn',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Một lượt quay vui vẻ — xem hôm nay bạn nhận được gì nhé!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 320,
              height: 340,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 18,
                    child: Container(
                      width: 304,
                      height: 304,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD889),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .2),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Transform.rotate(
                        angle: _turns * 2 * math.pi,
                        child: CustomPaint(
                          painter: _WheelPainter(
                            prizes: _prizes,
                            colors: _colors,
                          ),
                          child: Center(
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFD889),
                                  width: 5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_cafe_rounded,
                                color: AppColors.primary,
                                size: 27,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loadError != null
                  ? _loadConfig
                  : _isLoading || _isSubmitting ||
                        _controller.isAnimating ||
                        _spinsRemaining <= 0
                  ? null
                  : _spin,
              icon: Icon(
                _isLoading || _isSubmitting || _controller.isAnimating
                    ? Icons.hourglass_top_rounded
                    : _loadError != null
                    ? Icons.refresh_rounded
                    : Icons.casino_rounded,
              ),
              label: Text(
                _isLoading
                    ? 'Đang tải vòng quay...'
                    : _isSubmitting || _controller.isAnimating
                    ? 'Đang quay...'
                    : _loadError != null
                    ? 'Thử tải lại'
                    : _spinsRemaining <= 0
                    ? 'Đã hết lượt hôm nay'
                    : 'QUAY NGAY · $_spinsRemaining lượt',
              ),
            ),
          ),
          if (_prizeResult != null) ...[
            const SizedBox(height: 16),
            _PrizeCard(
              prize: _prizeResult!['label']?.toString() ?? '',
              voucherCode: _voucherCode,
              pointsAwarded: _pointsAwarded,
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Center(
              child: Text('Phần thưởng được chọn và xác nhận trên máy chủ.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phần quà trong vòng quay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Text('Đang tải phần thưởng...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                else if (_prizes.isEmpty)
                  Text(_loadError ?? 'Hiện chưa có phần thưởng.', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                else
                  for (final prize in _prizes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(prize, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Lượt quay và phần thưởng được quản lý bởi tài khoản MAXKO của bạn.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 22),
          const Text(
            'Lịch sử quay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 9),
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    final isLoggedIn = Get.isRegistered<AccountController>() &&
        Get.find<AccountController>().isLoggedIn.value;
    if (!isLoggedIn) {
      return const Text(
        'Đăng nhập để xem lịch sử lượt quay.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }
    if (_isHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_spinHistory.isEmpty) {
      return const Text(
        'Chưa có lượt quay nào.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }
    return Column(
      children: _spinHistory.map((spin) {
        final label = spin['prizeLabel']?.toString() ?? '';
        final code = spin['voucherCode']?.toString() ?? '';
        final points = (spin['pointsAwarded'] as num?)?.toInt() ?? 0;
        final createdAt = DateTime.tryParse(spin['createdAt']?.toString() ?? '');
        final dateLabel = createdAt == null
            ? ''
            : '${createdAt.toLocal().day.toString().padLeft(2, '0')}/'
                  '${createdAt.toLocal().month.toString().padLeft(2, '0')}/'
                  '${createdAt.toLocal().year}  '
                  '${createdAt.toLocal().hour.toString().padLeft(2, '0')}:'
                  '${createdAt.toLocal().minute.toString().padLeft(2, '0')}';
        final details = <String>[
          if (points > 0) '$points điểm',
          if (code.isNotEmpty) 'Mã: $code',
        ];
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.casino_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (dateLabel.isNotEmpty)
                      Text(dateLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    if (details.isNotEmpty)
                      Text(details.join(' · '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  const _PrizeCard({
    required this.prize,
    required this.voucherCode,
    required this.pointsAwarded,
  });
  final String prize;
  final String voucherCode;
  final int pointsAwarded;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1D6),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF4C88D)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.celebration_rounded,
          color: AppColors.primary,
          size: 30,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHÚC MỪNG BẠN!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                prize,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (voucherCode.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text('Mã ưu đãi: $voucherCode', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
              if (pointsAwarded > 0) ...[
                const SizedBox(height: 5),
                Text('Đã cộng $pointsAwarded điểm vào tài khoản', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.prizes, required this.colors});

  final List<String> prizes;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final segment = 2 * math.pi / prizes.length;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < prizes.length; i++) {
      final start = -math.pi / 2 + i * segment;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segment,
        true,
        paint,
      );
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: .85)
        ..strokeWidth = 2;
      canvas.drawLine(
        center,
        center + Offset(math.cos(start), math.sin(start)) * radius,
        linePaint,
      );
      final textAngle = start + segment / 2;
      final labelPosition =
          center +
          Offset(math.cos(textAngle), math.sin(textAngle)) * radius * .66;
      canvas.save();
      canvas.translate(labelPosition.dx, labelPosition.dy);
      canvas.rotate(textAngle + math.pi / 2);
      final foreground = (i == 1 || i == 3 || i == 5 || i == 7)
          ? AppColors.primaryDark
          : Colors.white;
      final text = TextPainter(
        text: TextSpan(
          text: prizes[i],
          style: TextStyle(
            color: foreground,
            fontSize: prizes[i].length > 10 ? 9 : 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 72);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .8),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.prizes.join('|') != prizes.join('|') ||
      oldDelegate.colors.length != colors.length;
}
