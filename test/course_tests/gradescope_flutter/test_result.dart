import 'dart:convert';

class GradescopeTest {
  String name;
  double score;
  double maxScore;
  String status;
  String visibility;

  GradescopeTest({
    required this.name,
    required this.score,
    required this.maxScore,
    this.status = "failed",
    this.visibility = "visible",
  });

  // Convert a Test instance to a map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'max_score': maxScore,
      'status': status,
      'visibility': visibility,
    };
  }
}

// Define the main class that holds the list of tests and other properties
class GradescopeTestReport {
  final List<GradescopeTest> tests;
  final List<dynamic> leaderboard;
  final String visibility;
  final String executionTime;
  final double score;

  GradescopeTestReport({
    required this.tests,
    required this.leaderboard,
    required this.visibility,
    required this.executionTime,
    required this.score,
  });

  // Convert a TestReport instance to a map
  Map<String, dynamic> toJson() {
    return {
      'tests': tests.map((test) => test.toJson()).toList(),
      'leaderboard': leaderboard,
      'visibility': visibility,
      'execution_time': executionTime,
      'score': score,
    };
  }
}

class ConfigTest {
  final String rubricElementName;
  final String testPath;
  final String testName;
  final List<String>? tags;
  final double points;
  final double maxPoints;
  final String? testGroup;
  final String pointAllocation;

  ConfigTest({
    required this.rubricElementName,
    required this.testPath,
    this.testName="all",
    this.tags,
    required this.points,
    required this.maxPoints,
    this.testGroup,
    this.pointAllocation = "binary",
  });

  factory ConfigTest.fromJson(Map<String, dynamic> json) {
    return ConfigTest(
      rubricElementName: json['rubricElementName'],
      testPath: json['testPath'],
      testName: json['testName'],
      tags: List<String>.from(json['tags']),
      points: json['points'],
      maxPoints: json['maxPoints'],
      testGroup: json['testGroup'],
      pointAllocation: json['pointAllocation'],
    );
  }
}

