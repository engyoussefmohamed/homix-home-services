import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../models/estimate_record.dart';
import '../models/technician_profile.dart';
import '../providers/auth_controller.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_bookings_screen.dart';
import '../screens/admin/audit_log_detail_screen.dart';
import '../screens/admin/payout_requests_screen.dart';
import '../screens/admin/technician_subscriptions_screen.dart';
import '../screens/admin/approve_products_screen.dart';
import '../screens/admin/approve_shops_screen.dart';
import '../screens/admin/audit_logs_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_customer_screen.dart';
import '../screens/auth/register_shop_owner_screen.dart';
import '../screens/auth/register_technician_screen.dart';
import '../screens/billing/billing_history_screen.dart';
import '../screens/customer/camera_estimation_screen.dart';
import '../screens/customer/customer_shell_screen.dart';
import '../screens/customer/customer_booking_detail_screen.dart';
import '../screens/customer/customer_notifications_screen.dart';
import '../screens/customer/estimation_result_screen.dart';
import '../screens/customer/my_bookings_screen.dart';
import '../screens/customer/technician_journey_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/shop_owner/add_product_screen.dart';
import '../screens/shop_owner/my_products_screen.dart';
import '../screens/shop_owner/shop_dashboard_screen.dart';
import '../screens/shop_owner/shop_subscription_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/technician/technician_shell_screen.dart';
import '../screens/technician/technician_booking_detail_screen.dart';
import '../screens/technician/technician_dashboard_screen.dart';
import '../screens/technician/technician_notifications_screen.dart';
import '../screens/technician/technician_subscription_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const registerCustomer = '/register/customer';
  static const registerShopOwner = '/register/shop-owner';
  static const registerTechnician = '/register/technician';
  static const customerHome = '/customer';
  static const cameraEstimation = '/customer/camera';
  static const estimationResult = '/customer/result';
  static const shopDashboard = '/shop-owner';
  static const addProduct = '/shop-owner/add-product';
  static const myProducts = '/shop-owner/products';
  static const orderDetails = '/orders/:orderId';
  static const adminDashboard = '/admin';
  static const approveShops = '/admin/shops';
  static const approveProducts = '/admin/products';
  static const adminBookings = '/admin/bookings';
  static const auditLogs = '/admin/audit-logs';
  static const auditLogDetails = '/admin/audit-logs/:logId';
  static const technicianSubscriptions = '/admin/technician-subscriptions';
  static const adminPayoutRequests = '/admin/payout-requests';
  static const technicianPreview = '/technician/preview';
  static const technicianDashboard = '/technician';
  static const technicianBookingDetails = '/technician/bookings/:bookingId';
  static const technicianNotifications = '/technician/notifications';
  static const technicianSubscription = '/technician/subscription';
  static const technicianJourney = '/technician/journey';
  static const myBookings = '/customer/bookings';
  static const customerNotifications = '/customer/notifications';
  static const customerBookingDetails = '/customer/bookings/:bookingId';
  static const shopSubscription = '/shop-owner/subscription';
  static const billingHistory = '/billing';

  static const _publicPages = {
    splash,
    onboarding,
    login,
    registerCustomer,
    registerShopOwner,
    registerTechnician,
  };

  static String homeForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return customerHome;
      case UserRole.shopOwner:
        return shopDashboard;
      case UserRole.technician:
        return technicianDashboard;
      case UserRole.admin:
        return adminDashboard;
    }
  }

  static String technicianBookingDetailsPath(String bookingId, {int tab = 0}) {
    return '/technician/bookings/$bookingId?tab=$tab';
  }

  static String customerBookingDetailsPath(String bookingId, {int tab = 0}) {
    return '/customer/bookings/$bookingId?tab=$tab';
  }

  static bool isPublicPath(String? path) => _publicPages.contains(path);

  static bool canAccessPath(UserRole role, String? path) {
    if (path == null || path.isEmpty) return true;
    if (role == UserRole.admin) return true;

    if (path == billingHistory) return true;

    if (path == orderDetails || path.startsWith('/orders/')) {
      return role == UserRole.customer || role == UserRole.shopOwner;
    }

    if (path == customerHome || path.startsWith('/customer/')) {
      return role == UserRole.customer;
    }

    if (path == shopDashboard || path.startsWith('/shop-owner/')) {
      return role == UserRole.shopOwner;
    }

    if (path == technicianDashboard ||
        path == technicianNotifications ||
        path == technicianSubscription ||
        path.startsWith('/technician/bookings/')) {
      return role == UserRole.technician;
    }

    if (path == technicianJourney) {
      return role == UserRole.customer;
    }

    if (path == technicianPreview) {
      return role == UserRole.technician;
    }

    if (path == adminDashboard || path.startsWith('/admin/')) {
      return role == UserRole.admin;
    }

    return true;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.registerCustomer,
        builder: (_, __) => const RegisterCustomerScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerShopOwner,
        builder: (_, __) => const RegisterShopOwnerScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerTechnician,
        builder: (_, __) => const RegisterTechnicianScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (_, state) => CustomerShellScreen(
          initialIndex: state.extra is int ? state.extra as int : 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.cameraEstimation,
        builder: (_, __) => const CameraEstimationScreen(),
      ),
      GoRoute(
        path: AppRoutes.estimationResult,
        builder: (_, state) {
          final estimate = state.extra;
          if (estimate is! EstimateRecord) {
            return const CustomerShellScreen();
          }
          return EstimationResultScreen(estimate: estimate);
        },
      ),
      GoRoute(
        path: AppRoutes.shopDashboard,
        builder: (_, __) => const ShopDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        builder: (_, __) => const AddProductScreen(),
      ),
      GoRoute(
        path: AppRoutes.myProducts,
        builder: (_, __) => const MyProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.approveShops,
        builder: (_, __) => const ApproveShopsScreen(),
      ),
      GoRoute(
        path: AppRoutes.approveProducts,
        builder: (_, __) => const ApproveProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminBookings,
        builder: (_, __) => const AdminBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.auditLogs,
        builder: (_, __) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.auditLogDetails,
        builder: (_, state) =>
            AuditLogDetailScreen(logId: state.pathParameters['logId']!),
      ),
      GoRoute(
        path: AppRoutes.technicianSubscriptions,
        builder: (_, __) => const TechnicianSubscriptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPayoutRequests,
        builder: (_, __) => const PayoutRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.technicianPreview,
        builder: (_, state) {
          final profile = state.extra;
          if (profile is! TechnicianProfile) {
            return const TechnicianDashboardScreen();
          }
          return TechnicianShellScreen(profile: profile);
        },
      ),
      GoRoute(
        path: AppRoutes.technicianDashboard,
        builder: (_, __) => const TechnicianDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.technicianBookingDetails,
        builder: (_, state) => TechnicianBookingDetailScreen(
          bookingId: state.pathParameters['bookingId']!,
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.technicianNotifications,
        builder: (_, __) => const TechnicianNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.technicianSubscription,
        builder: (_, __) => const TechnicianSubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.technicianJourney,
        builder: (_, state) {
          final profile = state.extra;
          if (profile is! TechnicianProfile) {
            return const CustomerShellScreen();
          }
          return TechnicianJourneyScreen(profile: profile);
        },
      ),
      GoRoute(
        path: AppRoutes.myBookings,
        builder: (_, __) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerNotifications,
        builder: (_, __) => const CustomerNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerBookingDetails,
        builder: (_, state) => CustomerBookingDetailScreen(
          bookingId: state.pathParameters['bookingId']!,
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.shopSubscription,
        builder: (_, __) => const ShopSubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.billingHistory,
        builder: (_, __) => const BillingHistoryScreen(),
      ),
    ],
    redirect: (_, state) {
      final path = state.uri.path;

      if (auth.isBootstrapping && path != AppRoutes.splash) {
        return AppRoutes.splash;
      }

      final isPublic = AppRoutes.isPublicPath(path);

      if (!auth.isAuthenticated) {
        return isPublic ? null : AppRoutes.login;
      }

      final user = auth.user;
      if (user == null) {
        return AppRoutes.login;
      }

      if (isPublic) {
        return AppRoutes.homeForRole(user.role);
      }

      if (!AppRoutes.canAccessPath(user.role, path)) {
        return AppRoutes.homeForRole(user.role);
      }

      return null;
    },
  );
});
