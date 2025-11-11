import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';

class ChatBotService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<String> generateResponse(String userMessage) async {
    print('ChatBotService: Starting generateResponse for message: "${userMessage.length > 50 ? userMessage.substring(0, 50) : userMessage}..."');
    log('ChatBotService: Starting generateResponse for message: "${userMessage.length > 50 ? userMessage.substring(0, 50) : userMessage}..."');

    try {
      // Check if API key is available
      if (GOOGLE_GEMINI_API_KEY.isEmpty) {
        print('ChatBotService: ERROR - API key is empty');
        log('ChatBotService: ERROR - API key is empty');
        return 'Sorry, API key not configured.';
      }

      print('ChatBotService: API key configured (length: ${GOOGLE_GEMINI_API_KEY.length})');
      log('ChatBotService: API key configured (length: ${GOOGLE_GEMINI_API_KEY.length})');

      // Use exact format from curl example
      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": "You are SaktoBot, a helpful assistant for Sakto Space - an ecommerce furniture app with AR capabilities. User question: $userMessage"
              }
            ]
          }
        ]
      };

      print('ChatBotService: Request URL: $_baseUrl');
      print('ChatBotService: Request body: ${jsonEncode(requestBody)}');
      log('ChatBotService: Request URL: $_baseUrl');
      log('ChatBotService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'x-goog-api-key': GOOGLE_GEMINI_API_KEY,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('ChatBotService: Response status: ${response.statusCode}');
      print('ChatBotService: Response body: ${response.body}');
      log('ChatBotService: Response status: ${response.statusCode}');
      log('ChatBotService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null &&
              data['candidates'][0]['content']['parts'] != null &&
              data['candidates'][0]['content']['parts'].isNotEmpty &&
              data['candidates'][0]['content']['parts'][0]['text'] != null) {

            final text = data['candidates'][0]['content']['parts'][0]['text'];
            print('ChatBotService: Success - Response received');
            log('ChatBotService: Success - Response received');
            return text;
          } else {
            print('ChatBotService: Invalid response structure: ${jsonEncode(data)}');
            log('ChatBotService: Invalid response structure: ${jsonEncode(data)}');
            return 'Sorry, received invalid response format.';
          }
        } catch (parseError) {
          print('ChatBotService: JSON parse error: $parseError');
          log('ChatBotService: JSON parse error: $parseError');
          return 'Sorry, error parsing response.';
        }
      } else {
        print('ChatBotService: HTTP Error ${response.statusCode}: ${response.body}');
        log('ChatBotService: HTTP Error ${response.statusCode}: ${response.body}');

        // Try to parse error details
        try {
          final errorData = jsonDecode(response.body);
          print('ChatBotService: Error details: ${jsonEncode(errorData)}');
          log('ChatBotService: Error details: ${jsonEncode(errorData)}');
        } catch (e) {
          print('ChatBotService: Could not parse error response');
          log('ChatBotService: Could not parse error response');
        }

        switch (response.statusCode) {
          case 400:
            return 'Sorry, invalid request. Please try again.';
          case 401:
            return 'Sorry, API authentication failed.';
          case 403:
            return 'Sorry, API access forbidden.';
          case 429:
            return 'Sorry, too many requests. Please try again later.';
          default:
            return 'Sorry, service unavailable. Status: ${response.statusCode}';
        }
      }
    } catch (e, stackTrace) {
      print('ChatBotService: Exception: $e');
      print('ChatBotService: StackTrace: $stackTrace');
      log('ChatBotService: Exception: $e', error: e, stackTrace: stackTrace);

      if (e.toString().contains('SocketException')) {
        return 'Sorry, no internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        return 'Sorry, request timed out.';
      } else {
        return 'Sorry, unexpected error: ${e.toString()}';
      }
    }
  }
}