import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/service/remote_service.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  final types.User _user = types.User(
      id: 'XZUGbVJiMQOM6IW6KCebjCHKLBA2'); // Replace with actual user ID
  final types.User _bot = types.User(id: 'bot-id', firstName: 'ZEN');
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
    });
    final userId = Provider.of<UserProvider>(context, listen: false).user!.uid;
    print(
        '${Provider.of<UserProvider>(context, listen: false).user!.uid} userr22');
    try {
      final data = await RemoteService().getChatData(
        userId,
      ) as List<dynamic>;

      setState(() {
        _messages = data.map((message) {
          final isBot = message['chat_from'] == 'AI';
          final author = isBot ? _bot : _user;

          return types.TextMessage(
            author: author,
            createdAt:
                message['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
            id: Random().nextInt(100000).toString(),
            text: message['message'] ?? 'No message text available',
          );
        }).toList();
      });
    } catch (error) {
      print('Error loading messages: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: Random().nextInt(100000).toString(),
      text: message.text,
    );

    final botResponse = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: "loader",
      text: "",
    );
    setState(() {
      _messages.insert(0, textMessage);
      _messages.insert(0, botResponse);
    });

    _sendBotResponse(message.text);
  }

  void _sendBotResponse(String userMessage) async {
    try {
      final userId =
          Provider.of<UserProvider>(context, listen: false).user!.uid;
      final response = await RemoteService().chatWithAI(userMessage, userId);

      final botResponse = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: Random().nextInt(100000).toString(),
        text: response,
      );
      setState(() {
        _messages[0] = botResponse;
      });
    } catch (error) {
      print('Error: $error');
      final botResponse = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: Random().nextInt(100000).toString(),
        text: 'Error: ${error.toString()}',
      );

      setState(() {
        _messages[0] = botResponse;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 246, 240, 255),
        appBar: AppBar(
          title: Text(
            "ZEN BOT",
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
        body: Stack(children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Chat(
                      messages: _messages,
                      onSendPressed: _handleSendPressed,
                      user: _user,
                      showUserAvatars: true,
                      showUserNames: true,
                      bubbleBuilder: _bubbleBuilder,
                      avatarBuilder: _avatarBuilder,
                      theme: DefaultChatTheme(
                        inputBackgroundColor: Colors.white,
                        backgroundColor: Colors.transparent,
                        emptyChatPlaceholderTextStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        inputTextCursorColor: Colors.deepPurple,
                        inputTextColor: Colors.deepPurple,
                        userAvatarNameColors: [Colors.deepPurple],
                        receivedMessageBodyTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        sentMessageBodyTextStyle: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      l10n: const ChatL10nEn(
                          inputPlaceholder:
                              "Type your message here. I'm ready to help you.",
                          emptyChatPlaceholder:
                              "No messages so far. I'm here to help with whatever you need."),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                ],
              ),
            ),
        ]));
  }

  Widget _avatarBuilder(types.User user) {
    return CircleAvatar(
      backgroundColor:
          Color.fromARGB(255, 190, 151, 229), // Avatar background color
      backgroundImage:
          user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
      child: user.imageUrl == null
          ? Text(
              user.firstName?.isNotEmpty == true
                  ? user.firstName![0]
                  : '?', // Display initial if no image
              style: TextStyle(color: Colors.deepPurple),
            )
          : null,
    );
  }

  Widget _loader() {
    return Lottie.asset(
      'assets/images/three_dot_loader.json',
      width: 50,
      height: 50,
      fit: BoxFit.contain,
    );
  }

  Widget _bubbleBuilder(Widget child,
      {required types.Message message, required bool nextMessageInGroup}) {
    final isBot = message.author.id == 'bot-id';
    final isLoader = message.id == "loader";
    return Container(
      decoration: BoxDecoration(
        color: isBot
            ? Color.fromARGB(
                255, 190, 151, 229) // Updated bot bubble background
            : Colors.white, // User bubble background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
          bottomLeft: isBot ? Radius.circular(0.0) : Radius.circular(20.0),
          bottomRight: isBot ? Radius.circular(20.0) : Radius.circular(0.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: isLoader ? _loader() : child,
    );
  }
}
