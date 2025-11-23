import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/promotional_advertisement.dart';

class PromotionalService {
  static Future<String?> _getAuthToken() async {
    print('[PromotionalService] Getting auth token from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('[PromotionalService] Retrieved token: ${token != null ? "EXISTS" : "NULL"}');
    return token;
  }

  static Future<Map<String, String>> _getHeaders() async {
    print('[PromotionalService] === GETTING AUTH HEADERS ===');
    final token = await _getAuthToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('[PromotionalService] Generated headers: $headers');
    return headers;
  }

  static Future<List<PromotionalAdvertisement>> getActivePromotions({int retries = 1}) async {
    print('[PromotionalService] Fetching active promotions (attempt 1/${retries + 1})');
    final ads = await _fetchActivePromotionsInternal();
    if (ads.isEmpty && retries > 0) {
      print('[PromotionalService] Empty result, retrying after 800ms...');
      await Future.delayed(const Duration(milliseconds: 800));
      final retryAds = await _fetchActivePromotionsInternal();
      return _sortPromotions(retryAds);
    }
    return _sortPromotions(ads);
  }

  static List<PromotionalAdvertisement> _sortPromotions(List<PromotionalAdvertisement> list) {
    final sorted = List<PromotionalAdvertisement>.from(list)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  }

  static Future<List<PromotionalAdvertisement>> _fetchActivePromotionsInternal() async {
    print('[PromotionalService] API URL: $baseUrl/promotional-advertisements');
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/promotional-advertisements'),
        headers: headers,
      );
      print('[PromotionalService] Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[PromotionalService] Non-200 status, returning empty list');
        return [];
      }
      final body = response.body;
      print('[PromotionalService] Raw body length: ${body.length}');
      final jsonData = json.decode(body);
      if (jsonData is! Map || jsonData['success'] != true) {
        print('[PromotionalService] Invalid response structure');
        return [];
      }
      final data = jsonData['data'];
      if (data is! List || data.isEmpty) {
        print('[PromotionalService] API returned empty promotions array');
        return [];
      }
      final promotions = data.map((e) {
        print('[PromotionalService] Promo title: ${e['title']} | img: ${e['image_url']}');
        return PromotionalAdvertisement.fromJson(e as Map<String, dynamic>);
      }).toList().cast<PromotionalAdvertisement>();
      print('[PromotionalService] Parsed ${promotions.length} promotions');
      return promotions;
    } catch (e, st) {
      print('[PromotionalService] Exception: $e');
      print('[PromotionalService] Stack: $st');
      return [];
    }
  }

  static Future<PromotionalAdvertisement?> getPromotionById(int id) async {
    print('[PromotionalService] Fetching promotion by ID: $id');
    print('[PromotionalService] API URL: $baseUrl/promotional-advertisements/$id');

    try {
      final headers = await _getHeaders();
      print('[PromotionalService] Using headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl/promotional-advertisements/$id'),
        headers: headers,
      );

      print('[PromotionalService] Response status: ${response.statusCode}');
      print('[PromotionalService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          print('[PromotionalService] Successfully fetched promotion: ${jsonData['data']['title']}');
          return PromotionalAdvertisement.fromJson(jsonData['data']);
        }
      } else if (response.statusCode == 401) {
        print('[PromotionalService] Unauthorized - Token may be invalid');
      }
      print('[PromotionalService] Promotion not found or invalid');
      return null;
    } catch (e, stackTrace) {
      print('[PromotionalService] Error fetching promotion $id: $e');
      print('[PromotionalService] Stack trace: $stackTrace');
      return null;
    }
  }
}
