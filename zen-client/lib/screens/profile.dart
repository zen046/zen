import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _MyProfileScreen();
}

class _MyProfileScreen extends State<ProfileScreen> {
  GoogleSignInAccount? currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        currentUser = account;
        _isLoading = false;
      });
    });
    _googleSignIn.signInSilently().catchError((error) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _handleSignOut() async {
    try {
      FirebaseAuth.instance.signOut();
      context.go('/login');
    } catch (err) {
      print('Could not log out');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 246, 240, 255),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(left: 16, top: 82, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(currentUser?.photoUrl ?? ''),
                  ),
                  SizedBox(height: 20),
                  Text(
                    currentUser?.displayName ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    currentUser?.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 40),
                  ProfileMenuItem(
                    icon: Icons.help,
                    text: 'Help & Support',
                    press: () {
                      context.push('/navigation/help_and_support');
                    },
                  ),
                  SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _handleSignOut,
                    icon: Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          Size(double.infinity, 45), // Match parent width
                      side: BorderSide(color: Colors.red),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback press;

  const ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      child: ElevatedButton(
        onPressed: press,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          backgroundColor: Color.fromARGB(255, 246, 240, 255),
          side: BorderSide(color: Colors.grey),
          minimumSize: Size(double.infinity, 46),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color.fromARGB(255, 190, 151, 229)),
            SizedBox(width: 20),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
