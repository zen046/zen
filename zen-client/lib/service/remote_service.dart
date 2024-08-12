import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/dayplan.dart';
import 'package:flutter_application_1/models/goals.dart';
import 'package:flutter_application_1/models/posts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// import 'constants.dart'; // Import the constants file
const String baseUrl = 'http://35.200.211.131:3000/api/';

class RemoteService {
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> _saveToken(String? token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token!);
  }

  Future<String?> _refreshToken() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String? newToken = await user.getIdToken(true);
        print('inside refresh token,$newToken'); // Force refresh token
        await _saveToken(newToken);
        return newToken;
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return null;
  }

  Future<http.Response> _retryRequest(http.Request originalRequest) async {
    String? newToken = await _refreshToken();
    if (newToken != null) {
      // Create a new request with the updated token
      var retryRequest = http.Request(
        originalRequest.method,
        originalRequest.url,
      )
        ..headers.addAll(originalRequest.headers)
        ..headers['Authorization'] = 'Bearer $newToken'
        ..body = originalRequest.body
        ..encoding = originalRequest.encoding;

      var client = http.Client();

      try {
        var res =
            await client.send(retryRequest).then(http.Response.fromStream);
        print('Retrying request with new token: ${res.statusCode} ${res.body}');
        return res;
      } catch (e) {
        print('Error sending request: $e');
        rethrow;
      } finally {
        client.close(); // Ensure the client is closed properly
      }
    }
    throw Exception('Failed to refresh token');
  }

  Future<http.Response> _makeRequestWithRetry(http.Request request) async {
    http.Response response =
        await http.Client().send(request).then(http.Response.fromStream);
    if (response.statusCode == 401) {
      // Token might be expired, try refreshing it
      response = await _retryRequest(request);
      print('Token expired, retrying request $response');
    }
    return response;
  }

  Future<void> sendTokenToBackend(String idToken) async {
    final response = await http.post(
      Uri.parse('${baseUrl}login'), // Use the baseUrl constant
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'idToken': idToken,
      }),
    );

    if (response.statusCode == 200) {
      print('User added to Firestore');
    } else {
      print('Failed to add user to Firestore');
    }
  }

  Future<List<Post>?> getPosts() async {
    var client = http.Client();
    var uri = Uri.parse('https://jsonplaceholder.typicode.com/comments');
    var token = await _getToken();

    var response = await client.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      print('${response.body} "response"');
      var json = [
        {
          "postId": 1,
          "id": 1,
          "name": "id labore ex et quam laborum",
          "email": "Eliseo@gardner.biz",
          "body":
              "laudantium enim quasi est quidem magnam voluptate ipsam eos\ntempora quo necessitatibus\ndolor quam autem quasi\nreiciendis et nam sapiente accusantium"
        },
        {
          "postId": 1,
          "id": 2,
          "name": "quo vero reiciendis velit similique earum",
          "email": "Jayne_Kuhic@sydney.com",
          "body":
              "est natus enim nihil est dolore omnis voluptatem numquam\net omnis occaecati quod ullam at\nvoluptatem error expedita pariatur\nnihil sint nostrum voluptatem reiciendis et"
        },
      ];
      return json.map((post) => Post.fromJson(post)).toList();
    } else {
      throw ('error');
    }
  }

  Future<List<dynamic>> getGoals() async {
    var client = http.Client();
    var uri =
        Uri.parse("${baseUrl}goal-recommendation"); // Use the baseUrl constant
    var token = await _getToken();
    var request = http.Request('GET', uri);
    request.headers['Authorization'] = 'Bearer $token';
    try {
      http.Response response = await _makeRequestWithRetry(request);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        print('$jsonData jsonData'); // For debugging
        return jsonData["data"];
      } else {
        print('Failed to load data: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error: $error vdeve');
      return [];
    } finally {
      client.close();
    }
  }

  Future<DayPlan> fetchDayPlan(String url) async {
    var token = await _getToken();
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      var json = response.body;
      var jsonData = jsonDecode(json);
      return DayPlan.fromJson(jsonData);
    } else {
      throw Exception('Failed to load day plan');
    }
  }

  Future<List<dynamic>?> getQuestionnaire() async {
    var client = http.Client();
    var uri = Uri.parse('https://jsonplaceholder.typicode.com/comments');
    var token = await _getToken();

    var response = await client.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Stream<List<dynamic>> fetchDataStream() async* {
    var token = await _getToken();
    final response = await http.get(
      Uri.parse('${baseUrl}questionnaire'), // Use the baseUrl constant
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      yield data;
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Stream<List<dynamic>> getDayList(String goalId) async* {
  //   var token = await _getToken();
  //   final response = await http.get(
  //     Uri.parse(
  //         '${baseUrl}stream-goal-targets?goal_id=$goalId'), // Use the baseUrl constant
  //     headers: {'Authorization': 'Bearer $token'},
  //   );

  //   if (response.statusCode == 200) {
  //     List<dynamic> data = json.decode(response.body);
  //     yield data;
  //   } else {
  //     throw Exception('Failed to load data');
  //   }
  // }

  Stream<Map<String, dynamic>> getDayList(goalId) async* {
    http.Client client = http.Client();
    http.Request request = http.Request(
      'GET',
      Uri.parse('${baseUrl}stream-goal-targets?goal_id=$goalId'),
    );

    try {
      final response = await client.send(request);
      await for (var event in response.stream.transform(utf8.decoder)) {
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

  Future<String> chatWithAI(String userMessage, userId) async {
    final url = Uri.parse('${baseUrl}chat'); // Use the baseUrl constant
    var token = await _getToken();
    print("token $token");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_message': userMessage, "user_id": userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Data received: ${data["data"]}');
        return data["data"] ?? 'No response';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      print('Error: $e');
      return 'Error: ${e.toString()}';
    }
  }

  Future<String> postQuestionnaire(userMessage) async {
    final url =
        Uri.parse('${baseUrl}questionnaire'); // Use the baseUrl constant
    var token = await _getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'questionnaireResponse': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Data received: $data');
        return data['gemini_call_resp'] ?? 'No response';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      print('Error: $e');
      return 'Error: ${e.toString()}';
    }
  }

  Future<String> postMood(userMessage) async {
    final url = Uri.parse('${baseUrl}moods'); // Use the baseUrl constant
    var token = await _getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userMessage),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Data received: $data');
        return data['gemini_call_resp'] ?? 'No response';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      print('Error: $e');
      return 'Error: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> fetchDashboardData(String userId) async {
    final response =
        await http.get(Uri.parse('${baseUrl}get-dashboard-data/$userId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  Future<List<dynamic>> getChatData(
    String userId,
  ) async {
    // final response = await http
    //     .get(Uri.parse('http://10.0.2.2:8000/api/get-dashboard-data/$userId'));

    final response = await http.get(
      Uri.parse('${baseUrl}get-chat?user_id=${userId}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)["data"];
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  Future<http.Response> changeTaskStatus(
    dynamic widget,
  ) async {
    // final response = await http
    //     .get(Uri.parse('http://10.0.2.2:8000/api/get-dashboard-data/$userId'));

    print('widget $widget');

    final res = await http.patch(
      Uri.parse('${baseUrl}edit-task'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'goal_id': widget["goal_id"],
        'day_id': widget["day_id"],
        'task_id': widget["task_id"],
        'status': widget["status"],
      }),
    );

    return res; // Add a return statement at the end
  }

  Future<List<dynamic>> fetchvideoReccomendations(
    dynamic mood,
  ) async {
    final response = await http.get(
      Uri.parse('${baseUrl}/mood?mood=$mood'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)["data"];
    } else {
      throw Exception('Failed to load dashboard data: ${response.body}');
    }
  }
}

final sampleData = {
  "data": [
    {
      "searchResults": [
        {
          "etag": "Pj1_EfnbUrERYereNXXx4o_Cr28",
          "items": [
            {
              "etag": "pvBR3q8tXE1n_FuGgQnIS8ViJpU",
              "id": {"kind": "youtube#video", "videoId": "m3-O7gPsQK0"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UC4rlAVgAK0SGk-yTfe48Qpw",
                "channelTitle": "BRIGHT SIDE",
                "description":
                    "How to relieve stress? While a certain amount of stress in our lives is normal and even necessary, excessive stress can interfere ...",
                "liveBroadcastContent": "none",
                "publishTime": "2017-05-12T17:00:06Z",
                "publishedAt": "2017-05-12T17:00:06Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/m3-O7gPsQK0/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/m3-O7gPsQK0/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/m3-O7gPsQK0/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title": "A JAPANESE METHOD TO RELAX IN 5 MINUTES"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 455727},
          "regionCode": "IN"
        },
        {
          "etag": "IYtbPQXOo4hgoj92f8RPNNqRqUk",
          "items": [
            {
              "etag": "HMpL5X76qJljpX6PDyKx5McFRM8",
              "id": {"kind": "youtube#video", "videoId": "MDqsn2oiYig"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UCGiSCVGNukLqv8hwpKCsQKQ",
                "channelTitle": "SELF",
                "description":
                    "Meditation teacher and co-founder of Awarehouse Christine Alfred guides us through a 5-minute practice designed to assist in ...",
                "liveBroadcastContent": "none",
                "publishTime": "2023-04-13T16:00:12Z",
                "publishedAt": "2023-04-13T16:00:12Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/MDqsn2oiYig/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/MDqsn2oiYig/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/MDqsn2oiYig/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title":
                    "5 Minutes Of Guided Meditation For Letting Go Of Anger | SELF"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        },
        {
          "etag": "86gtuPSWTByBUhMSA9byvbKXeUc",
          "items": [
            {
              "etag": "Arg3EpVtzX9iUNN_VPVUM2--Aeo",
              "id": {"kind": "youtube#video", "videoId": "HSXcZmUN0OQ"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UCbcI2r4u2hyBjyNe9YcoDfA",
                "channelTitle": "MindfulPeace",
                "description":
                    "EXCITING NEWS: I just created a 12-page meditation guide that I want to be yours for FREE! Just visit my new website at ...",
                "liveBroadcastContent": "none",
                "publishTime": "2016-12-06T17:27:14Z",
                "publishedAt": "2016-12-06T17:27:14Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/HSXcZmUN0OQ/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/HSXcZmUN0OQ/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/HSXcZmUN0OQ/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title":
                    "Guided Mindfulness Meditation on Dealing with Anger (20 Minutes)"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        },
        {
          "etag": "qWrpvGYLfez-gwZACCIPMHBj1dk",
          "items": [
            {
              "etag": "5h7Z10Vpx6ZpLFgucb_Y41cjQlU",
              "id": {"kind": "youtube#video", "videoId": "0WQRfkZ_TC4"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UCttspZesZIDEwwpVIgoZtWQ",
                "channelTitle": "IndiaTV",
                "description":
                    "Swami Ramdev suggests effective yoga asanas to control anger.",
                "liveBroadcastContent": "none",
                "publishTime": "2019-06-21T17:00:33Z",
                "publishedAt": "2019-06-21T17:00:33Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/0WQRfkZ_TC4/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/0WQRfkZ_TC4/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/0WQRfkZ_TC4/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title": "How Yoga helps in anger managment"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        },
        {
          "etag": "0VaU3MNCrQwFhhHrPGRSKEEnBhg",
          "items": [
            {
              "etag": "i-BB1kM7Gj17G9faO-LMTnUHxuU",
              "id": {"kind": "youtube#video", "videoId": "395ZloN4Rr8"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UC_xYALq063ZWm-26IeG9cCQ",
                "channelTitle": "VENTUNO YOGA",
                "description":
                    "Pranayama is a breath-control technique. In Sanskrit, pran means life and ayama means way. Pranayama can help you regulate ...",
                "liveBroadcastContent": "none",
                "publishTime": "2016-08-11T01:00:00Z",
                "publishedAt": "2016-08-11T01:00:00Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/395ZloN4Rr8/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/395ZloN4Rr8/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/395ZloN4Rr8/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title":
                    "3 Most Effective Pranayamas - Deep Breathing Exercises"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        }
      ],
      "sectionTitle": "Calming Strategies"
    },
    {
      "searchResults": [
        {
          "etag": "2DQpywkmP4QP9crA5jm_Q0nKgGk",
          "items": [
            {
              "etag": "oxlG0i6VsTT6_5qaeNAeSPf1HJQ",
              "id": {"kind": "youtube#video", "videoId": "2JuLXQ8w_9A"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UCyGOloOIJWt8NlE4tnejQeA",
                "channelTitle": "MedCircle",
                "description":
                    "Get access to hundreds of LIVE workshops with the MedCircle psychologists & psychiatrists: https://watch.medcircle.com DBT is ...",
                "liveBroadcastContent": "none",
                "publishTime": "2020-06-26T16:00:03Z",
                "publishedAt": "2020-06-26T16:00:03Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/2JuLXQ8w_9A/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/2JuLXQ8w_9A/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/2JuLXQ8w_9A/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title": "3 Ways You Can Improve Emotional Regulation Using DBT"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        },
        {
          "etag": "DYFmtjugsfNmpJPN5ySDd7mwr-Q",
          "items": [
            {
              "etag": "n6K-iNssuPQKuyBiuASt4gtYu-Q",
              "id": {"kind": "youtube#video", "videoId": "PmQ2FJBJBRc"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UCcYzLCs3zrQIBVHYA1sK2sw",
                "channelTitle": "Sadhguru",
                "description":
                    "During a Youth and Truth event at JJ School of Arts, Mumbai, Sadhguru answers a student's question on how to deal with anger.",
                "liveBroadcastContent": "none",
                "publishTime": "2018-10-19T11:30:00Z",
                "publishedAt": "2018-10-19T11:30:00Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/PmQ2FJBJBRc/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/PmQ2FJBJBRc/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/PmQ2FJBJBRc/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title": "How to Deal With Anger - Sadhguru"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        },
        {
          "etag": "-K_XCz3NlmCIN_KaKco0dOqW2v0",
          "items": [
            {
              "etag": "y3VZq3tlu50BYQvrzDt0OYxztfU",
              "id": {"kind": "youtube#video", "videoId": "JSYGROLF8T4"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UC0x-WgTCAcISky8-83Q6UUw",
                "channelTitle": "Brendan Mooney Psychologist",
                "description":
                    "What if we considered the underlying cause of anger is actually hurt? If this is so, is it possible to prevent anger altogether if we ...",
                "liveBroadcastContent": "none",
                "publishTime": "2020-09-29T03:44:00Z",
                "publishedAt": "2020-09-29T03:44:00Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/JSYGROLF8T4/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/JSYGROLF8T4/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/JSYGROLF8T4/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title": "What Are the Underlying Causes of Anger?"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        },
        {
          "etag": "DG4FGmE8acQelH_oJlRsZCbBUSM",
          "items": [
            {
              "etag": "QirkmOf-kc6tEnMw78H2oKg3_dc",
              "id": {"kind": "youtube#video", "videoId": "N_US-edrX64"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UCkUaT0T03TJvafYkfATM2Ag",
                "channelTitle": "Daily Stoic",
                "description":
                    "To learn more about how to control your anger visit: https://dailystoic.com/anger The Stoics were very opposed to caving into ...",
                "liveBroadcastContent": "none",
                "publishTime": "2020-09-06T12:00:09Z",
                "publishedAt": "2020-09-06T12:00:09Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/N_US-edrX64/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/N_US-edrX64/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/N_US-edrX64/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title":
                    "3 Stoic Strategies For Overcoming Your Anger and Stress | Ryan Holiday | Daily Stoic"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        },
        {
          "etag": "BZloQpLxRQc3nv-eWgE13E9XpVk",
          "items": [
            {
              "etag": "Y-7m2P5NWb-xTUpa625GzEPSj9o",
              "id": {"kind": "youtube#video", "videoId": "fN4w4UWVZUg"},
              "kind": "youtube#searchResult",
              "snippet": {
                "channelId": "UCAE3JJi8tX7gfhZEXCUGd_A",
                "channelTitle": "Doc Snipes",
                "description":
                    "Dr. Dawn-Elise Snipes is a Licensed Professional Counselor and Qualified Clinical Supervisor. She received her PhD in Mental ...",
                "liveBroadcastContent": "none",
                "publishTime": "2022-03-21T20:00:08Z",
                "publishedAt": "2022-03-21T20:00:08Z",
                "thumbnails": {
                  "default": {
                    "height": 90,
                    "url": "https://i.ytimg.com/vi/fN4w4UWVZUg/default.jpg",
                    "width": 120
                  },
                  "high": {
                    "height": 360,
                    "url": "https://i.ytimg.com/vi/fN4w4UWVZUg/hqdefault.jpg",
                    "width": 480
                  },
                  "medium": {
                    "height": 180,
                    "url": "https://i.ytimg.com/vi/fN4w4UWVZUg/mqdefault.jpg",
                    "width": 320
                  }
                },
                "title":
                    "Anger Management: 10 Session Cognitive Behavioral Therapy Protocol"
              }
            }
          ],
          "kind": "youtube#searchListResponse",
          "nextPageToken": "CAEQAA",
          "pageInfo": {"resultsPerPage": 1, "totalResults": 1000000},
          "regionCode": "IN"
        }
      ],
      "sectionTitle": "Understanding Anger"
    }
  ],
  "message": "Successfully retrieved mood links",
  "success": true
};
