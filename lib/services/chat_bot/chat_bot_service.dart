import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shop/constants.dart';

class ChatBotService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<String> generateResponse(String userMessage) async {
    log('ChatBotService: Starting generateResponse for message: "${userMessage.substring(0, userMessage.length > 50 ? 50 : userMessage.length)}..."');

    try {
      // Check if API key is available
      if (GOOGLE_GEMINI_API_KEY.isEmpty) {
        log('ChatBotService: ERROR - API key is empty');
        return 'Sorry, API key not configured.';
      }

      log('ChatBotService: API key length: ${GOOGLE_GEMINI_API_KEY.length}');

      final requestBody = {
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
      };

      log('ChatBotService: Sending request to Gemini API');
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

      log('ChatBotService: Received response with status code: ${response.statusCode}');
      log('ChatBotService: Response headers: ${response.headers}');
      log('ChatBotService: Full response body: ${response.body}');

      if (response.statusCode == 200) {
        log('ChatBotService: Successfully received response from API');
        final data = jsonDecode(response.body);
        log('ChatBotService: Parsed response data: ${jsonEncode(data)}');

        // More defensive parsing
        try {
          final candidates = data['candidates'];
          if (candidates == null || candidates.isEmpty) {
            log('ChatBotService: No candidates in response');
            return 'Sorry, no response generated.';
          }

          final content = candidates[0]['content'];
          if (content == null) {
            log('ChatBotService: No content in first candidate');
            return 'Sorry, no content in response.';
          }

          final parts = content['parts'];
          if (parts == null || parts.isEmpty) {
            log('ChatBotService: No parts in content');
            return 'Sorry, no parts in response.';
          }

          final text = parts[0]['text'];
          if (text == null) {
            log('ChatBotService: No text in first part');
            return 'Sorry, no text in response.';
          }

          log('ChatBotService: Extracted text response: "${text.substring(0, text.length > 100 ? 100 : text.length)}..."');
          return text;
        } catch (parseError) {
          log('ChatBotService: Error parsing response: $parseError');
          return 'Sorry, error parsing response.';
        }
      } else if (response.statusCode == 400) {
        log('ChatBotService: Bad request (400) - Check request format');
        return 'Sorry, invalid request format.';
      } else if (response.statusCode == 401) {
        log('ChatBotService: Unauthorized (401) - Check API key');
        return 'Sorry, API authentication failed.';
      } else if (response.statusCode == 403) {
        log('ChatBotService: Forbidden (403) - Check API permissions');
        return 'Sorry, API access forbidden.';
      } else if (response.statusCode == 429) {
        log('ChatBotService: Rate limit exceeded (429)');
        return 'Sorry, too many requests. Please try again later.';
      } else {
        log('ChatBotService: API request failed with status ${response.statusCode}');
        log('ChatBotService: Error response body: ${response.body}');
        return 'Sorry, there was an error connecting to SaktoBot. Status: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      log('ChatBotService: Exception occurred: $e', error: e, stackTrace: stackTrace);
      if (e.toString().contains('SocketException')) {
        return 'Sorry, no internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        return 'Sorry, request timed out.';
      } else {
        return 'Sorry, something went wrong: ${e.toString()}';
      }
    }
  }
}