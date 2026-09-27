import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/estimate_record.dart';
import '../models/product_item.dart';
import '../models/shop_item.dart';
import '../models/service_booking.dart';
import '../models/store_order.dart';
import '../models/subscription_models.dart';
import '../models/technician_dashboard_models.dart';
import '../models/technician_profile.dart';

const _tokenKey = 'auth_token';
const _refreshTokenKey = 'refresh_token';
const _deviceIdKey = 'device_registration_id';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _resolveBaseUrl(),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: _mapErrorMessage(error),
            ),
          );
        },
      ),
    );
  }

  final Dio _dio;
  static final _localApiBaseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://localhost:8000/api/v1';

  static String _resolveBaseUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return _localApiBaseUrl;
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getSavedRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<AppUser?> restoreUser() async {
    var token = await getSavedToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await getCurrentUser(token);
    } on DioException {
      final refreshed = await refreshSession();
      if (!refreshed) {
        await clearToken();
        return null;
      }
      token = await getSavedToken();
      if (token == null || token.isEmpty) return null;
      return await getCurrentUser(token);
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final body = _asMap(response.data);
    final accessToken = _extractToken(body);
    final refreshToken = _extractRefreshToken(body);
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('لم يتم استلام access token من الخادم.');
    }
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    return getCurrentUser(accessToken);
  }

  Future<AppUser> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'customer',
      },
    );
    final body = _asMap(response.data);
    final accessToken = _extractToken(body);
    final refreshToken = _extractRefreshToken(body);
    if (accessToken != null && accessToken.isNotEmpty) {
      await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      return getCurrentUser(accessToken);
    }
    return AppUser.fromJson(_extractUserMap(body));
  }

  Future<AppUser> registerShopOwner({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String shopName,
    required String city,
  }) async {
    final authResponse = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'shop_owner',
      },
    );
    final authBody = _asMap(authResponse.data);
    final accessToken = _extractToken(authBody);
    final refreshToken = _extractRefreshToken(authBody);
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('تم إنشاء الحساب بدون access token صالح.');
    }
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    await _dio.post(
      '/shops/register',
      data: {'name': shopName, 'address': city},
      options: Options(headers: _authHeaders(accessToken)),
    );

    return getCurrentUser(accessToken);
  }

  Future<AppUser> registerTechnician({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String title,
    required String category,
    required String city,
    required double hourlyRate,
    required double yearsExperience,
    required String bio,
  }) async {
    final response = await _dio.post(
      '/auth/register-technician',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'title': title,
        'category': category,
        'city': city,
        'hourly_rate': hourlyRate,
        'years_experience': yearsExperience,
        'bio': bio,
      },
    );
    final body = _asMap(response.data);
    final accessToken = _extractToken(body);
    final refreshToken = _extractRefreshToken(body);
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('تم إنشاء حساب الفني بدون access token صالح.');
    }
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    return getCurrentUser(accessToken);
  }

  Future<AppUser> getCurrentUser(String token) async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(headers: _authHeaders(token)),
    );
    return AppUser.fromJson(_extractUserMap(_asMap(response.data)));
  }

  Future<bool> refreshSession() async {
    final refreshToken = await getSavedRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final body = _asMap(response.data);
      final accessToken = _extractToken(body);
      final nextRefreshToken = _extractRefreshToken(body);
      if (accessToken == null || accessToken.isEmpty) return false;
      await saveTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken ?? refreshToken,
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> logoutAllSessions(String token) async {
    await _dio.post(
      '/auth/logout-all',
      options: Options(headers: _authHeaders(token)),
    );
    await clearToken();
  }

  Future<String> getOrCreateDeviceRegistrationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated =
        'homix-${Platform.operatingSystem}-${DateTime.now().microsecondsSinceEpoch}';
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  Future<List<EstimateRecord>> getMyEstimates(String token) async {
    final response = await _dio.get(
      '/auth/my-estimates',
      options: Options(headers: _authHeaders(token)),
    );
    return _extractList(
      response.data,
    ).map((item) => EstimateRecord.fromJson(_asMap(item))).toList();
  }

  Future<EstimateRecord> submitEstimate({
    required String token,
    required File image,
    required double height,
    required double width,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path),
      'height': height,
      'width': width,
    });
    final response = await _dio.post(
      '/estimate',
      data: form,
      options: Options(headers: _authHeaders(token)),
    );
    return EstimateRecord.fromJson(_extractPrimaryMap(response.data));
  }

  Future<List<ProductItem>> getProducts() async {
    final response = await _dio.get('/products/');
    return _extractList(
      response.data,
    ).map((item) => ProductItem.fromJson(_asMap(item))).toList();
  }

  Future<void> addProduct({
    required String token,
    required String name,
    required String description,
    required double volumeLiters,
    required double price,
  }) async {
    await _dio.post(
      '/products/',
      data: {
        'name': name,
        'description': description,
        'volume_liters': volumeLiters,
        'unit_price': price,
      },
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<List<ShopItem>> getPendingShops(String token) async {
    final response = await _dio.get(
      '/shops/pending',
      options: Options(headers: _authHeaders(token)),
    );
    return _extractList(
      response.data,
    ).map((item) => ShopItem.fromJson(_asMap(item))).toList();
  }

  Future<void> updateShopStatus({
    required String token,
    required String shopId,
    required String status,
  }) async {
    await _dio.patch(
      '/shops/$shopId/status',
      queryParameters: {'action': status == 'approved' ? 'approve' : 'reject'},
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<List<ProductItem>> getPendingProducts(String token) async {
    final response = await _dio.get(
      '/products/pending',
      options: Options(headers: _authHeaders(token)),
    );
    return _extractList(
      response.data,
    ).map((item) => ProductItem.fromJson(_asMap(item))).toList();
  }

  Future<List<ProductItem>> getMyProducts(String token) async {
    final response = await _dio.get(
      '/products/mine',
      options: Options(headers: _authHeaders(token)),
    );
    return _extractList(
      response.data,
    ).map((item) => ProductItem.fromJson(_asMap(item))).toList();
  }

  Future<ShopItem?> getMyShop(String token) async {
    final response = await _dio.get(
      '/shops/me',
      options: Options(headers: _authHeaders(token)),
    );
    if (response.data == null) return null;
    final data = _extractPrimaryMap(response.data);
    if (data.isEmpty) return null;
    return ShopItem.fromJson(data);
  }

  Future<void> updateProductStatus({
    required String token,
    required String productId,
    required String status,
  }) async {
    await _dio.patch(
      '/products/$productId/status',
      queryParameters: {'action': status == 'approved' ? 'approve' : 'reject'},
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<Map<String, dynamic>> getAdminStats(String token) async {
    final response = await _dio.get(
      '/admin/stats',
      options: Options(headers: _authHeaders(token)),
    );
    return _extractPrimaryMap(response.data);
  }

  Future<Map<String, dynamic>> getAuditLogs(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/admin/audit-logs',
      queryParameters: {'page': page, 'page_size': pageSize},
      options: Options(headers: _authHeaders(token)),
    );
    return _extractPrimaryMap(response.data);
  }

  Future<Map<String, dynamic>> getAuditLogDetails({
    required String token,
    required String logId,
  }) async {
    final response = await _dio.get(
      '/admin/audit-logs/$logId',
      options: Options(headers: _authHeaders(token)),
    );
    return _extractPrimaryMap(response.data);
  }

  Future<Map<String, dynamic>> getAdminPayoutRequests(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final response = await _dio.get(
      '/admin/payout-requests',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return _extractPrimaryMap(response.data);
  }

  Future<Map<String, dynamic>> getAdminBookings(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final response = await _dio.get(
      '/admin/bookings',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return _extractPrimaryMap(response.data);
  }

  Future<Map<String, dynamic>> updateAdminPayoutRequest({
    required String token,
    required String payoutId,
    required String action,
    String? rejectionReason,
    String? paymentReference,
  }) async {
    final response = await _dio.patch(
      '/admin/payout-requests/$payoutId',
      data: {
        'action': action,
        'rejection_reason': rejectionReason,
        'payment_reference': paymentReference,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return _extractPrimaryMap(response.data);
  }

  Future<void> updateServiceBookingStatus({
    required String token,
    required String bookingId,
    required String action,
  }) async {
    await _dio.patch(
      '/bookings/$bookingId/status',
      queryParameters: {'action': action},
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<StoreOrder> createOrder({
    required String token,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/orders/',
      data: {'items': items, 'notes': notes},
      options: Options(headers: _authHeaders(token)),
    );
    return StoreOrder.fromJson(_extractPrimaryMap(response.data));
  }

  Future<PaginatedOrders> getMyOrders(
    String token, {
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/orders/mine',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return PaginatedOrders.fromJson(_extractPrimaryMap(response.data));
  }

  Future<PaginatedOrders> getShopOrders(
    String token, {
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/orders/shop',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return PaginatedOrders.fromJson(_extractPrimaryMap(response.data));
  }

  Future<StoreOrder> getOrderDetails({
    required String token,
    required String orderId,
  }) async {
    final response = await _dio.get(
      '/orders/$orderId',
      options: Options(headers: _authHeaders(token)),
    );
    return StoreOrder.fromJson(_extractPrimaryMap(response.data));
  }

  Future<void> updateOrderStatus({
    required String token,
    required String orderId,
    required String action,
  }) async {
    await _dio.patch(
      '/orders/$orderId/status',
      queryParameters: {'action': action},
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<List<TechnicianProfile>> getTechnicians({
    String? query,
    String? category,
    String? city,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/technicians',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category.isNotEmpty && category != 'الكل')
          'category': category,
        if (city != null && city.isNotEmpty) 'city': city,
      },
    );
    final body = _extractPrimaryMap(response.data);
    return (body['items'] as List<dynamic>? ?? const [])
        .map((item) => TechnicianProfile.fromJson(_asMap(item)))
        .toList();
  }

  Future<TechnicianProfile> getTechnicianDetails(String technicianId) async {
    final response = await _dio.get('/technicians/$technicianId');
    return TechnicianProfile.fromJson(_extractPrimaryMap(response.data));
  }

  Future<TechnicianProfile> getMyTechnicianProfile(String token) async {
    final response = await _dio.get(
      '/technician/me',
      options: Options(headers: _authHeaders(token)),
    );
    return TechnicianProfile.fromJson(_extractPrimaryMap(response.data));
  }

  Future<PaginatedServiceBookings> getMyTechnicianBookings(
    String token, {
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/technician/bookings',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return PaginatedServiceBookings.fromJson(_extractPrimaryMap(response.data));
  }

  Future<TechnicianEarningsSummary> getMyTechnicianEarnings(
    String token,
  ) async {
    final response = await _dio.get(
      '/technician/earnings',
      options: Options(headers: _authHeaders(token)),
    );
    return TechnicianEarningsSummary.fromJson(
      _extractPrimaryMap(response.data),
    );
  }

  Future<PaginatedTechnicianPayouts> getMyTechnicianPayouts(
    String token, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/technician/payouts',
      queryParameters: {'page': page, 'page_size': pageSize},
      options: Options(headers: _authHeaders(token)),
    );
    return PaginatedTechnicianPayouts.fromJson(
      _extractPrimaryMap(response.data),
    );
  }

  Future<TechnicianPayoutRequestItem> requestTechnicianPayout({
    required String token,
    required double amount,
    String? destinationLabel,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/technician/payouts',
      data: {
        'amount': amount,
        'destination_label': destinationLabel,
        'notes': notes,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return TechnicianPayoutRequestItem.fromJson(
      _extractPrimaryMap(response.data),
    );
  }

  Future<TechnicianProfile> updateMyTechnicianProfile({
    required String token,
    required String name,
    required String title,
    required String city,
    required double hourlyRate,
    required String bio,
    required List<String> serviceAreas,
    required List<String> skills,
  }) async {
    final response = await _dio.patch(
      '/technician/profile',
      data: {
        'name': name,
        'title': title,
        'city': city,
        'hourly_rate': hourlyRate,
        'bio': bio,
        'service_areas': serviceAreas,
        'skills': skills,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return TechnicianProfile.fromJson(_extractPrimaryMap(response.data));
  }

  Future<bool> updateMyTechnicianAvailability({
    required String token,
    required bool isAvailable,
  }) async {
    final response = await _dio.patch(
      '/technician/availability',
      data: {'is_available': isAvailable},
      options: Options(headers: _authHeaders(token)),
    );
    final body = _extractPrimaryMap(response.data);
    if (body.containsKey('is_available')) {
      return body['is_available'] == true;
    }
    return isAvailable;
  }

  Future<ServiceBooking> createBooking({
    required String token,
    required String technicianId,
    required DateTime scheduledFor,
    required String address,
    required String problemDescription,
  }) async {
    final response = await _dio.post(
      '/bookings',
      data: {
        'technician_id': technicianId,
        'scheduled_for': scheduledFor.toUtc().toIso8601String(),
        'address': address,
        'problem_description': problemDescription,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return ServiceBooking.fromJson(_extractPrimaryMap(response.data));
  }

  Future<PaginatedServiceBookings> getMyBookings(
    String token, {
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/bookings/mine',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return PaginatedServiceBookings.fromJson(_extractPrimaryMap(response.data));
  }

  Future<ServiceBooking> getBookingDetails({
    required String token,
    required String bookingId,
  }) async {
    final response = await _dio.get(
      '/bookings/$bookingId',
      options: Options(headers: _authHeaders(token)),
    );
    return ServiceBooking.fromJson(_extractPrimaryMap(response.data));
  }

  Future<void> payForBooking({
    required String token,
    required String bookingId,
    required String method,
  }) async {
    await _dio.post(
      '/bookings/$bookingId/payment',
      data: {'method': method},
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<ServiceBooking> rescheduleBooking({
    required String token,
    required String bookingId,
    required DateTime scheduledFor,
  }) async {
    final response = await _dio.patch(
      '/bookings/$bookingId/reschedule',
      data: {'scheduled_for': scheduledFor.toUtc().toIso8601String()},
      options: Options(headers: _authHeaders(token)),
    );
    return ServiceBooking.fromJson(_extractPrimaryMap(response.data));
  }

  Future<void> cancelBooking({
    required String token,
    required String bookingId,
  }) async {
    await _dio.patch(
      '/bookings/$bookingId/cancel',
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<void> sendBookingMessage({
    required String token,
    required String bookingId,
    required String message,
  }) async {
    await _dio.post(
      '/bookings/$bookingId/messages',
      data: {'message': message},
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<ServiceBooking> submitBookingReview({
    required String token,
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post(
      '/bookings/$bookingId/review',
      data: {'rating': rating, 'comment': comment},
      options: Options(headers: _authHeaders(token)),
    );
    return ServiceBooking.fromJson(_extractPrimaryMap(response.data));
  }

  Future<List<AppNotificationItem>> getMyNotifications(
    String token, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/notifications/mine',
      queryParameters: {'page': page, 'page_size': pageSize},
      options: Options(headers: _authHeaders(token)),
    );
    final body = _extractPrimaryMap(response.data);
    return (body['items'] as List<dynamic>? ?? const [])
        .map((item) => AppNotificationItem.fromJson(_asMap(item)))
        .toList();
  }

  Future<int> getUnreadNotificationsCount(String token) async {
    final response = await _dio.get(
      '/notifications/unread-count',
      options: Options(headers: _authHeaders(token)),
    );
    final body = _extractPrimaryMap(response.data);
    return (body['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> registerNotificationDevice(
    String token, {
    required String deviceToken,
    required String provider,
    required String platform,
    String? deviceName,
    bool pushEnabled = true,
  }) async {
    await _dio.post(
      '/notifications/devices',
      data: {
        'device_token': deviceToken,
        'provider': provider,
        'platform': platform,
        'device_name': deviceName,
        'push_enabled': pushEnabled,
      },
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<void> registerCurrentDevice(String token) async {
    final deviceToken = await getOrCreateDeviceRegistrationId();
    await registerNotificationDevice(
      token,
      deviceToken: deviceToken,
      provider: 'internal',
      platform: Platform.operatingSystem,
      deviceName: Platform.localHostname,
      pushEnabled: true,
    );
  }

  Future<void> markNotificationRead({
    required String token,
    required String notificationId,
  }) async {
    await _dio.post(
      '/notifications/$notificationId/read',
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<List<SubscriptionPlanItem>> getSubscriptionPlans() async {
    final response = await _dio.get('/subscriptions/plans');
    return _extractList(
      response.data,
    ).map((item) => SubscriptionPlanItem.fromJson(_asMap(item))).toList();
  }

  Future<SubscriptionSnapshot> getMyShopSubscription(String token) async {
    final response = await _dio.get(
      '/subscriptions/shop/me',
      options: Options(headers: _authHeaders(token)),
    );
    return SubscriptionSnapshot.fromJson(_extractPrimaryMap(response.data));
  }

  Future<SubscriptionSnapshot> subscribeShop({
    required String token,
    required String planCode,
    int durationMonths = 1,
  }) async {
    final response = await _dio.post(
      '/subscriptions/shop/checkout',
      data: {'plan_code': planCode, 'duration_months': durationMonths},
      options: Options(headers: _authHeaders(token)),
    );
    return SubscriptionSnapshot.fromJson(
      Map<String, dynamic>.from(
        _extractPrimaryMap(response.data)['subscription'] as Map? ?? const {},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getTechnicianSubscriptions(
    String token,
  ) async {
    final response = await _dio.get(
      '/subscriptions/technicians',
      options: Options(headers: _authHeaders(token)),
    );
    return _extractList(response.data).map((item) => _asMap(item)).toList();
  }

  Future<SubscriptionSnapshot> subscribeTechnician({
    required String token,
    required String technicianId,
    required String planCode,
    int durationMonths = 1,
  }) async {
    final response = await _dio.post(
      '/subscriptions/technicians/$technicianId/checkout',
      data: {'plan_code': planCode, 'duration_months': durationMonths},
      options: Options(headers: _authHeaders(token)),
    );
    return SubscriptionSnapshot.fromJson(
      Map<String, dynamic>.from(
        _extractPrimaryMap(response.data)['subscription'] as Map? ?? const {},
      ),
    );
  }

  Future<SubscriptionSnapshot> getMyTechnicianSubscription(String token) async {
    final response = await _dio.get(
      '/subscriptions/technician/me',
      options: Options(headers: _authHeaders(token)),
    );
    return SubscriptionSnapshot.fromJson(_extractPrimaryMap(response.data));
  }

  Future<SubscriptionSnapshot> subscribeCurrentTechnician({
    required String token,
    required String planCode,
    int durationMonths = 1,
  }) async {
    final response = await _dio.post(
      '/subscriptions/technician/checkout',
      data: {'plan_code': planCode, 'duration_months': durationMonths},
      options: Options(headers: _authHeaders(token)),
    );
    return SubscriptionSnapshot.fromJson(
      Map<String, dynamic>.from(
        _extractPrimaryMap(response.data)['subscription'] as Map? ?? const {},
      ),
    );
  }

  Future<void> updateTechnicianBookingStatus({
    required String token,
    required String bookingId,
    required String action,
  }) async {
    await _dio.patch(
      '/bookings/$bookingId/status',
      queryParameters: {'action': action},
      options: Options(headers: _authHeaders(token)),
    );
  }

  Future<PaginatedPaymentTransactions> getMyPaymentTransactions(
    String token, {
    String? transactionType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/payments/mine',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (transactionType != null && transactionType.isNotEmpty)
          'transaction_type': transactionType,
      },
      options: Options(headers: _authHeaders(token)),
    );
    return PaginatedPaymentTransactions.fromJson(
      _extractPrimaryMap(response.data),
    );
  }

  Future<PaymentSummary> getMyPaymentSummary(String token) async {
    final response = await _dio.get(
      '/payments/summary',
      options: Options(headers: _authHeaders(token)),
    );
    return PaymentSummary.fromJson(_extractPrimaryMap(response.data));
  }

  Map<String, String> _authHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  String? _extractToken(Map<String, dynamic> body) {
    if (body['access_token'] != null) return body['access_token'].toString();
    if (body['token'] != null) return body['token'].toString();
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      if (data['access_token'] != null) return data['access_token'].toString();
      if (data['token'] != null) return data['token'].toString();
    }
    return null;
  }

  String? _extractRefreshToken(Map<String, dynamic> body) {
    if (body['refresh_token'] != null) return body['refresh_token'].toString();
    final data = body['data'];
    if (data is Map<String, dynamic> && data['refresh_token'] != null) {
      return data['refresh_token'].toString();
    }
    return null;
  }

  Map<String, dynamic> _extractUserMap(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) return _asMap(data['user']);
      return data;
    }
    if (body['user'] is Map<String, dynamic>) return _asMap(body['user']);
    return body;
  }

  Map<String, dynamic> _extractPrimaryMap(dynamic data) {
    final body = _asMap(data);
    final wrapped = body['data'];
    if (wrapped is Map<String, dynamic>) return wrapped;
    return body;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    final body = _asMap(data);
    if (body['data'] is List) return body['data'] as List<dynamic>;
    if (body['items'] is List) return body['items'] as List<dynamic>;
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  String _mapErrorMessage(DioException error) {
    final body = _asMap(error.response?.data);
    final detail = body['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'انتهت مهلة الاتصال بالخادم.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'تعذر الوصول إلى الخادم. تأكد من تشغيل الخدمة وإعداد API_BASE_URL.';
    }
    if (error.response?.statusCode == 401) {
      return 'بيانات الدخول غير صحيحة أو انتهت الجلسة.';
    }
    if (error.response?.statusCode == 403) {
      return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
    }
    if (error.response?.statusCode == 429) {
      return 'تم تجاوز عدد الطلبات المسموح. حاول مرة أخرى بعد قليل.';
    }
    if (error.response?.statusCode == 500) {
      return 'حدث خطأ داخلي في الخادم.';
    }
    return 'حدث خطأ غير متوقع أثناء الاتصال بالخادم.';
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
