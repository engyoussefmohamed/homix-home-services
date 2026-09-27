import 'technician_profile.dart';

class BookingTrackingEntry {
  const BookingTrackingEntry({
    required this.id,
    required this.status,
    required this.label,
    required this.details,
    required this.etaMinutes,
    required this.createdAt,
  });

  final String id;
  final String status;
  final String label;
  final String details;
  final int? etaMinutes;
  final DateTime? createdAt;

  factory BookingTrackingEntry.fromJson(Map<String, dynamic> json) {
    return BookingTrackingEntry(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class BookingMessageItem {
  const BookingMessageItem({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String senderType;
  final String senderName;
  final String message;
  final DateTime? createdAt;

  bool get isIncoming => senderType != 'customer';

  factory BookingMessageItem.fromJson(Map<String, dynamic> json) {
    return BookingMessageItem(
      id: (json['id'] ?? '').toString(),
      senderType: (json['sender_type'] ?? '').toString(),
      senderName: (json['sender_name'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class ServiceBooking {
  const ServiceBooking({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.scheduledFor,
    required this.address,
    required this.problemDescription,
    required this.estimatedPrice,
    required this.currency,
    required this.paymentMethod,
    required this.paymentReference,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.technician,
    required this.tracking,
    required this.messages,
    required this.review,
  });

  final String id;
  final String status;
  final String paymentStatus;
  final DateTime? scheduledFor;
  final String address;
  final String problemDescription;
  final double estimatedPrice;
  final String currency;
  final String paymentMethod;
  final String paymentReference;
  final DateTime? createdAt;
  final String customerName;
  final String customerEmail;
  final TechnicianProfile technician;
  final List<BookingTrackingEntry> tracking;
  final List<BookingMessageItem> messages;
  final TechnicianReview? review;

  ServiceBooking copyWith({
    String? status,
    String? paymentStatus,
    DateTime? scheduledFor,
    String? address,
    String? problemDescription,
    double? estimatedPrice,
    String? currency,
    String? paymentMethod,
    String? paymentReference,
    DateTime? createdAt,
    String? customerName,
    String? customerEmail,
    TechnicianProfile? technician,
    List<BookingTrackingEntry>? tracking,
    List<BookingMessageItem>? messages,
    TechnicianReview? review,
  }) {
    return ServiceBooking(
      id: id,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      address: address ?? this.address,
      problemDescription: problemDescription ?? this.problemDescription,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      technician: technician ?? this.technician,
      tracking: tracking ?? this.tracking,
      messages: messages ?? this.messages,
      review: review ?? this.review,
    );
  }

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    return ServiceBooking(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      scheduledFor: _parseDateTime(json['scheduled_for']),
      address: (json['address'] ?? '').toString(),
      problemDescription: (json['problem_description'] ?? '').toString(),
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'EGP').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      paymentReference: (json['payment_reference'] ?? '').toString(),
      createdAt: _parseDateTime(json['created_at']),
      customerName: (json['customer_name'] ?? '').toString(),
      customerEmail: (json['customer_email'] ?? '').toString(),
      technician: TechnicianProfile.fromJson(
        Map<String, dynamic>.from(json['technician'] as Map? ?? const {}),
      ),
      tracking: (json['tracking'] as List<dynamic>? ?? const [])
          .map((item) => BookingTrackingEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((item) => BookingMessageItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      review: json['review'] == null
          ? null
          : TechnicianReview.fromJson(Map<String, dynamic>.from(json['review'] as Map)),
    );
  }
}

class PaginatedServiceBookings {
  const PaginatedServiceBookings({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<ServiceBooking> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory PaginatedServiceBookings.fromJson(Map<String, dynamic> json) {
    return PaginatedServiceBookings(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => ServiceBooking.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 10,
      hasMore: json['has_more'] == true,
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.bookingId,
    required this.category,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String category;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: (json['id'] ?? '').toString(),
      bookingId: (json['booking_id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      isRead: json['is_read'] == true,
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

