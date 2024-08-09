import 'dart:ffi';
import 'package:dart_test_adapter/dart_test_adapter.dart';
// import 'package:flutter_test/flutter_test.dart';
// import '../lib/main.dart';
import 'test_result.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'test_runner_extension.dart';

Future<List<ConfigTest>> loadConfigTestsFromFile(String filePath) async {
  try {
    // Read the file
    final file = File(filePath);
    
    // Read the contents of the file as a string
    String jsonString = await file.readAsString();

    // Decode the JSON string into a Map
    final jsonMap = json.decode(jsonString);

    // Convert the JSON Map into a list of ConfigTest objects
    List<ConfigTest> configTests = List<ConfigTest>.from(
      jsonMap['Tests'].map((testJson) => ConfigTest.fromJson(testJson)),
    );

    // Convert the JSON Map into a dictionary of ConfigTest objects
    // Map<String, ConfigTest> configTests = {
    //   for (var testJson in jsonMap['Tests'])
    //     testJson['testName']: ConfigTest.fromJson(testJson)
    // };

    return configTests;
  } catch (e) {
    // Handle any errors, such as file not found or JSON parsing issues
    print('Error loading JSON data: $e');
    return [];
  }
}


void main() async {

  String filePath = 'test/gradescope_flutter/config.json';
  List<ConfigTest> configData = await loadConfigTestsFromFile(filePath);
  var testResults = <int, GradescopeTest>{};
  var tests = <GradescopeTest>[];
  var execution_time = 0;

  for (var configtest in configData){
    var testStream = flutterTestByNames(testFiles: [configtest.testPath], testNames: [configtest.testName]);
    var count = 0;

    if (configtest.testName == "ALL"){
      testStream = flutterTestByNames(testFiles: [configtest.testPath]);
    }

    // Set a timeout for the stream
    final timeout = Duration(seconds: 15); // Adjust the timeout as needed
    final completer = Completer<void>();

    // Listen to the stream and process events
    final subscription = testStream.listen(
      (event) {
        double score = configtest.points;
        final double maxScore = configtest.maxPoints;
        final GradescopeTest? test;

        if (event is TestEventTestStart) {
            print('Test started: ${event.test.name}, id: ${event.test.id}');
            count += 1;
            testResults[event.test.id] = GradescopeTest(
              name: configtest.rubricElementName,
              score: 0.0,
              maxScore: maxScore,
            );

        } else if (event is TestEventTestDone) {
          print('Test ended: ${event.testID}, Result: ${event.result.name}');

          test = testResults[event.testID];
          if (test != null) {
            test.status = event.result.name;
            if (test.status == "success"){
              test.score += score;
            }
            tests.add(test);
            testResults[event.testID] = test;
          } else {
            print('Test result not found for ID: ${event.testID}');
          }
        } else if (event is TestEventDone) {
          print('Test ended: ${event.toString()}');
          completer.complete();
          execution_time += event.time;
          if (event.success == false && configtest.testName == "ALL" && configtest.pointAllocation == "BINARY"){
            while(count>0){
              tests[tests.length-count].score = 0.0;
              count -= 1;
            }
          }
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
    } catch (e) {
      print('Failed to process test results: $e');
    }

  }

  // Write results to results.json file
  final jsonString = jsonEncode({
    'tests': tests.map((test) => test.toJson()).toList(),
    'leaderboard': [],
    'visibility': 'visible',
    'execution_time': execution_time, // Replace with actual execution time 
    'score': tests.fold(0.0, (sum, test) => sum + test.score),
  });
  print(jsonString);
  final file = File('test/gradescope_flutter/test_results.json'); // Specify the file path
  file.writeAsString(jsonString, mode: FileMode.write);

}
