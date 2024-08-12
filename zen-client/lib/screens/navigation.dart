import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard.dart';
import 'package:flutter_application_1/screens/goals_list.dart';
import 'package:flutter_application_1/screens/mood.dart';
import 'package:flutter_application_1/screens/profile.dart';
import 'package:go_router/go_router.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/mood_provider.dart';

void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int selected = 0;
  final controller = PageController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mood =
        Provider.of<MoodProvider>(context, listen: false).currentMood as String;
    print("Mood: $mood");

    return Scaffold(
      extendBody: true, // Keep body extended behind the FAB and bottom bar
      body: SafeArea(
        child: PageView(
          controller: controller,
          onPageChanged: (index) {
            setState(() {
              selected = index;
            });
          },
          children: [
            MyDashboard(),
            GoalsPage(),
            MoodPage(
              currentMood: "",
            ),
            ProfileScreen(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: colorScheme.primary,
        child: Container(
          width: 60, // Adjusted width and height
          height: 60,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 158, 124, 191),
            border: Border.all(
              color: Color.fromARGB(255, 174, 150, 201),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: GestureDetector(
            onTap: () {
              context.push('/navigation/chat');
            },
            child: Lottie.asset(
              'assets/images/chat_bot_anim.json',
              width: 60, // Adjusted width and height
              height: 60,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: StylishBottomBar(
        option: DotBarOptions(),
        backgroundColor: colorScheme.primary,
        items: [
          BottomBarItem(
            icon: const Icon(
              Icons.house_outlined,
              size: 30,
            ),
            selectedColor: Colors.white,
            unSelectedColor: Colors.black,
            title: const Text('Home'),
          ),
          BottomBarItem(
            icon: const Icon(
              Icons.explore_outlined,
              size: 30,
            ),
            selectedColor: Colors.white,
            unSelectedColor: Colors.black,
            title: const Text('Explore'),
          ),
          BottomBarItem(
            icon: const Icon(
              Icons.mood_outlined,
              size: 30,
            ),
            selectedColor: Colors.white,
            unSelectedColor: Colors.black,
            title: const Text('Mood'),
          ),
          BottomBarItem(
            icon: const Icon(
              Icons.person_outline,
              size: 30,
            ),
            selectedColor: Colors.white,
            unSelectedColor: Colors.black,
            title: const Text('Profile'),
          ),
        ],
        hasNotch: true,
        fabLocation: StylishBarFabLocation.center,
        currentIndex: selected,
        notchStyle: NotchStyle.circle,
        onTap: (index) {
          if (index == selected) return;
          controller.jumpToPage(index);
          setState(() {
            selected = index;
          });
        },
      ),
    );
  }
}
