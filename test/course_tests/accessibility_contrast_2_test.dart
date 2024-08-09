import 'package:flutter_test/flutter_test.dart';
import '../../lib/main.dart';

// ignore_for_file: avoid_relative_lib_imports

void main() {
  // Checks that tappable nodes have a minimum size of 48 by 48 pixels for Android.
  testWidgets('max_size', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const MainApp());
    print("min_size_on_tappable_nodes_android");
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  }, tags: ['tappable-nodes', 'accessibility']);

  // 'Checks that tappable nodes have a minimum size of 44 by 44 pixels for iOS.'
  testWidgets('min_text_contrast_level', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const MainApp());
    print("min_iod");
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  }, tags: ['tappable-nodes', 'accessibility']);

  test('fail_test', () {
    // Arrange
    final int expectedValue = 1;
    final int actualValue = 2;

    // Act & Assert
    expect(actualValue, equals(expectedValue), reason: 'The values should be equal');
  });
 }
