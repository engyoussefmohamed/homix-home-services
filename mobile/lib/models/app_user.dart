enum UserRole { customer, shopOwner, technician, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.customer => 'عميل',
    UserRole.shopOwner => 'صاحب محل',
    UserRole.technician => 'فني',
    UserRole.admin => 'مدير',
  };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: _roleFromString((json['role'] ?? 'customer').toString()),
    );
  }

  static UserRole _roleFromString(String value) {
    switch (value) {
      case 'shop_owner':
        return UserRole.shopOwner;
      case 'technician':
        return UserRole.technician;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
}
