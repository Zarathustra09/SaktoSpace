import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';

class ChatBotService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<String> generateResponse(String userMessage) async {
    try {
      print('[ChatBotService] Sending request to: $_baseUrl');
      print('[ChatBotService] API Key exists: ${OPENAI_API_KEY.isNotEmpty}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $OPENAI_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are SaktoBot, a specialized assistant for Sakto Space - an AR-enabled furniture ecommerce app. You ONLY answer questions about:\n"
                  "1. Augmented Reality (AR) features and how to use them\n"
                  "2. Furniture products, styles, materials, and recommendations\n"
                  "3. AR furniture visualization and placement\n"
                  "4. How AR works with furniture shopping\n\n"
                  "If a user asks about anything else (politics, general knowledge, other products, etc.), politely decline and remind them you only help with AR and furniture topics. "
                  "Keep responses brief, helpful, and focused on AR furniture shopping."
            },
            {"role": "user", "content": userMessage}
          ],
          "max_tokens": 150,
          "temperature": 0.7,
        }),
      );

      print('[ChatBotService] Response status: ${response.statusCode}');
      print('[ChatBotService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];
        return text?.trim() ?? 'Sorry, I couldn\'t generate a response.';
      } else {
        // Parse error response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']['message'] ?? 'Unknown error';

          if (response.statusCode == 429) {
            return 'I\'m currently experiencing high traffic. Please try again in a few minutes. 🕒';
          } else if (response.statusCode == 401) {
            return 'API access is currently restricted. Please check your API key configuration.';
          } else if (response.statusCode == 403) {
            return 'API access denied. Please verify your permissions.';
          } else {
            return 'Service temporarily unavailable (Error ${response.statusCode}). Please try again later.';
          }
        } catch (parseError) {
          return 'Service error ${response.statusCode}. Please try again later.';
        }
      }
    } catch (e) {
      print('[ChatBotService] Exception: $e');
      return 'I\'m having trouble connecting right now. Please check your internet connection and try again. 📡';
    }
  }
}
