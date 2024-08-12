// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

Goal welcomeFromJson(String str) => Goal.fromJson(json.decode(str));

String welcomeToJson(Goal data) => json.encode(data.toJson());

class Goal {
  String title;
  String status;
  String longDescription;
  String benefits;

  Goal({
    required this.title,
    required this.status,
    required this.longDescription,
    required this.benefits,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        title: json["title"],
        status: json["status"],
        longDescription: json["long_description"] ?? "",
        benefits: json["benefits"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "status": status,
        "long_description": longDescription,
        "benefits": benefits,
      };
}
