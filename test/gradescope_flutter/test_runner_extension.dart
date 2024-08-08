import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'test_protocol.dart';

Stream<TestEvent> flutterTestByNames({
  Map<String, String>? environment,
  List<String>? arguments,
  List<String>? testFiles,
  List<String>? testNames,
  String? workingDirectory,
}) {
  // Initialize arguments list with common options
  final args = <String>[
    'test',
    '--reporter=json',
    '--no-pub',
  ];

  // Add test files if provided
  if (testFiles != null && testFiles.isNotEmpty) {
    args.addAll(testFiles);
  }

  // Add test names if provided
  if (testNames != null && testNames.isNotEmpty) {
    for (var name in testNames) {
      args.add('--name=$name');
    }
  }

  // print(args);
  // Start the Flutter test process
  return _parseTestJsonOutput(
    () => Process.start(
      'flutter',
      args,
      environment: environment,
      workingDirectory: workingDirectory,
    ),
  );
}
