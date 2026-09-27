import 'package:flutter/material.dart';

import 'subscription_models.dart';

class TechnicianReview {
  const TechnicianReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.customerName,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final String customerName;
  final DateTime? createdAt;

  factory TechnicianReview.fromJson(Map<String, dynamic> json) {
    return TechnicianReview(
      id: (json['id'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class TechnicianProfile {
  const TechnicianProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.category,
    required this.city,
    required this.rating,
    required this.reviewsCount,
    required this.jobsDone,
    required this.yearsExperience,
    required this.responseMinutes,
    required this.hourlyRate,
    required this.bio,
    required this.serviceAreas,
    required this.skills,
    required this.accent,
    required this.icon,
    required this.isAvailable,
    required this.recentReviews,
    required this.subscription,
  });

  final String id;
  final String name;
  final String title;
  final String category;
  final String city;
  final double rating;
  final int reviewsCount;
  final int jobsDone;
  final double yearsExperience;
  final int responseMinutes;
  final int hourlyRate;
  final String bio;
  final List<String> serviceAreas;
  final List<String> skills;
  final Color accent;
  final IconData icon;
  final bool isAvailable;
  final List<TechnicianReview> recentReviews;
  final SubscriptionSnapshot subscription;

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    return TechnicianProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      jobsDone: (json['jobs_done'] as num?)?.toInt() ?? 0,
      yearsExperience: (json['years_experience'] as num?)?.toDouble() ?? 0,
      responseMinutes: (json['response_minutes'] as num?)?.toInt() ?? 0,
      hourlyRate: ((json['hourly_rate'] as num?)?.toDouble() ?? 0).round(),
      bio: (json['bio'] ?? '').toString(),
      serviceAreas: _parseStringList(json['service_areas']),
      skills: _parseStringList(json['skills']),
      accent: _parseColor((json['accent_hex'] ?? '#D8E6FF').toString()),
      icon: _iconFromName((json['icon_name'] ?? 'build').toString()),
      isAvailable: json['is_available'] == true,
      recentReviews: (json['recent_reviews'] as List<dynamic>? ?? const [])
          .map((item) => TechnicianReview.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      subscription: SubscriptionSnapshot.fromJson(
        Map<String, dynamic>.from(json['subscription'] as Map? ?? const {}),
      ),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    }
    return const [];
  }

  static Color _parseColor(String hex) {
    final normalized = hex.replaceAll('#', '');
    final withAlpha = normalized.length == 6 ? 'FF$normalized' : normalized;
    final value = int.tryParse(withAlpha, radix: 16) ?? 0xFFD8E6FF;
    return Color(value);
  }

  static IconData _iconFromName(String name) {
    switch (name) {
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical_services':
        return Icons.electrical_services_rounded;
      case 'construction':
        return Icons.construction_rounded;
      case 'brush':
        return Icons.brush_rounded;
      case 'ac_unit':
        return Icons.ac_unit_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
