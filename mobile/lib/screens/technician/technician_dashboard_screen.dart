import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import 'technician_shell_screen.dart';

final myTechnicianProfileProvider = FutureProvider.autoDispose((ref) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null || token.isEmpty) {
    throw Exception('يجب تسجيل الدخول بحساب فني.');
  }
  return ref.watch(apiServiceProvider).getMyTechnicianProfile(token);
});

class TechnicianDashboardScreen extends ConsumerWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myTechnicianProfileProvider);
    return profileAsync.when(
      data: (profile) => TechnicianShellScreen(profile: profile),
      loading: () => const Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: AppAtmosphere(
                topColor: AppColors.background,
                bottomColor: AppColors.backgroundTertiary,
              ),
            ),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (error, _) => Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(
              child: AppAtmosphere(
                topColor: AppColors.background,
                bottomColor: AppColors.backgroundTertiary,
              ),
            ),
            Center(child: AsyncPlaceholder(message: error.toString())),
          ],
        ),
      ),
    );
  }
}
