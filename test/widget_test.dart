import 'package:flutter_test/flutter_test.dart';
import 'package:uterine_cancer_advisor/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UterineCancerAdvisorApp());
    expect(find.byType(UterineCancerAdvisorApp), findsOneWidget);
  });
}
