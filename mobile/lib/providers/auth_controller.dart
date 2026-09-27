import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref.read(apiServiceProvider))..bootstrap();
});

class AuthController extends ChangeNotifier {
  AuthController(this._api);

  final ApiService _api;

  AppUser? user;
  bool isLoading = false;
  bool isBootstrapping = true;
  String? _token;
  String? errorMessage;

  String? get token => _token;
  bool get isAuthenticated => user != null && _token != null;

  Future<void> bootstrap() async {
    isBootstrapping = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _api.restoreUser();
      _token = await _api.getSavedToken();
      await _registerDeviceIfPossible();
    } catch (_) {
      await _api.clearToken();
      user = null;
      _token = null;
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    return _runGuarded(() async {
      user = await _api.login(email: email, password: password);
      _token = await _api.getSavedToken();
      await _registerDeviceIfPossible();
    });
  }

  Future<bool> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    return _runGuarded(() async {
      user = await _api.registerCustomer(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _token = await _api.getSavedToken();
      await _registerDeviceIfPossible();
    });
  }

  Future<bool> registerShopOwner({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String shopName,
    required String city,
  }) async {
    return _runGuarded(() async {
      user = await _api.registerShopOwner(
        name: name,
        email: email,
        password: password,
        phone: phone,
        shopName: shopName,
        city: city,
      );
      _token = await _api.getSavedToken();
      await _registerDeviceIfPossible();
    });
  }

  Future<bool> registerTechnician({
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
    return _runGuarded(() async {
      user = await _api.registerTechnician(
        name: name,
        email: email,
        password: password,
        phone: phone,
        title: title,
        category: category,
        city: city,
        hourlyRate: hourlyRate,
        yearsExperience: yearsExperience,
        bio: bio,
      );
      _token = await _api.getSavedToken();
      await _registerDeviceIfPossible();
    });
  }

  Future<void> logout() async {
    await _api.clearToken();
    user = null;
    _token = null;
    notifyListeners();
  }

  Future<bool> _runGuarded(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _registerDeviceIfPossible() async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    try {
      await _api.registerCurrentDevice(token);
    } catch (_) {
      // Device registration is best-effort until a real push provider is connected.
    }
  }
}
