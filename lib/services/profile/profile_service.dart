import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';

class ProfileService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('No token found');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'name': name,
        'email': email,
        if (password != null) 'password': password,
        if (passwordConfirmation != null) 'password_confirmation': passwordConfirmation,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // Remove for multipart

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/image'),
      );

      request.headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data']['profile_image_url'];
      } else {
        throw Exception(data['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> resetProfileImage() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/image'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to reset profile image');
      }
    } catch (e) {
      throw Exception('Error resetting profile image: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }
}