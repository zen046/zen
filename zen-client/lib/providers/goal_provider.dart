// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/service/remote_service.dart';

// class GoalsProvider with ChangeNotifier {
//   List<dynamic> _goals = [];

//   List<dynamic> get goals => _goals;

//   Future<void> fetchGoals() async {
//     try {
//       _goals = await RemoteService().getGoals();
//       notifyListeners();
//     } catch (error) {
//       // Handle error
//     }
//   }

//   void updateTaskStatus(
//       String goalId, String dayId, String taskId, String newStatus) {
//     // Update the task status in the local state
//     for (var goal in _goals) {
//       if (goal['id'] == goalId) {
//         var goalPlan = goal['goalPlan'];
//         if (goalPlan is String) {
//           goalPlan = jsonDecode(goalPlan);
//         }
//         if (goalPlan is Map<String, dynamic>) {
//           var tasks = goalPlan['tasks'];
//           if (tasks != null && tasks[taskId] != null) {
//             tasks[taskId]['status'] = newStatus;
//           }
//         }
//       }
//     }
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/remote_service.dart';

class GoalsProvider with ChangeNotifier {
  List<dynamic> _goals = [];
  bool _isLoading = false;
  bool _hasError = false;

  List<dynamic> get goals => _goals;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> fetchGoals() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    print("insid fetch goals");

    try {
      final fetchedGoals = await RemoteService().getGoals();
      _goals = fetchedGoals;
    } catch (e) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
