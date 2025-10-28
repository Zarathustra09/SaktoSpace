class RatingModel {
  final int id;
  final int userId;
  final int productId;
  final String? comment;
  final int rating;
  final String createdAt;
  final String updatedAt;
  final UserModel? user;

  RatingModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.comment,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      comment: json['comment'],
      rating: json['rating'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class UserModel {
  final int id;
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class RatingResponse {
  final List<RatingModel> ratings;
  final int currentPage;
  final int lastPage;
  final int total;

  RatingResponse({
    required this.ratings,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    // Case 1: Paginated ratings payload { data: [...], current_page, last_page, total }
    if (json['data'] is List) {
      final list = (json['data'] as List)
          .map((rating) => RatingModel.fromJson(rating as Map<String, dynamic>))
          .toList();
      return RatingResponse(
        ratings: list,
        currentPage: (json['current_page'] ?? 1) as int,
        lastPage: (json['last_page'] ?? 1) as int,
        total: (json['total'] ?? list.length) as int,
      );
    }

    // Case 2: Product payload { ..., ratings: [...], total_ratings, ... }
    if (json['ratings'] is List) {
      final list = (json['ratings'] as List)
          .map((rating) => RatingModel.fromJson(rating as Map<String, dynamic>))
          .toList();
      return RatingResponse(
        ratings: list,
        currentPage: 1,
        lastPage: 1,
        total: (json['total_ratings'] ?? list.length) as int,
      );
    }

    // Fallback: unknown shape
    return RatingResponse(
      ratings: const [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    );
  }
}
