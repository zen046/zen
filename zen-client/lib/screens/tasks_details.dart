// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;

// class SevenDayPlanScreen extends StatefulWidget {
//   final goalId;
//   final Map<String, dynamic>? planData;

//   SevenDayPlanScreen({required this.goalId, this.planData});

//   @override
//   _SevenDayPlanScreenState createState() => _SevenDayPlanScreenState();
// }

// class _SevenDayPlanScreenState extends State<SevenDayPlanScreen> {
//   final StreamController<Map<String, dynamic>> _streamController =
//       StreamController();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.planData == null) {
//       _startSSEConnection();
//     }
//   }

//   void _startSSEConnection() {
//     establishSSEConnection().listen(
//       (data) {
//         try {
//           final Map<String, dynamic> parsedData = jsonDecode(data);
//           setState(() {
//             _streamController.add(parsedData);
//           });
//         } catch (error) {
//           print('Error parsing JSON data: $error');
//         }
//       },
//       onError: (error) {
//         print('Error receiving data: $error');
//       },
//       onDone: () {
//         print('Stream closed.');
//         _streamController.close();
//       },
//     );
//   }

//   Stream<String> establishSSEConnection() async* {
//     http.Client client = http.Client();
//     http.Request request = http.Request(
//       'GET',
//       Uri.parse(
//           'http://10.0.2.2:8000/api/stream-goal-targets?goal_id=${widget.goalId}'),
//     );

//     try {
//       final response = await client.send(request);
//       await for (var event in response.stream.transform(utf8.decoder)) {
//         yield event;
//       }
//     } catch (error) {
//       print('Error: $error');
//       yield '';
//     } finally {
//       client.close();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Color primaryColor = Color.fromARGB(255, 190, 151, 229);
//     final Color secondaryColor = Color.fromARGB(255, 201, 184, 219);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           '7-Day Plan',
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//         ),
//         backgroundColor: primaryColor,
//       ),
//       body: widget.planData != null
//           ? _buildPlanList(widget.planData!)
//           : StreamBuilder<Map<String, dynamic>>(
//               stream: _streamController.stream,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(
//                     child: CircularProgressIndicator(
//                       color: primaryColor,
//                     ),
//                   );
//                 } else if (snapshot.hasError) {
//                   return Center(
//                     child: Text('Error: ${snapshot.error}',
//                         style: TextStyle(color: Colors.red)),
//                   );
//                 } else if (snapshot.hasData) {
//                   return _buildPlanList(snapshot.data!);
//                 } else {
//                   return Center(child: Text('No data received'));
//                 }
//               },
//             ),
//     );
//   }

//   Widget _buildPlanList(Map<String, dynamic> data) {
//     final Color primaryColor = Color.fromARGB(255, 190, 151, 229);
//     final Color secondaryColor = Color.fromARGB(255, 201, 184, 219);

//     return ListView.builder(
//       itemCount: data.length,
//       itemBuilder: (context, index) {
//         final key = data.keys.elementAt(index);
//         final value = data[key];
//         if (value is Map<String, dynamic>) {
//           final objective = value['objective'] ?? 'No Objective';
//           final description = value['description'] ?? 'No Description';
//           final status = value['status'] ?? 'Not specified'; // Adjust as needed

//           Icon trailingIcon;
//           switch (status) {
//             case 'DONE':
//               trailingIcon = Icon(
//                 Icons.check_circle_outline,
//                 color: primaryColor,
//               );
//               break;
//             case 'in progress':
//               trailingIcon = Icon(
//                 Icons.hourglass_empty,
//                 color: Colors.orange, // Or any color representing progress
//               );
//               break;
//             case 'not started':
//               trailingIcon = Icon(
//                 Icons.radio_button_unchecked,
//                 color: Colors.grey, // Or any color representing not started
//               );
//               break;
//             default:
//               trailingIcon = Icon(
//                 Icons.radio_button_unchecked,
//                 color: Colors.blueGrey, // Placeholder icon for unknown statuses
//               );
//           }

