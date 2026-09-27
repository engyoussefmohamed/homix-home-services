import 'subscription_models.dart';

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.status,
    required this.ownerName,
    required this.city,
    required this.description,
    required this.phone,
    required this.address,
    required this.subscription,
  });

  final String id;
  final String name;
  final String status;
  final String ownerName;
  final String city;
  final String description;
  final String phone;
  final String address;
  final SubscriptionSnapshot subscription;

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['shop_name'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      ownerName: (json['owner_name'] ?? json['owner'] ?? '').toString(),
      city: (json['city'] ?? json['address'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? json['city'] ?? '').toString(),
      subscription: SubscriptionSnapshot.fromJson(
        Map<String, dynamic>.from(json['subscription'] as Map? ?? const {}),
      ),
    );
  }
}
