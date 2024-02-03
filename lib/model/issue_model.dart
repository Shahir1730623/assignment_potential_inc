import 'package:intl/intl.dart';

class Issue {
  final String title;
  final String body;
  final String userName;
  final String createdAt;
  final List<String> labels;

  Issue({
    required this.title,
    required this.body,
    required this.userName,
    required this.createdAt,
    required this.labels,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      title: json['title'],
      body: json['body'] ?? "",
      userName: json['user']['login'],
      createdAt: json['created_at'],
      labels: List<String>.from(json['labels'].map((label) => label['name'])),
    );
  }
}
