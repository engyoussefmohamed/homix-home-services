class SubscriptionPlanItem {
  const SubscriptionPlanItem({
    required this.id,
    required this.code,
    required this.name,
    required this.monthlyPrice,
    required this.commissionRate,
    required this.priorityRank,
    required this.verifiedBadge,
    required this.guaranteedSupport,
    required this.description,
    required this.supportedDurations,
  });

  final String id;
  final String code;
  final String name;
  final double monthlyPrice;
  final double commissionRate;
  final int priorityRank;
  final bool verifiedBadge;
  final bool guaranteedSupport;
  final String description;
  final List<int> supportedDurations;

  double totalPriceFor(int months) => monthlyPrice * months;

  factory SubscriptionPlanItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanItem(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      monthlyPrice: (json['monthly_price'] as num?)?.toDouble() ?? 0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0,
      priorityRank: (json['priority_rank'] as num?)?.toInt() ?? 0,
      verifiedBadge: json['verified_badge'] == true,
      guaranteedSupport: json['guaranteed_support'] == true,
      description: (json['description'] ?? '').toString(),
      supportedDurations:
          (json['supported_durations'] as List<dynamic>? ?? const [1, 3, 6, 12])
              .map((item) => (item as num).toInt())
              .toList(),
    );
  }
}

class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.planCode,
    required this.planName,
    required this.commissionRate,
    required this.priorityRank,
    required this.verifiedBadge,
    required this.guaranteedSupport,
    required this.monthlyPrice,
    required this.status,
    required this.paymentReference,
    required this.startedAt,
    required this.expiresAt,
  });

  final String planCode;
  final String planName;
  final double commissionRate;
  final int priorityRank;
  final bool verifiedBadge;
  final bool guaranteedSupport;
  final double monthlyPrice;
  final String status;
  final String paymentReference;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  bool get isPro => planCode == 'pro';

  factory SubscriptionSnapshot.fromJson(Map<String, dynamic> json) {
    return SubscriptionSnapshot(
      planCode: (json['plan_code'] ?? 'basic').toString(),
      planName: (json['plan_name'] ?? 'مجاني').toString(),
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0,
      priorityRank: (json['priority_rank'] as num?)?.toInt() ?? 0,
      verifiedBadge: json['verified_badge'] == true,
      guaranteedSupport: json['guaranteed_support'] == true,
      monthlyPrice: (json['monthly_price'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'active').toString(),
      paymentReference: (json['payment_reference'] ?? '').toString(),
      startedAt: _parseDateTime(json['started_at']),
      expiresAt: _parseDateTime(json['expires_at']),
    );
  }
}

class PaymentTransactionItem {
  const PaymentTransactionItem({
    required this.id,
    required this.transactionType,
    required this.provider,
    required this.status,
    required this.amount,
    required this.currency,
    required this.externalReference,
    required this.paymentMethod,
    required this.description,
    required this.metadata,
    required this.createdAt,
    required this.booking,
    required this.subscription,
  });

  final String id;
  final String transactionType;
  final String provider;
  final String status;
  final double amount;
  final String currency;
  final String externalReference;
  final String paymentMethod;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final PaymentBookingSummary? booking;
  final PaymentSubscriptionSummary? subscription;

  factory PaymentTransactionItem.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionItem(
      id: (json['id'] ?? '').toString(),
      transactionType: (json['transaction_type'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'EGP').toString(),
      externalReference: (json['external_reference'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      createdAt: _parseDateTime(json['created_at']),
      booking: json['booking'] == null
          ? null
          : PaymentBookingSummary.fromJson(
              Map<String, dynamic>.from(json['booking'] as Map),
            ),
      subscription: json['subscription'] == null
          ? null
          : PaymentSubscriptionSummary.fromJson(
              Map<String, dynamic>.from(json['subscription'] as Map),
            ),
    );
  }
}

class PaymentBookingSummary {
  const PaymentBookingSummary({
    required this.id,
    required this.status,
    required this.scheduledFor,
    required this.technicianName,
  });

  final String id;
  final String status;
  final DateTime? scheduledFor;
  final String technicianName;

  factory PaymentBookingSummary.fromJson(Map<String, dynamic> json) {
    return PaymentBookingSummary(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      scheduledFor: _parseDateTime(json['scheduled_for']),
      technicianName: (json['technician_name'] ?? '').toString(),
    );
  }
}

class PaymentSubscriptionSummary {
  const PaymentSubscriptionSummary({
    required this.id,
    required this.status,
    required this.planName,
    required this.planCode,
    required this.startedAt,
    required this.expiresAt,
  });

  final String id;
  final String status;
  final String planName;
  final String planCode;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  factory PaymentSubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSubscriptionSummary(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      planName: (json['plan_name'] ?? '').toString(),
      planCode: (json['plan_code'] ?? '').toString(),
      startedAt: _parseDateTime(json['started_at']),
      expiresAt: _parseDateTime(json['expires_at']),
    );
  }
}

class PaymentSummary {
  const PaymentSummary({
    required this.currency,
    required this.totalPaid,
    required this.subscriptionPaid,
    required this.bookingPaid,
    required this.latestSubscriptionPlan,
  });

  final String currency;
  final double totalPaid;
  final double subscriptionPaid;
  final double bookingPaid;
  final String latestSubscriptionPlan;

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      currency: (json['currency'] ?? 'EGP').toString(),
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      subscriptionPaid: (json['subscription_paid'] as num?)?.toDouble() ?? 0,
      bookingPaid: (json['booking_paid'] as num?)?.toDouble() ?? 0,
      latestSubscriptionPlan: (json['latest_subscription_plan'] ?? '')
          .toString(),
    );
  }
}

class PaginatedPaymentTransactions {
  const PaginatedPaymentTransactions({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<PaymentTransactionItem> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory PaginatedPaymentTransactions.fromJson(Map<String, dynamic> json) {
    return PaginatedPaymentTransactions(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) => PaymentTransactionItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      hasMore: json['has_more'] == true,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
