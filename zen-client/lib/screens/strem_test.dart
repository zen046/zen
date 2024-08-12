import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class QuestionnaireModal extends StatefulWidget {
  @override
  _QuestionnaireModalState createState() => _QuestionnaireModalState();
}

class _QuestionnaireModalState extends State<QuestionnaireModal> {
  int _currentSectionIndex = 0;
  Map<int, Map<int, String>> _selectedOptions = {};
  final StreamController<Map<String, dynamic>> _streamController =
      StreamController();
  Map<String, dynamic> _sections = {};

  @override
  void initState() {
    super.initState();
    _startSSEConnection();
  }

  void _startSSEConnection() {
    establishSSEConnection().listen((data) {
      setState(() {
        _sections = data;
        _streamController.add(data);
      });
    }, onError: (error) {
      // Handle error case here
      print('Error receiving data: $error');
    });
  }

  Stream<Map<String, dynamic>> establishSSEConnection() async* {
    http.Client client = http.Client();
    http.Request request = http.Request(
        'GET', Uri.parse('http://10.0.2.2:8000/api/questionnaire'));

    try {
      final response = await client.send(request);
      await for (var event in response.stream.transform(utf8.decoder)) {
        // Decode the JSON response
        Map<String, dynamic> jsonData = jsonDecode(event);
        yield jsonData;
      }
    } catch (error) {
      print('Error: $error');
      yield {};
    } finally {
      client.close();
    }
  }

  void _nextSection() {
    if (_currentSectionIndex < _getSectionKeys().length - 1) {
      setState(() {
        _currentSectionIndex++;
      });
    } else {
      Navigator.pop(context);
    }
  }

  List<String> _getSectionKeys() {
    return _sections.keys.toList();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<Map<String, dynamic>>(
            stream: _streamController.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final sectionKeys = _getSectionKeys();
              if (sectionKeys.isEmpty) {
                return Center(child: Text('No data available.'));
              }
              print(sectionKeys);
              final currentSectionKey = sectionKeys[_currentSectionIndex];
              final currentSection = snapshot.data![currentSectionKey];

              // Ensure currentSection is a List<Map<String, dynamic>>
              if (currentSection) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSectionKey,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16.0),
                      ...currentSection.map<Widget>((item) {
                        if (item is Map<String, dynamic>) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['question'] ?? '',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 16.0),
                              ...(item['options'] as List<dynamic>)
                                  .map<Widget>((option) {
                                return RadioListTile<String>(
                                  title: Text(option),
                                  value: option,
                                  groupValue:
                                      _selectedOptions[_currentSectionIndex]
                                          ?[currentSection.indexOf(item)],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedOptions[_currentSectionIndex] ??=
                                          {};
                                      _selectedOptions[_currentSectionIndex]![
                                              currentSection.indexOf(item)] =
                                          value!;
                                    });
                                  },
                                );
                              }).toList(),
                              SizedBox(height: 16.0),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      }).toList(),
                      ElevatedButton(
                        onPressed: _nextSection,
                        child: Text(
                            _currentSectionIndex < sectionKeys.length - 1
                                ? 'Next Section'
                                : 'Finish'),
                      ),
                    ],
                  ),
                );
              } else {
                print('Data received: ${snapshot.data} ');
                return Center(child: Text('Invalid data format.'));
              }
            },
          ),
        ),
      ),
    );
  }
}