//           return Card(
//             margin: EdgeInsets.all(10.0),
//             elevation: 5.0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15.0),
//             ),
//             color: secondaryColor,
//             child: ListTile(
//               contentPadding: EdgeInsets.all(16.0),
//               leading: CircleAvatar(
//                 backgroundColor: primaryColor,
//                 child: Text(
//                   '${index + 1}',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               title: Text(
//                 'Day ${index + 1}',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text(objective),
//               trailing: trailingIcon,
//               onTap: () {
//                 context.push('/navigation/day_list/task_list', extra: {
//                   "task_data": value,
//                   "day_id": key,
//                   "goal_id": widget.goalId
//                 });
//               },
//             ),
//           );
//         }
//         return SizedBox.shrink();
//       },
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/goal_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class SevenDayPlanScreen extends StatefulWidget {
  final goalId;
  final Map<String, dynamic>? planData;

  SevenDayPlanScreen({required this.goalId, this.planData});

  @override
  _SevenDayPlanScreenState createState() => _SevenDayPlanScreenState();
}

class _SevenDayPlanScreenState extends State<SevenDayPlanScreen> {
  final StreamController<Map<String, dynamic>> _streamController =
      StreamController();

  @override
  void initState() {
    super.initState();
    if (widget.planData == null) {
      _startSSEConnection();
    }
  }

  void _startSSEConnection() {
    establishSSEConnection().listen(
      (data) {
        try {
          final Map<String, dynamic> parsedData = jsonDecode(data);
          setState(() {
            _streamController.add(parsedData);
          });
        } catch (error) {
          print('Error parsing JSON data: $error');
        }
      },
      onError: (error) {
        print('Error receiving data: $error');
      },
      onDone: () {
        print('Stream closed.');
        _streamController.close();
        // Fetch goals when the stream connection is done
        Provider.of<GoalsProvider>(context, listen: false).fetchGoals();
      },
    );
  }

  Stream<String> establishSSEConnection() async* {
    http.Client client = http.Client();
    http.Request request = http.Request(
      'GET',
      Uri.parse(
          'http://35.200.211.131:3000/api/stream-goal-targets?goal_id=${widget.goalId}'),
    );
    try {
      final response = await client.send(request);
      await for (var event in response.stream.transform(utf8.decoder)) {
        yield event;
      }
    } catch (error) {
      print('Error: $error');
      yield '';
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color.fromARGB(255, 190, 151, 229);
    final Color secondaryColor = Color.fromARGB(255, 201, 184, 219);

    if (widget.planData != null) {
      final goalProvider = Provider.of<GoalsProvider>(context, listen: false);
      final goal = goalProvider.goals.firstWhere(
          (goal) => goal['id'] == widget.goalId,
          orElse: () => null);
      if (goal != null) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '7-Day Plan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).primaryColor,
            centerTitle: true,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white, size: 30),
          ),
          body: _buildPlanList(goal['goalPlan']),
        );
      } else {
        return Center(child: Text('Goal not found'));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '7-Day Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: 30),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red)),
            );
          } else if (snapshot.hasData) {
            return _buildPlanList(snapshot.data!);
          } else {
            return Center(child: Text('No data received'));
          }
        },
      ),
    );
  }

  Widget _buildPlanList(Map<String, dynamic> data) {
    final Color primaryColor = Color.fromARGB(255, 190, 151, 229);
    final Color secondaryColor = Color.fromARGB(255, 201, 184, 219);

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final key = data.keys.elementAt(index);
        final value = data[key];
        if (value is Map<String, dynamic>) {
          final objective = value['objective'] ?? 'No Objective';
          final description = value['description'] ?? 'No Description';
          final status = value['status'] ?? 'Not specified'; // Adjust as needed

          Icon trailingIcon;
          switch (status) {
            case 'DONE':
              trailingIcon = Icon(
                Icons.check_circle_outline,
                color: primaryColor,
              );
              break;
            case 'in progress':
              trailingIcon = Icon(
                Icons.hourglass_empty,
                color: Colors.orange, // Or any color representing progress
              );
              break;
            case 'not started':
              trailingIcon = Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey, // Or any color representing not started
              );
              break;
            default:
              trailingIcon = Icon(
                Icons.radio_button_unchecked,
                color: Colors.blueGrey, // Placeholder icon for unknown statuses
              );
          }

          return Card(
            margin: EdgeInsets.all(10.0),
            elevation: 5.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: secondaryColor,
            child: ListTile(
              contentPadding: EdgeInsets.all(16.0),
              leading: CircleAvatar(
                backgroundColor: primaryColor,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                'Day ${index + 1}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(objective),
              trailing: trailingIcon,
              onTap: () {
                context.push('/navigation/day_list/task_list', extra: {
                  "task_data": value,
                  "day_id": key,
                  "goal_id": widget.goalId
                });
              },
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
