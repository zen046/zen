import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// class User {
//   // Define the User class here
// }

class UserProvider extends ChangeNotifier {
  User? _user = FirebaseAuth.instance.currentUser;

  User? get user => _user;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }
}
