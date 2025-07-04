import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:shop/constants.dart';

class HomeBotPage extends StatefulWidget {
  const HomeBotPage({super.key});
  @override
  State<HomeBotPage> createState() => _HomeBotPageState();
}

class _HomeBotPageState extends State<HomeBotPage> {
  final ChatUser _user = ChatUser(id: 'user1', firstName: 'You');
  final ChatUser _bot = ChatUser(id: 'bot', firstName: 'ShopBot');
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ShopBot"),
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
          inputDecoration: InputDecoration(hintText: 'Ask about furniture...'),
        ),
        typingUsers: [],
      ),
    );
  }

  void _handleSend(ChatMessage msg) {
    setState(() {
      _messages.insert(0, msg);
      _messages.insert(
          0,
          ChatMessage(
            text: "Sorry, ShopBot isn't live yet 😊",
            user: _bot,
            createdAt: DateTime.now(),
          ));
    });
  }
}
