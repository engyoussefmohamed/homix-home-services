import 'package:flutter/material.dart';

import 'shop_dashboard_screen.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShopDashboardScreen(initialTab: 1);
  }
}
