class EstimateRecord {
  const EstimateRecord({
    required this.id,
    required this.area,
    required this.crackCount,
    required this.materialCost,
    required this.totalCost,
    required this.bestOffer,
    required this.createdAt,
  });

  final String id;
  final double area;
  final int crackCount;
  final double materialCost;
  final double totalCost;
  final String bestOffer;
  final DateTime createdAt;

  factory EstimateRecord.fromJson(Map<String, dynamic> json) {
    final materialNeeds = _asMap(json['material_needs']);
    final summary = _asMap(json['estimate_summary']);
    final imageAnalysis = _asMap(json['image_analysis']);
    final offers = json['shop_offers'] is List
        ? json['shop_offers'] as List<dynamic>
        : const [];
    final bestOffer = offers.isNotEmpty
        ? _asMap(offers.first)
        : const <String, dynamic>{};

    return EstimateRecord(
      id: (json['estimate_id'] ?? json['id'] ?? '').toString(),
      area:
          (json['area'] as num?)?.toDouble() ??
          (json['wall_area'] as num?)?.toDouble() ??
          (json['wall_area_m2'] as num?)?.toDouble() ??
          (materialNeeds['net_area_m2'] as num?)?.toDouble() ??
          0,
      crackCount:
          (json['crack_count'] as num?)?.toInt() ??
          (json['detected_cracks'] as num?)?.toInt() ??
          (imageAnalysis['detections'] is List
              ? (imageAnalysis['detections'] as List).length
              : null) ??
          0,
      materialCost:
          (json['material_cost'] as num?)?.toDouble() ??
          (summary['best_price'] as num?)?.toDouble() ??
          (bestOffer['total_cost'] as num?)?.toDouble() ??
          0,
      totalCost:
          (json['total_cost'] as num?)?.toDouble() ??
          (json['estimated_total'] as num?)?.toDouble() ??
          (summary['best_price'] as num?)?.toDouble() ??
          (bestOffer['total_cost'] as num?)?.toDouble() ??
          0,
      bestOffer:
          (json['best_offer'] ??
                  json['recommended_shop'] ??
                  summary['best_product'] ??
                  bestOffer['product_name'] ??
                  '')
              .toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }
}
