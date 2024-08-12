import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/remote_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/goal_provider.dart';

class QuestionnaireModal extends StatefulWidget {
  @override
  _QuestionnaireModalState createState() => _QuestionnaireModalState();
}

class _QuestionnaireModalState extends State<QuestionnaireModal> {
  Map<String, Map<int, String>> _selectedOptions = {};
  Map<String, Map<int, String>> _textInputs = {};
  final StreamController<Map<String, dynamic>> _streamController =
      StreamController();
  Map<String, dynamic> _questions = {};
  bool _isLoading = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _startSSEConnection();
  }

  void _startSSEConnection() {
    establishSSEConnection().listen(
      (data) {
        try {
          // final Map<String, dynamic> parsedData = jsonDecode(data);
          print('Received data: $data');
          setState(() {
            _questions = data['questionnaire'] as Map<String, dynamic>;
            _isDataLoaded = true; // Mark data as loaded
            _streamController.add(data);
          });
        } catch (error) {
          print('Error parsing JSON data: $error');
          // Handle JSON parsing errors
        }
      },
      onError: (error) {
        print('Error receiving data: $error');
      },
      onDone: () {
        print('Stream closed.');
        _streamController.close(); // Ensure the stream controller is closed
      },
    );
  }

  // Stream<String> establishSSEConnection() async* {
  //   http.Client client = http.Client();
  //   http.Request request = http.Request(
  //       'GET', Uri.parse('http://10.0.2.2:8000/api/questionnaire'));

  //   try {
  //     final response = await client.send(request);
  //     await for (var event in response.stream.transform(utf8.decoder)) {
  //       yield event; // Yield raw string data
  //     }
  //   } catch (error) {
  //     print('Error: $error');
  //     yield ''; // Yield empty string on error
  //   } finally {
  //     client.close();
  //   }
  // }

  Stream<Map<String, dynamic>> establishSSEConnection() async* {
    http.Client client = http.Client();
    http.Request request = http.Request(
        'GET', Uri.parse('http://35.200.211.131:3000/api/questionnaire'));
    print("inside establishSSEConnection");
    try {
      final response = await client.send(request);
      print("inside response $response");
      await for (var event in response.stream.transform(utf8.decoder)) {
        print('Received event: $event');
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

  // Stream<Map<String, dynamic>> establishSSEConnection() async* {
  //   http.Client client = http.Client();
  //   http.Request request = http.Request('GET',
  //       Uri.parse('https://zenapp-39c88.el.r.appspot.com/api/questionnaire'));

  //   String buffer = ''; // Buffer to hold incoming data chunks

  //   try {
  //     final response = await client.send(request);
  //     await for (var event in response.stream.transform(utf8.decoder)) {
  //       buffer += event; // Append new data to the buffer

  //       // Attempt to split the buffer into separate JSON objects
  //       while (true) {
  //         int jsonEndIndex =
  //             buffer.indexOf('}}') + 2; // Find the end of a JSON object
  //         if (jsonEndIndex == 1) break; // No complete JSON object found

  //         String jsonStr = buffer.substring(0, jsonEndIndex);
  //         buffer =
  //             buffer.substring(jsonEndIndex); // Remove parsed JSON from buffer

  //         try {
  //           Map<String, dynamic> jsonData = jsonDecode(jsonStr);
  //           yield jsonData;
  //         } catch (error) {
  //           print('Error parsing JSON data: $error');
  //         }
  //       }
  //     }
  //   } catch (error) {
  //     print('Error: $error');
  //     yield {};
  //   } finally {
  //     client.close();
  //   }
  // }

  void _submitResponses() async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    final response = _generateResponse();
    try {
      await RemoteService().postQuestionnaire(response);
      // Optionally, handle success (e.g., show a success message)
    } catch (error) {
      print('Error posting data: $error');
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
      Provider.of<GoalsProvider>(context, listen: false).fetchGoals();
      Navigator.pop(context); // Close the modal
    }
  }

  Map<String, dynamic> _generateResponse() {
    Map<String, dynamic> response = {};

    _questions.forEach((questionKey, question) {
      List<Map<String, String>> answers = [];
      question.forEach((item) {
        int itemIndex = question.indexOf(item);
        if (item['question'] != null) {
          String? answer;
          if (item.containsKey('options')) {
            answer = _selectedOptions[questionKey]?[itemIndex];
          } else if (item.containsKey('type') && item['type'] == 'text') {
            answer = _textInputs[questionKey]?[itemIndex];
          }
          if (answer != null) {
            answers.add({
              'question': item['question'],
              'answer': answer,
            });
          }
        }
      });
      response[questionKey] = answers;
    });

    return response;
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
              final hasData = snapshot.hasData;

              Map<String, dynamic>? questions = snapshot.data?['questionnaire'];

              if (!hasData || questions == null) {
                // Show shimmer for the entire screen until data starts loading
                return ListView.builder(
                  itemCount: 5, // Number of shimmer placeholders
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 60.0,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...questions.keys.map((key) {
                      final questionList = questions[key] as List<dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            key,
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16.0),
                          ...questionList.map<Widget>((item) {
                            if (item is Map<String, dynamic>) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['question'] ?? '',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  SizedBox(height: 16.0),
                                  if (item.containsKey('options') &&
                                      item['options'] is List<dynamic>)
                                    ...(item['options'] as List<dynamic>)
                                        .map<Widget>((option) {
                                      return RadioListTile<String>(
                                        title: Text(option),
                                        value: option,
                                        groupValue: _selectedOptions[key]
                                            ?[questionList.indexOf(item)],
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedOptions[key] ??= {};
                                            _selectedOptions[key]![questionList
                                                .indexOf(item)] = value!;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  if (item.containsKey('type') &&
                                      item['type'] == 'text')
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _textInputs[key] ??= {};
                                          _textInputs[key]![questionList
                                              .indexOf(item)] = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Your answer',
                                      ),
                                    ),
                                  SizedBox(height: 16.0),
                                ],
                              );
                            } else {
                              return Container();
                            }
                          }).toList(),
                          SizedBox(height: 24.0),
                        ],
                      );
                    }).toList(),
                    if (snapshot.connectionState != ConnectionState.done)
                      Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 20.0,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8.0),
                              Container(
                                width: double.infinity,
                                height: 16.0,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8.0),
                              Container(
                                width: double.infinity,
                                height: 16.0,
                                color: Colors.white,
                              ),
                            ],
                          )),
                    if (snapshot.connectionState == ConnectionState.done)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitResponses,
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text('Finish'),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
