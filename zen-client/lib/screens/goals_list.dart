import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/goal_provider.dart';
import 'package:flutter_application_1/widgets/Questionare.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPage();
}

class _GoalsPage extends State<GoalsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch goals when the screen is initialized
    _fetchGoals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch goals every time the screen gains focus
    _fetchGoals();
  }

  void _fetchGoals() {
    // Use `Future.microtask` to ensure `fetchGoals` is called after the build
    Future.microtask(() {
      Provider.of<GoalsProvider>(context, listen: false).fetchGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color seedColor = Color.fromARGB(255, 190, 151, 229); // seedColor
    final Color primaryColor = seedColor; // primary
    final Color secondaryColor =
        Color.fromARGB(255, 201, 184, 219); // secondary

    return Scaffold(
      body: Consumer<GoalsProvider>(
        builder: (context, goalsProvider, child) {
          if (goalsProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          } else if (goalsProvider.hasError) {
            return Center(child: Text('An error occurred!'));
          } else if (goalsProvider.goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, size: 80, color: Colors.deepPurple),
                  SizedBox(height: 20),
                  Text(
                    "No goals yet!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Start your goal journey by setting your first goal.",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => SafeArea(
                          child: Container(
                            height: MediaQuery.of(context).size.height - 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            child: QuestionnaireModal(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Start Your Goal Journey",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final posts = goalsProvider.goals;
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final title = posts[index]['title'] ?? 'Untitled';
                final description = posts[index]['shortDescription'] ??
                    'No description available.';
                final goalStatus = posts[index]['goal_status'] ?? 'Unknown';

                return InkWell(
                  onTap: () {
                    if (goalStatus == "TO_DO") {
                      context.go('/navigation/goal_details',
                          extra: posts[index]);
                    } else {
                      var goalPlan = posts[index]["goalPlan"];
                      if (goalPlan is String) {
                        try {
                          goalPlan =
                              jsonDecode(goalPlan) as Map<String, dynamic>;
                        } catch (e) {
                          print('Error parsing goalPlan JSON: $e');
                          return;
                        }
                      }
                      if (goalPlan is Map<String, dynamic>) {
                        context.go('/navigation/day_list', extra: {
                          "planData": goalPlan,
                          "goalId": posts[index]["id"]
                        });
                      } else {
                        print('goalPlan is not a valid Map<String, dynamic>');
                      }
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            SizedBox(height: 8),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  goalStatus == 'IN_PROGRESS'
                                      ? Icons.timelapse
                                      : Icons.check_circle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  goalStatus,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}
