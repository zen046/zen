import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/mood_provider.dart';
import 'package:flutter_application_1/service/remote_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speedometer_chart/speedometer_chart.dart';
import 'package:provider/provider.dart';

class MyDashboard extends StatefulWidget {
  const MyDashboard({super.key});
  @override
  State<MyDashboard> createState() => _MyDashboardState();
}

// moods = {"ANGRY": 0, "SAD": 25, "NEUTRAL": 50, "HAPPY": 75, "EXCITED": 100}
class _MyDashboardState extends State<MyDashboard> {
  String name = 'Shankar';
  final List<Map<String, String>> imagePaths = [
    {"path": 'assets/images/angry_icon.png', "mood": "ANGRY"},
    {"path": 'assets/images/sad_icon.png', "mood": "SAD"},
    {"path": 'assets/images/smile_with_pain_icon.png', "mood": "NEUTRAL"},
    {"path": 'assets/images/smile_icon.png', "mood": "HAPPY"},
    {"path": 'assets/images/star.png', "mood": "EXCITED"},
    // Add more image paths and moods as needed
  ];

  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      _dashboardData = RemoteService()
          .fetchDashboardData(FirebaseAuth.instance.currentUser!.uid);
      setState(() {}); // To refresh the UI after fetching the data
    } catch (e) {
      print('Error refreshing dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          return Stack(
            children: [
              // The main UI components go here (e.g., background, widgets)

              if (snapshot.hasData)
                DashboardUI(
                  data: snapshot.data!,
                  fetchDashboardData: fetchDashboardData,
                  imagePaths: imagePaths,
                ), // Dashboard UI
              if (snapshot.connectionState == ConnectionState.waiting)
                _buildBlurredLoader(), // This method builds the blurred loader
            ],
          );
          // if (snapshot.hasError) {
          //   return Center(child: Text('Error: ${snapshot.error}'));
          // } else  else {
          //   return Center(child: Text('No data available'));
          // }
        },
      ),
    );
  }

  // Main content of the dashboard screen
  Widget _buildMainContent() {
    return Center(
      child: Text('Your main content here'),
    );
  }

  // Blurred loader widget
  Widget _buildBlurredLoader() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        ],
      ),
    );
  }
}

class EllipseClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 5, 0, 20, size.height);
    path.quadraticBezierTo(size.width, size.height, 0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class GoalsCard extends StatelessWidget {
  final int completedGoals;
  final int inProgressGoals;

  GoalsCard({required this.completedGoals, required this.inProgressGoals});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              '$completedGoals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              'Completed ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.deepPurple[300],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '$inProgressGoals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              'In Progress ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.deepPurple[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardUI extends StatefulWidget {
  final Map<String, dynamic> data;
  final Future<void> Function() fetchDashboardData;
  final List<Map<String, String>> imagePaths;

  DashboardUI({
    required this.data,
    required this.fetchDashboardData,
    required this.imagePaths,
  });

  @override
  _DashboardUIState createState() => _DashboardUIState();
}

class _DashboardUIState extends State<DashboardUI> {
  String? highlightedMood;
  @override
  Widget build(BuildContext context) {
    final completionPercentage =
        widget.data["overall_completion_percentage"]?.toDouble() ?? 0;
    final userData = FirebaseAuth.instance.currentUser;
// print()
    final completedGoalsCount = widget.data["completed_goals_count"] ?? 0;
    final inProgressGoalsCount = widget.data["total_in_progress_goals"] ?? 0;

    // Avoid division by zero
    final progressValue = completedGoalsCount > 0
        ? completedGoalsCount / inProgressGoalsCount
        : 0.0;

    final progressText = '${completedGoalsCount}/${inProgressGoalsCount}';

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              Positioned(
                child: ClipPath(
                  clipper: EllipseClipper(),
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(500),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 174, 150, 201),
                          Color(0xFFFFFFFF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 15,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Good Morning ${userData?.displayName}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Image.asset(
                          'assets/images/morning_icon.png',
                          width: 60,
                          height: 60,
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                    SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/reminder_icon.png',
                              width: 24,
                              height: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.data["quote"],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.deepPurple[300],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "What's your mood right now?",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            SizedBox(height: 24),
                            Container(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: widget.imagePaths.map((path) {
                                  return InkWell(
                                    onTap: () async {
                                      try {
                                        String selectedMood = path["mood"]!;

                                        setState(() {
                                          highlightedMood = selectedMood;
                                          Provider.of<MoodProvider>(context,
                                                  listen: false)
                                              .setCurrentMood(selectedMood);
                                          // MoodProvider().currentMood =
                                          //     selectedMood;
                                        });

                                        // Post the mood
                                        await RemoteService().postMood({
                                          "user_id": FirebaseAuth
                                              .instance.currentUser!.uid,
                                          "mood": selectedMood,
                                        });

                                        // Fetch the updated dashboard data
                                        await widget.fetchDashboardData();

                                        // Show a toast notification on success
                                        Fluttertoast.showToast(
                                          msg: "Mood set to $selectedMood",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.TOP,
                                          backgroundColor: Colors.deepPurple,
                                          textColor: Colors.white,
                                          fontSize: 16.0,
                                        );
                                      } catch (error) {
                                        // Handle any errors by showing a toast notification
                                        Fluttertoast.showToast(
                                          msg:
                                              "Failed to set mood. Please try again.",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white,
                                          fontSize: 16.0,
                                        );
                                        print('Error: $error');
                                      }
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      padding: EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Provider.of<MoodProvider>(
                                                        context,
                                                        listen: false)
                                                    .currentMood ==
                                                path["mood"]
                                            ? Colors.deepPurple.withOpacity(
                                                0.8) // Highlight selected
                                            : null, // Default color
                                        border: highlightedMood == path["mood"]
                                            ? Border.all(
                                                color: Colors.deepPurple,
                                                width:
                                                    2) // Add a border to higxhlight
                                            : null,
                                        // No border for non-selected
                                      ),
                                      child: Image.asset(
                                        path["path"]!,
                                        width: 35,
                                        height: 35,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          'Tasks',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: Colors
                                                      .white, // Set the background color
                                                  shape: BoxShape
                                                      .circle, // Make it circular
                                                ),
                                                child: Text('dat'),
                                              ),
                                              CircularProgressIndicator(
                                                value:
                                                    completionPercentage / 100,
                                                strokeWidth: 80,
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 241, 241, 241),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Color.fromARGB(
                                                      255, 158, 124, 191),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                '${completionPercentage.toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          'Goals',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: progressValue,
                                                strokeWidth: 80,
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 241, 241, 241),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Color.fromARGB(
                                                      255, 158, 124, 191),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              SizedBox(
                                                  height: 80,
                                                  width: 80,
                                                  child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Text(
                                                          progressText,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .deepPurple,
                                                          ),
                                                        ),
                                                      ]))
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width:
                          double.infinity, // Ensures full width of the screen
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Happiness Meter',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              SizedBox(height: 15),
                              Container(
                                height: 150,
                                child: SpeedometerChart(
                                  dimension: 200,
                                  minValue: 0,
                                  maxValue: 100,
                                  value:
                                      widget.data["mood_percentage"].toDouble(),
                                  graphColor: [
                                    Color.fromARGB(255, 167, 153, 181),
                                    Color.fromARGB(255, 177, 152, 206),
                                    Color.fromARGB(255, 114, 68, 160),
                                  ],
                                  pointerColor: Colors.black,
                                  minWidget: Text(
                                    'Sad',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Color.fromARGB(255, 167, 153, 181)),
                                  ),
                                  maxWidget: Text(
                                    'Happy',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 114, 68, 160),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
