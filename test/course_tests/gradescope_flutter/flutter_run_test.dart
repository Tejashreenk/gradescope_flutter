import 'package:dart_test_adapter/dart_test_adapter.dart';
// import 'package:flutter_test/flutter_test.dart';
// import '../lib/main.dart';
import 'test_result.dart';
import 'dart:convert';

void main() async {
  // Run Flutter tests using dart_test_adapter
  final testStream = flutterTest();
  final testResults = {};
  List<GradescopeTest> tests = [];
  GradescopeTestReport report; 
  // flutterTest()
  //     .where((e) => e is TestEventTestStart)
  //     .cast<TestEventTestStart>()
  //     .forEach((start) => print("start.test.name"));
    
  // Listen to the stream and process events
  await for (final event in testStream) {
    if (event is TestEventTestStart) {
      print('Test started: ${event.test.name}, id: ${event.test.id}');
      double score = 1.0;
      final double maxScore = 1.0;
      final String visibility = "visible";
      String status = "failed";

      testResults[event.test.id] = (GradescopeTest(name: event.test.name, score: score, maxScore: maxScore, status: status, visibility: visibility));
    } else if (event is TestEventTestDone) {
      print('Test ended: ${event.testID}, Result: ${event.result}}');

      GradescopeTest test = testResults[event.testID];
      test.status = event.result.name;
      tests.add(test);
      testResults[event.testID] = test;
    }
  }
  print("object");
  report = GradescopeTestReport(
      tests: tests,
      leaderboard: [],
      visibility: 'visible',
      executionTime: '36.56',
      score: 4.0,
    );

  // Convert to JSON
  final jsonString = jsonEncode(report.toJson());

  // Print the JSON string
  print(jsonString);

}
