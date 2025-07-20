import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';

class ChatBotService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  static Future<String> generateResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'x-goog-api-key': GOOGLE_GEMINI_API_KEY,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {
                "text": "You are a chatbot named SaktoBot. You are to help answer basic questions about our app name Sakto Space. A ecommerce furniture AR enabled app."
              }
            ]
          },
          "contents": [
            {
              "parts": [
                {
                  "text": userMessage
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return text ?? 'Sorry, I couldn\'t generate a response.';
      } else {
        return 'Sorry, there was an error connecting to SaktoBot.';
      }
    } catch (e) {
      return 'Sorry, something went wrong. Please try again.';
    }
  }
}