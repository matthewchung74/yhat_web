import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inference_app/main.dart' as app;

// https://medium.com/flutter-community/writing-ui-teststester-using-integration-test-package-for-flutter-web-77b6a7f37897

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("test example", (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
  });
}
