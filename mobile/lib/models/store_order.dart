class StoreOrderItem {
  const StoreOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    return StoreOrderItem(
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class StoreOrderTimelineEntry {
  const StoreOrderTimelineEntry({
    required this.status,
    required this.label,
    required this.at,
  });

  final String status;
  final String label;
  final DateTime? at;

  factory StoreOrderTimelineEntry.fromJson(Map<String, dynamic> json) {
    return StoreOrderTimelineEntry(
      status: (json['status'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      at: json['at'] == null ? null : DateTime.tryParse(json['at'].toString()),
    );
  }
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.currency,
    required this.notes,
    required this.customerName,
    required this.customerEmail,
    required this.createdAt,
    required this.timeline,
    required this.items,
  });

  final String id;
  final String status;
  final double totalPrice;
  final String currency;
  final String notes;
  final String customerName;
  final String customerEmail;
  final DateTime? createdAt;
  final List<StoreOrderTimelineEntry> timeline;
  final List<StoreOrderItem> items;

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawTimeline = json['timeline'] as List<dynamic>? ?? const [];
    return StoreOrder(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'EGP').toString(),
      notes: (json['notes'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString(),
      customerEmail: (json['customer_email'] ?? '').toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      timeline: rawTimeline
          .map(
            (entry) => StoreOrderTimelineEntry.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      items: rawItems
          .map((item) => StoreOrderItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class PaginatedOrders {
  const PaginatedOrders({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<StoreOrder> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory PaginatedOrders.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return PaginatedOrders(
      items: rawItems
          .map((item) => StoreOrder.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 10,
      hasMore: json['has_more'] == true,
    );
  }
}
