import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visitor_management/main.dart';
import 'package:visitor_management/providers/visitor_provider.dart';
import 'package:visitor_management/services/visitor_api_service.dart';

void main() {
  testWidgets('shows dashboard and persistent navigation', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VisitorProvider(VisitorApiService())..loadVisitors(),
        child: const VisitorManagementApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good day'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Visitors'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
  });
}
