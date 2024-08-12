class Task {
  String task;
  String status;
  String reflection;

  Task({
    required this.task,
    required this.status,
    required this.reflection,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        task: json["task"],
        status: json["status"],
        reflection: json["reflection"],
      );

  Map<String, dynamic> toJson() => {
        "task": task,
        "status": status,
        "reflection": reflection,
      };
}

class Objective {
  String objective;
  String description;
  Map<int, Task> tasks;

  Objective({
    required this.objective,
    required this.description,
    required this.tasks,
  });

  factory Objective.fromJson(Map<String, dynamic> json) => Objective(
        objective: json["objective"],
        description: json["description"],
        tasks: Map.from(json["tasks"])
            .map((k, v) => MapEntry(int.parse(k), Task.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "objective": objective,
        "description": description,
        "tasks":
            Map.from(tasks).map((k, v) => MapEntry(k.toString(), v.toJson())),
      };
}

class DayPlan {
  Map<int, Objective> objectives;

  DayPlan({
    required this.objectives,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        objectives: Map.from(json)
            .map((k, v) => MapEntry(int.parse(k), Objective.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "objectives": Map.from(objectives)
            .map((k, v) => MapEntry(k.toString(), v.toJson())),
      };
}
