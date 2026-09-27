import 'service_booking.dart';
import 'technician_profile.dart';

class TechnicianEarningTransaction {
  const TechnicianEarningTransaction({
    required this.bookingId,
    required this.title,
    required this.customerName,
    required this.completedAt,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.currency,
    required this.paymentStatus,
  });

  final String bookingId;
  final String title;
  final String customerName;
  final DateTime? completedAt;
  final double grossAmount;
  final double commissionAmount;
  final double netAmount;
  final String currency;
  final String paymentStatus;

  factory TechnicianEarningTransaction.fromJson(Map<String, dynamic> json) {
    return TechnicianEarningTransaction(
      bookingId: (json['booking_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString(),
      completedAt: _parseDateTime(json['completed_at']),
      grossAmount: (json['gross_amount'] as num?)?.toDouble() ?? 0,
      commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'EGP').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
    );
  }
}

class TechnicianEarningsSummary {
  const TechnicianEarningsSummary({
    required this.currency,
    required this.currentMonthLabel,
    required this.grossEarnings,
    required this.commissionRate,
    required this.commissionAmount,
    required this.netEarnings,
    required this.completedBookings,
    required this.averageTicket,
    required this.pendingPayout,
    required this.paidOut,
    required this.availableBalance,
    required this.recentTransactions,
  });

  final String currency;
  final String currentMonthLabel;
  final double grossEarnings;
  final double commissionRate;
  final double commissionAmount;
  final double netEarnings;
  final int completedBookings;
  final double averageTicket;
  final double pendingPayout;
  final double paidOut;
  final double availableBalance;
  final List<TechnicianEarningTransaction> recentTransactions;

  factory TechnicianEarningsSummary.fromJson(Map<String, dynamic> json) {
    return TechnicianEarningsSummary(
      currency: (json['currency'] ?? 'EGP').toString(),
      currentMonthLabel: (json['current_month_label'] ?? '').toString(),
      grossEarnings: (json['gross_earnings'] as num?)?.toDouble() ?? 0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0,
      commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0,
      netEarnings: (json['net_earnings'] as num?)?.toDouble() ?? 0,
      completedBookings: (json['completed_bookings'] as num?)?.toInt() ?? 0,
      averageTicket: (json['average_ticket'] as num?)?.toDouble() ?? 0,
      pendingPayout: (json['pending_payout'] as num?)?.toDouble() ?? 0,
      paidOut: (json['paid_out'] as num?)?.toDouble() ?? 0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0,
      recentTransactions: (json['recent_transactions'] as List<dynamic>? ?? const [])
          .map((item) => TechnicianEarningTransaction.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class TechnicianPayoutRequestItem {
  const TechnicianPayoutRequestItem({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.destinationLabel,
    required this.notes,
    required this.rejectionReason,
    required this.paymentReference,
    required this.createdAt,
    required this.reviewedAt,
    required this.paidAt,
  });

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String destinationLabel;
  final String notes;
  final String rejectionReason;
  final String paymentReference;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final DateTime? paidAt;

  factory TechnicianPayoutRequestItem.fromJson(Map<String, dynamic> json) {
    return TechnicianPayoutRequestItem(
      id: (json['id'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'EGP').toString(),
      status: (json['status'] ?? 'pending').toString(),
      destinationLabel: (json['destination_label'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      rejectionReason: (json['rejection_reason'] ?? '').toString(),
      paymentReference: (json['payment_reference'] ?? '').toString(),
      createdAt: _parseDateTime(json['created_at']),
      reviewedAt: _parseDateTime(json['reviewed_at']),
      paidAt: _parseDateTime(json['paid_at']),
    );
  }
}

class PaginatedTechnicianPayouts {
  const PaginatedTechnicianPayouts({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<TechnicianPayoutRequestItem> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory PaginatedTechnicianPayouts.fromJson(Map<String, dynamic> json) {
    return PaginatedTechnicianPayouts(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => TechnicianPayoutRequestItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 10,
      hasMore: json['has_more'] == true,
    );
  }
}

class TechnicianDashboardData {
  const TechnicianDashboardData({
    required this.profile,
    required this.bookings,
    required this.earnings,
  });

  final TechnicianProfile profile;
  final PaginatedServiceBookings bookings;
  final TechnicianEarningsSummary earnings;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

