import 'package:flutter_test/flutter_test.dart';
import 'package:stockpulse/main.dart';

void main() {
  testWidgets('App boots and shows StockPulse title', (WidgetTester tester) async {
    await tester.pumpWidget(const StockPulseApp());
    await tester.pumpAndSettle();
    expect(find.text('StockPulse'), findsWidgets);
  });
}
