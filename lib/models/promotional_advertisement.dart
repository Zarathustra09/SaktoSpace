import 'package:shop/constants.dart';

class PromotionalAdvertisement {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final int displayOrder;
  final DateTime? startDate;
  final DateTime? endDate;

  PromotionalAdvertisement({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.displayOrder,
    this.startDate,
    this.endDate,
  });

  factory PromotionalAdvertisement.fromJson(Map<String, dynamic> json) {
    String? rawUrl = json['image_url'] as String?;
    // Normalize relative storage paths
    if (rawUrl != null && rawUrl.startsWith('/storage')) {
      rawUrl = '$storageUrl$rawUrl';
    }
    return PromotionalAdvertisement(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: rawUrl,
      displayOrder: json['display_order'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}
