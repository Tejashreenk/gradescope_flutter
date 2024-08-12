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

  var testResults = <int, GradescopeTest>{};
  var tests = <GradescopeTest>[];
  var execution_time = 0;

  String filePath = 'test/course_tests/gradescope_flutter/config.json';
  List<ConfigTest> configData = await loadConfigTestsFromFile(filePath);

  for (var configtest in configData){

    // Linter Test
    if (configtest.testName.toLowerCase() == "linter"){
        final result = await Process.run('flutter', ['analyze', '.']);
        var test = GradescopeTest(name: "Linter", score: configtest.points, maxScore: configtest.maxPoints);
        print(result.stdout);
        print(result.stderr);

        if (result.exitCode != 0) {
          test.score = 0.0;
          print('Analysis failed with exit code ${result.exitCode}');
          test.status = "failed";

        } else {
          print('Analysis completed successfully.');
          test.status = "success";
        }
        testResults[0] = test;
        tests.add(test);
        continue;
    }

    var testStream = flutterTestByNames(testFiles: [configtest.testPath], testNames: [configtest.testName]);
    var final_score = 0.0;
    GradescopeTest? test = GradescopeTest(name: configtest.rubricElementName, score: 0.0, maxScore: configtest.maxPoints);
    tests.add(test);

    if (configtest.testName == "all"){
      testStream = flutterTestByNames(testFiles: [configtest.testPath]);
    }

    // Set a timeout for the stream
    final timeout = Duration(seconds: 60); // Adjust the timeout as needed
    final completer = Completer<void>();

    // Listen to the stream and process events
    final subscription = testStream.listen(
      (event) {
        double score = configtest.points;

        if (event is TestEventTestStart) {
            // print('Test started: ${event.test.id} - ${event.test.name}');

            // To avoid considering Test events like : 
            // "loading xxx/accessibility_contrast_and_spacing_test.dart"
            if (event.test.name.contains("loading") != true){
              testResults[event.test.id] = GradescopeTest(
                name: '${configtest.rubricElementName} ${event.test.name}',
                score: 0.0,
                maxScore: configtest.maxPoints,
              );
            }
        } else if (event is TestEventTestDone) {

          if (testResults[event.testID] != null) {
            print('Test ended: ${event.testID} ${testResults[event.testID].name}, Result: ${event.result.name}');

            testResults[event.testID]?.status = event.result.name;
            if (event.result.name == "success"){
              testResults[event.testID]?.score += score;
              final_score += score;
              // print('final_score : ${final_score} score: ${testResults[event.testID]?.score}');

            }
          }
        } else if (event is TestEventDone) {
          print('Test ended: ${tests.last.name} ${event.toString()}');
          completer.complete();
          execution_time += event.time;
          if (event.success == false && configtest.testName == "all"){
            if(configtest.pointAllocation.toLowerCase() == "binary"){
              tests.last.score = 0.0;
            }else{
              tests.last.score = final_score;
            }
          }else if(event.success == true){
              tests.last.score = final_score;
              tests.last.status = "success";

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
    } catch (e) {
      print('Failed to process test results: $e');
    }

  }

  // Write results to results.json file
  final jsonString = jsonEncode({
    'tests': tests.map((test) => test.toJson()).toList(),
    'leaderboard': [],
    'visibility': 'visible',
    'execution_time': execution_time,  
    'score': tests.fold(0.0, (sum, test) => sum + test.score),
  });
  print(jsonString);
  final file = File('test/gradescope_flutter/test_results.json'); // Specify the file path
  file.writeAsString(jsonString, mode: FileMode.write);

}
