import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:shop/constants.dart';
import 'package:shop/services/chat_bot/chat_bot_service.dart';

class HomeBotPage extends StatefulWidget {
  const HomeBotPage({super.key});
  @override
  State<HomeBotPage> createState() => _HomeBotPageState();
}

class _HomeBotPageState extends State<HomeBotPage> {
  final ChatUser _user = ChatUser(id: 'user1', firstName: 'You');
  final ChatUser _bot = ChatUser(id: 'bot', firstName: 'SaktoBot');
  final List<ChatMessage> _messages = [];
  final List<ChatUser> _typingUsers = [];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text: "Hello! I'm SaktoBot 🤖 I'm here to help you with questions about Sakto Space, our furniture AR app. How can I assist you today?",
        user: _bot,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SaktoBot"),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: DashChat(
        currentUser: _user,
        messages: _messages,
        onSend: _handleSend,
        messageOptions: const MessageOptions(
          currentUserContainerColor: primaryColor,
          textColor: Colors.white,
          containerColor: Colors.grey,
        ),
        inputOptions: const InputOptions(
          inputDecoration: InputDecoration(hintText: 'Ask about Sakto Space...'),
        ),
        typingUsers: _typingUsers,
      ),
    );
  }

  void _handleSend(ChatMessage msg) async {
    setState(() {
      _messages.insert(0, msg);
      _typingUsers.add(_bot);
    });

    try {
      final response = await ChatBotService.generateResponse(msg.text);

      setState(() {
        _typingUsers.remove(_bot);
        _messages.insert(
          0,
          ChatMessage(
            text: response,
            user: _bot,
            createdAt: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _typingUsers.remove(_bot);
        _messages.insert(
          0,
          ChatMessage(
            text: "Sorry, I'm having trouble responding right now. Please try again later.",
            user: _bot,
            createdAt: DateTime.now(),
          ),
        );
      });
    }
  }
}