import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

// ignore_for_file: avoid_relative_lib_imports

void main() {
  // Checks that tappable nodes have a minimum size of 48 by 48 pixels for Android.
  testWidgets('min_size_on_tappable_nodes_android', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const MainApp());
    print("min_size_on_tappable_nodes_android");
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  }, tags: ['tappable-nodes', 'accessibility']);

  // 'Checks that tappable nodes have a minimum size of 44 by 44 pixels for iOS.'
  testWidgets('min_size_on_tappable_nodes_ios', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const MainApp());

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  }, tags: ['tappable-nodes', 'accessibility']);

  // 'Checks that touch targets with a tap or long press action are labeled.'
  testWidgets('tappable_buttons_labeled', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const MainApp());
    print("tappable_buttons_labeled");
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  }, tags: 'accessibility');

  // Checks whether semantic nodes meet the minimum text contrast levels.
  testWidgets('min_text_contrast_level', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const MainApp());
    print("min_text_contrast_level");

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  }, tags: 'accessibility');
}
