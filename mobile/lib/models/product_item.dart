class ProductItem {
  const ProductItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.price,
    required this.status,
    required this.category,
    required this.volumeLiters,
    required this.currency,
    required this.description,
  });

  final String id;
  final String shopId;
  final String name;
  final double price;
  final String status;
  final String category;
  final double volumeLiters;
  final String currency;
  final String description;

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final description = (json['description'] ?? '').toString();
    final volumeLiters = (json['volume_liters'] as num?)?.toDouble() ?? 0;
    return ProductItem(
      id: (json['id'] ?? '').toString(),
      shopId: (json['shop_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price:
          (json['price'] as num?)?.toDouble() ??
          (json['unit_price'] as num?)?.toDouble() ??
          0,
      status: (json['status'] ?? 'pending').toString(),
      category:
          (json['category'] ??
                  json['type'] ??
                  description ??
                  (volumeLiters > 0 ? '$volumeLiters L' : ''))
              .toString(),
      volumeLiters: volumeLiters,
      currency: (json['currency'] ?? 'EGP').toString(),
      description: description,
    );
  }
}
