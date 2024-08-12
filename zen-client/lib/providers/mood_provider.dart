import 'package:flutter/material.dart';

class MoodProvider with ChangeNotifier {
  String _currentMood = 'NEUTRAL';

  String get currentMood => _currentMood;

  void setCurrentMood(String mood) {
    _currentMood = mood;
    notifyListeners();
  }
}
