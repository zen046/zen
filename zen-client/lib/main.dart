import 'package:firebase_auth/firebase_auth.dart';
// // Copyright 2019 The Flutter team. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/common/theme.dart';
import 'package:flutter_application_1/providers/goal_provider.dart';
import 'package:flutter_application_1/providers/mood_provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/chat.dart';
import 'package:flutter_application_1/screens/dashboard.dart';
import 'package:flutter_application_1/screens/goal_desc.dart';
import 'package:flutter_application_1/screens/help_and_support.dart';
import 'package:flutter_application_1/screens/navigation.dart';
import 'package:flutter_application_1/screens/task_list.dart';
import 'package:flutter_application_1/screens/tasks_details.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

GoRouter router(BuildContext context) {
  User? user = FirebaseAuth.instance.currentUser;
  print(user);
  // Provider.of<UserProvider>(context, listen: false).setUser(user);
  return GoRouter(
    initialLocation: user != null ? "/navigation" : "/login",
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const MyLogin(),
      ),
      GoRoute(
        path: '/navigation',
        builder: (context, state) => const NavigationExample(),
        routes: [
          GoRoute(
            path: 'goal_details',
            builder: (context, state) {
              final goal = state.extra; // Extract the goal object
              return GoalDetailScreen(goal: goal);
              // GoalDetailScreen()
            },
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) => ChatScreen(),
          ),
          GoRoute(
              path: 'day_list',
              builder: (context, state) {
                final goal = state.extra;
                print('${state.extra} "extra"');
                if ((state.extra as dynamic).containsKey("planData")) {
                  return SevenDayPlanScreen(
                    goalId: (state.extra as Map<String, dynamic>)["goalId"],
                    planData: (state.extra as Map<String, dynamic>)["planData"],
                  );
                } else {
                  return SevenDayPlanScreen(
                    goalId: (state.extra as Map<String, dynamic>)["goalId"],
                  );
                }
              },
              routes: [
                GoRoute(
                  path: 'task_list',
                  builder: (context, state) {
                    final task = state.extra as Map<String, dynamic>;
                    return TaskListScreen(
                      taskData: task["task_data"],
                      day_id: task["day_id"],
                      goal_id: task["goal_id"],
                    );
                  },
                ),
              ]),
          GoRoute(
            path: 'help_and_support',
            builder: (context, state) => const HelpAndSupportScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MyDashboard(),
      ),

      // GoRoute(
      //    ath: '/catalog',
      //   builder: (context, state) => const MyCatalog(),
      //   routes: [
      //     GoRoute(
      //       path: 'cart',
      //       builder: (context, state) => const MyCart(),
      //     ),
      //   ],
      // ),
    ],
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => GoalsProvider()),
            ChangeNotifierProvider(create: (context) => MoodProvider()),
            ChangeNotifierProvider(create: (context) => UserProvider()),
          ],
          child: MaterialApp.router(
            title: 'Provider Demo',
            theme: appTheme,
            routerConfig: router(context),
          ),
        );
      },
    );
  }
}
