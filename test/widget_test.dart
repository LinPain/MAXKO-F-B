import 'package:flutter_test/flutter_test.dart';
import 'package:maxko_fb/main.dart';

void main() {
  testWidgets('main app opens its primary navigation', (tester) async {
    await tester.pumpWidget(const MaxkoApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Đặt món'), findsWidgets);
    expect(find.text('Đơn hàng'), findsWidgets);
  });
}
