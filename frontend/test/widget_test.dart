import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartExpenseManagerApp());
    expect(find.text('Smart Expense Manager'), findsOneWidget);
  });
}
