import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_test_adapter/dart_test_adapter.dart';

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

/// Parses the JSON output from the test process and converts it into a stream of TestEvents
Stream<TestEvent> _parseTestJsonOutput(
  Future<Process> Function() processCb,
) {
  final controller = StreamController<TestEvent>();
  late StreamSubscription eventSub;
  late Future<Process> processFuture;

  controller.onListen = () async {
    processFuture = processCb();
    final process = await processFuture;

    final events = process.stdout
        .map(utf8.decode)
        .expand<String>((msg) sync* {
          for (final value in msg.split('\n')) {
            final trimmedValue = value.trim();
            if (trimmedValue.isNotEmpty) yield trimmedValue;
          }
        })
        .expand<Object?>((j) {
          try {
            return [json.decode(j)];
          } on FormatException {
            return [];
          }
        })
        .cast<Map<Object?, Object?>>()
        .map((json) => TestEvent.fromJson(Map.from(json)));

    eventSub = events.listen(
      controller.add,
      onError: controller.addError,
      onDone: () async {
        controller.add(TestProcessDone(exitCode: await process.exitCode));
        await controller.close();
      },
    );
  };

  controller.onCancel = () async {
    await controller.close();
    (await processFuture).kill();
    await eventSub.cancel();
  };

  return controller.stream;
}