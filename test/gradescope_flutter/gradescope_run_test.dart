import 'dart:ffi';
import 'package:dart_test_adapter/dart_test_adapter.dart';
// import 'package:flutter_test/flutter_test.dart';
// import '../lib/main.dart';
import '../gradescope_flutter/test_result.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';


void main() async {
  
  final testStream = flutterTest(tests: ['accessibility_contrast_2_test.dart'], arguments: ['--name=min_text_contrast_level']);
  // final testStream = flutterTestByNames(testFiles: ['test/accessibility_contrast_2_test.dart'], testNames: ['min_text_contrast_level']);
  var testResults = <int, GradescopeTest>{};
  var tests = <GradescopeTest>[];

  // Set a timeout for the stream
  final timeout = Duration(seconds: 15); // Adjust the timeout as needed
  final completer = Completer<void>();

  // Listen to the stream and process events
  final subscription = testStream.listen(
    (event) {
      if (event is TestEventTestStart) {
          print('Test started: ${event.test.name}, id: ${event.test.id}');

          double score = 0.0;
          final double maxScore = 0.0;

          testResults[event.test.id] = GradescopeTest(
            name: event.test.name,
            score: score,
            maxScore: maxScore,
          );
      } else if (event is TestEventTestDone) {
        print('Test ended: ${event.testID}, Result: ${event.result.name}');

        final GradescopeTest? test = testResults[event.testID];
        if (test != null) {
          test.status = event.result.name;
          test.score = 1.0;
          tests.add(test);
          testResults[event.testID] = test;
        } else {
          print('Test result not found for ID: ${event.testID}');
        }
      } else if (event is TestEventDone) {
        print('Test ended: ${event.toString()}');
        completer.complete();
        final jsonString = jsonEncode({
          'tests': tests.map((test) => test.toJson()).toList(),
          'leaderboard': [],
          'visibility': 'visible',
          'execution_time': '${event.time}', // Replace with actual execution time 
          'score': tests.fold(0.0, (sum, test) => sum + test.score),
        });
        print(jsonString);
        final file = File('test_results.json'); // Specify the file path
        file.writeAsString(jsonString, mode: FileMode.write);
      }
    },
    onDone: () {
      // Stream has finished
      completer.complete();
    },
    onError: (error) {
      // Handle errors
      print('Error: $error');
      completer.completeError(error);
    },
  );

  // Set up a timeout
  Future.delayed(timeout, () {
    if (!completer.isCompleted) {
      subscription.cancel();
      completer.completeError('Test stream timed out');
    }
  });

  // Wait for the stream to complete or timeout
  try {
    await completer.future;
    // After completion, you can process your results
    final jsonString = jsonEncode({
      'tests': tests.map((test) => test.toJson()).toList(),
      'leaderboard': [],
      'visibility': 'visible',
      'execution_time': 'N/A', // Replace with actual execution time
      'score': tests.fold(0.0, (sum, test) => sum + test.score),
    });
    print(jsonString);
  } catch (e) {
    print('Failed to process test results: $e');
  }
}
