import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/profile.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  // Function to open the email app
  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'zenapp046@gmail.com',
    );
    await launchUrl(emailUri);
  }

  // Function to open the dialer app
  void _launchDialer() async {
    final Uri dialerUri = Uri(
      scheme: 'tel',
      path: '+917013991532',
    );
    await launchUrl(dialerUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
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
      backgroundColor: Color.fromARGB(255, 246, 240, 255),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'For any issues, questions, or feedback, feel free to reach out to our support team. We are here to assist you!',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            ProfileMenuItem(
                icon: Icons.email_outlined,
                text: 'Email Support',
                press: _launchEmail),
            const SizedBox(height: 20),
            ProfileMenuItem(
                icon: Icons.email_outlined,
                text: 'Call Support',
                press: _launchDialer),
          ],
        ),
      ),
    );
  }
}
