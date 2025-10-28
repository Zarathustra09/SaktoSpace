import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../models/rating_model.dart';
import '../../models/prod_product_model.dart';
import '../auth/login_service.dart';

class RatingService {
  final AuthService _authService = AuthService();

  Future<RatingResponse> getRatings({int? productId, int page = 1}) async {
    final headers = await _authService.getHeaders();

    String url;
    if (productId != null) {
      // When productId is provided, backend returns the product object with "ratings" array
      url = '$baseUrl/ratings/$productId';
      if (page > 1) {
        url += '?page=$page';
      }
    } else {
      url = '$baseUrl/ratings?page=$page';
    }

    print('[RatingService] Getting ratings from: $url');

    final response = await http.get(Uri.parse(url), headers: headers);

    print('[RatingService] Ratings response status: ${response.statusCode}');
    print('[RatingService] Ratings response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // RatingResponse.fromJson now supports both shapes: paginated and product payload
      return RatingResponse.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load ratings: ${response.body}');
    }
  }

  Future<ProdProductModel> getProductWithRatings(int productId) async {
    final headers = await _authService.getHeaders();

    // Use the correct endpoint that matches your controller's show method
    final url = '$baseUrl/ratings/$productId';

    print('[RatingService] GET product with ratings: $url (productId=$productId)');

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    print('[RatingService] Product with ratings status: ${response.statusCode}');
    print('[RatingService] Product with ratings body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print('[RatingService] Parsed product: id=${data['id']}, name=${data['name']}');
      return ProdProductModel.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Product with ID $productId not found');
    } else {
      throw Exception('Failed to load product with ratings: ${response.body}');
    }
  }

  Future<RatingModel> createRating({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    final headers = await _authService.getHeaders();

    final url = '$baseUrl/ratings';
    final body = {
      'product_id': productId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };

    print('[RatingService] POST create rating: $url');
    print('[RatingService] Body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('[RatingService] Create rating status: ${response.statusCode}');
    print('[RatingService] Create rating body: ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RatingModel.fromJson(data);
    } else if (response.statusCode == 422) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'You have already rated this product');
    } else {
      throw Exception('Failed to create rating: ${response.body}');
    }
  }

  Future<RatingModel> updateRating({
    required int ratingId,
    required int rating,
    String? comment,
  }) async {
    final headers = await _authService.getHeaders();

    final url = '$baseUrl/ratings/$ratingId';
    final body = {
      'rating': rating,
      if (comment != null) 'comment': comment,
    };

    print('Updating rating with URL: $url');
    print('Update rating body: $body');

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Update rating response status: ${response.statusCode}');
    print('Update rating response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RatingModel.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('You can only update your own ratings');
    } else {
      throw Exception('Failed to update rating: ${response.body}');
    }
  }

  Future<void> deleteRating(int ratingId) async {
    final headers = await _authService.getHeaders();

    final url = '$baseUrl/ratings/$ratingId';

    print('Deleting rating with URL: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    print('Delete rating response status: ${response.statusCode}');
    print('Delete rating response body: ${response.body}');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 403) {
      throw Exception('You can only delete your own ratings');
    } else {
      throw Exception('Failed to delete rating: ${response.body}');
    }
  }
}
