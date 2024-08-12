import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/goal_provider.dart';
import 'package:flutter_application_1/service/remote_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
// import 'goals_provider.dart'; // Make sure to import the GoalsProvider

class TaskListScreen extends StatefulWidget {
  final dynamic taskData;
  final day_id;
  final goal_id;

  TaskListScreen({required this.taskData, this.day_id, this.goal_id});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late List<bool> _isChecked;
  late List<bool> _isExpanded;

  final Color primaryColor = Color.fromARGB(255, 190, 151, 229);
  final Color secondaryColor = Color.fromARGB(255, 201, 184, 219);
  final Color backgroundColor = Color.fromARGB(255, 245, 240, 255);

  @override
  void initState() {
    super.initState();
    _isChecked = List<bool>.generate(
      widget.taskData["tasks"].length,
      (index) {
        final key = widget.taskData["tasks"].keys.elementAt(index);
        final status = widget.taskData["tasks"][key]['status'];
        return status == 'DONE';
      },
    );
    _isExpanded = List<bool>.filled(widget.taskData["tasks"].length, false);
  }

  @override
  Widget build(BuildContext context) {
    final taskObject = widget.taskData["tasks"];
    final description = widget.taskData["description"];
    final objective = widget.taskData["objective"];

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 246, 240, 255),
      appBar: AppBar(
        title: Text(
          'Tasks for Day',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objective,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: taskObject.length,
              itemBuilder: (context, index) {
                final key = taskObject.keys.elementAt(index);
                final value = taskObject[key];

                return Card(
                  margin: EdgeInsets.all(10.0),
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        leading: Icon(
                          _isChecked[index]
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _isChecked[index]
                              ? Colors.deepPurple
                              : Colors.grey,
                        ),
                        title: Text(
                          value['task'] ?? 'No title available',
                          maxLines: _isExpanded[index] ? null : 1,
                          overflow: _isExpanded[index]
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            _isExpanded[index]
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isExpanded[index] = !_isExpanded[index];
                            });
                          },
                        ),
                        onTap: () async {
                          setState(() {
                            _isChecked[index] = !_isChecked[index];
                          });

                          final newStatus =
                              _isChecked[index] ? 'DONE' : 'TO_DO';
                          final response =
                              await RemoteService().changeTaskStatus({
                            'goal_id': widget.goal_id,
                            'day_id': widget.day_id,
                            'task_id': key,
                            'status': newStatus,
                          });

                          if (response.statusCode == 200) {
                            print('Task status updated successfully');
                            // Call fetchGoals() after task status update
                            Provider.of<GoalsProvider>(context, listen: false)
                                .fetchGoals();
                          } else {
                            print(
                                'Failed to update task status: ${response.statusCode}');
                          }
                        },
                      ),
                      if (_isExpanded[index])
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            value['details'] ??
                                'No additional details available',
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
