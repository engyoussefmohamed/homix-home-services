import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/app_router.dart';
import '../../models/product_item.dart';
import '../../models/shop_item.dart';
import '../../models/store_order.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final myShopProvider = FutureProvider.autoDispose<ShopItem?>((ref) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) return null;
  return ref.watch(apiServiceProvider).getMyShop(token);
});

final myProductsProvider = FutureProvider.autoDispose<List<ProductItem>>((
  ref,
) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) return const <ProductItem>[];
  return ref.watch(apiServiceProvider).getMyProducts(token);
});

final myShopOrderStatusProvider = StateProvider<String?>((ref) => null);
final myShopOrderPageProvider = StateProvider<int>((ref) => 1);

final myShopOrdersProvider = FutureProvider.autoDispose<PaginatedOrders>((
  ref,
) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) {
    return const PaginatedOrders(
      items: [],
      total: 0,
      page: 1,
      pageSize: 10,
      hasMore: false,
    );
  }
  return ref
      .watch(apiServiceProvider)
      .getShopOrders(
        token,
        status: ref.watch(myShopOrderStatusProvider),
        page: ref.watch(myShopOrderPageProvider),
      );
});

class ShopDashboardScreen extends ConsumerStatefulWidget {
  const ShopDashboardScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<ShopDashboardScreen> createState() =>
      _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends ConsumerState<ShopDashboardScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);
    final productsAsync = ref.watch(myProductsProvider);
    final ordersAsync = ref.watch(myShopOrdersProvider);
    final title = switch (_tabIndex) {
      1 => context.tr(ar: 'منتجاتي', en: 'My products'),
      2 => context.tr(ar: 'طلبات المتجر', en: 'Shop orders'),
      _ => context.tr(ar: 'حساب المتجر', en: 'Shop account'),
    };

    return HomixPage(
      title: title,
      header: AppBanner(
        title: context.tr(
          ar: 'لوحة متجر بمظهر أقوى',
          en: 'A stronger-looking store dashboard',
        ),
        message: context.tr(
          ar: 'التصميم الجديد يبرز المبيعات، الباقة، والطلبات بطريقة أوضح وأسهل في العرض على العميل.',
          en: 'The refreshed design presents sales, subscription, and orders with a cleaner premium layout.',
        ),
        icon: Icons.storefront_rounded,
        background: AppColors.secondarySoft,
        foreground: AppColors.secondary,
      ),
      actions: [
        IconButton(
          tooltip: context.tr(ar: 'تسجيل الخروج', en: 'Log out'),
          onPressed: () async {
            await ref.read(authControllerProvider).logout();
            if (!context.mounted) return;
            context.go(AppRoutes.login);
          },
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      bottomNavigationBar: _ShopBottomBar(
        currentIndex: _tabIndex,
        onChanged: (value) => setState(() => _tabIndex = value),
      ),
      child: shopAsync.when(
        data: (shop) => productsAsync.when(
          data: (products) => ordersAsync.when(
            data: (ordersPage) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myShopProvider);
                ref.invalidate(myProductsProvider);
                ref.invalidate(myShopOrdersProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_tabIndex == 0)
                    _Overview(
                      shop: shop,
                      products: products,
                      orders: ordersPage.items,
                    ),
                  if (_tabIndex == 1) _ProductsList(products: products),
                  if (_tabIndex == 2) _OrdersList(pageData: ordersPage),
                  if (_tabIndex == 3)
                    _Stats(products: products, orders: ordersPage.items),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncPlaceholder(message: error.toString()),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncPlaceholder(message: error.toString()),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncPlaceholder(message: error.toString()),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
      onPressed: busy ? null : onPressed,
      child: Text(
        busy ? context.tr(ar: 'جارٍ التنفيذ...', en: 'Processing...') : label,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                )
              : const LinearGradient(
                  colors: [AppColors.cardWhite, AppColors.backgroundTertiary],
                ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.products, required this.orders});

  final List<ProductItem> products;
  final List<StoreOrder> orders;

  @override
  Widget build(BuildContext context) {
    final completed = orders.where((item) => item.status == 'fulfilled').length;
    final revenue = orders
        .where(
          (item) => item.status == 'confirmed' || item.status == 'fulfilled',
        )
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
    final cancelled = orders.where((item) => item.status == 'cancelled').length;

    return Column(
      children: [
        SectionHeading(
          title: context.tr(ar: 'إحصائيات المتجر', en: 'Store stats'),
          subtitle: context.tr(
            ar: 'لقطة تشغيلية سريعة تساعدك تعرض أداء المتجر بثقة',
            en: 'A quick operational snapshot for presenting your store performance',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'المبيعات', en: 'Revenue'),
                value: revenue.toStringAsFixed(0),
                color: AppColors.accent,
                icon: Icons.payments_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'مكتمل', en: 'Fulfilled'),
                value: '$completed',
                color: AppColors.secondary,
                icon: Icons.check_circle_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'منتجات', en: 'Products'),
                value: '${products.length}',
                background: AppColors.primarySoft,
                valueColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'ملغي', en: 'Cancelled'),
                value: '$cancelled',
                background: AppColors.errorSoft,
                valueColor: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShopBottomBar extends StatelessWidget {
  const _ShopBottomBar({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.storefront_rounded, context.tr(ar: 'الرئيسية', en: 'Home')),
      (Icons.inventory_2_rounded, context.tr(ar: 'المنتجات', en: 'Products')),
      (Icons.receipt_long_rounded, context.tr(ar: 'الطلبات', en: 'Orders')),
      (Icons.bar_chart_rounded, context.tr(ar: 'إحصائيات', en: 'Stats')),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bottomBar, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final active = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [Colors.white, AppColors.accentSoft],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryDark
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        items[index].$1,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      items[index].$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.primaryDark : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

String _productStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'approved':
      return context.tr(ar: 'معتمد', en: 'Approved');
    case 'rejected':
      return context.tr(ar: 'مرفوض', en: 'Rejected');
    default:
      return context.tr(ar: 'معلق', en: 'Pending');
  }
}

Color _productStatusForeground(String status) {
  switch (status) {
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.error;
    default:
      return AppColors.accentDark;
  }
}

Color _productStatusBackground(String status) {
  switch (status) {
    case 'approved':
      return AppColors.successSoft;
    case 'rejected':
      return AppColors.errorSoft;
    default:
      return AppColors.accentSoft;
  }
}

String _orderStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'confirmed':
      return context.tr(ar: 'مؤكد', en: 'Confirmed');
    case 'fulfilled':
      return context.tr(ar: 'مكتمل', en: 'Fulfilled');
    case 'cancelled':
      return context.tr(ar: 'ملغي', en: 'Cancelled');
    default:
      return context.tr(ar: 'جديد', en: 'Pending');
  }
}

Color _orderStatusForeground(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.primary;
    case 'fulfilled':
      return AppColors.success;
    case 'cancelled':
      return AppColors.error;
    default:
      return AppColors.accentDark;
  }
}

Color _orderStatusBackground(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.primarySoft;
    case 'fulfilled':
      return AppColors.successSoft;
    case 'cancelled':
      return AppColors.errorSoft;
    default:
      return AppColors.accentSoft;
  }
}

String _shopStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'approved':
      return context.tr(ar: 'معتمد', en: 'Approved');
    case 'rejected':
      return context.tr(ar: 'مرفوض', en: 'Rejected');
    default:
      return context.tr(ar: 'قيد المراجعة', en: 'Pending');
  }
}

Color _shopStatusForeground(String status) {
  switch (status) {
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.error;
    default:
      return AppColors.accentDark;
  }
}

Color _shopStatusBackground(String status) {
  switch (status) {
    case 'approved':
      return AppColors.successSoft;
    case 'rejected':
      return AppColors.errorSoft;
    default:
      return AppColors.accentSoft;
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.shop,
    required this.products,
    required this.orders,
  });

  final ShopItem? shop;
  final List<ProductItem> products;
  final List<StoreOrder> orders;

  @override
  Widget build(BuildContext context) {
    final revenue = orders
        .where(
          (item) => item.status == 'confirmed' || item.status == 'fulfilled',
        )
        .fold<double>(0, (sum, item) => sum + item.totalPrice);
    final fulfilled = orders.where((item) => item.status == 'fulfilled').length;
    final pending = orders.where((item) => item.status == 'pending').length;

    return Column(
      children: [
        DashboardHero(
          title: shop?.name.isNotEmpty == true
              ? shop!.name
              : context.tr(ar: 'متجر Homix', en: 'Homix shop'),
          subtitle: shop?.city.isNotEmpty == true
              ? shop!.city
              : context.tr(ar: 'أضف مدينة المتجر', en: 'Add shop city'),
          chips: [
            HeroTagChip(
              label: context.tr(
                ar: 'منتجات ${products.length}',
                en: '${products.length} products',
              ),
            ),
            HeroTagChip(
              label: context.tr(
                ar: 'طلبات ${orders.length}',
                en: '${orders.length} orders',
              ),
            ),
            HeroTagChip(
              label: shop?.subscription.planName ?? 'Basic',
              highlight: true,
            ),
          ],
          trailing: Container(
            width: 108,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Text(
                  revenue.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  context.tr(ar: 'إجمالي المبيعات', en: 'Revenue'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'طلبات جاهزة', en: 'Fulfilled orders'),
                value: '$fulfilled',
                color: AppColors.secondary,
                icon: Icons.inventory_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: context.tr(ar: 'تنتظر المراجعة', en: 'Pending orders'),
                value: '$pending',
                color: AppColors.accent,
                icon: Icons.pending_actions_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeading(
          title: 'تشغيل سريع',
          subtitle: 'كل ما يحتاجه صاحب المتجر واضح ومباشر في هذه الواجهة',
        ),
        const SizedBox(height: 12),
        AppSectionCard(
          color: shop?.subscription.isPro == true
              ? AppColors.secondarySoft
              : AppColors.primarySoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr(
                        ar: 'الباقة الحالية: ${shop?.subscription.planName ?? 'Basic'}',
                        en: 'Current plan: ${shop?.subscription.planName ?? 'Basic'}',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  AppStatusBadge(
                    label: shop?.status.isNotEmpty == true
                        ? _shopStatusLabel(context, shop!.status)
                        : context.tr(ar: 'غير مكتمل', en: 'Incomplete'),
                    foreground: _shopStatusForeground(
                      shop?.status ?? 'pending',
                    ),
                    background: _shopStatusBackground(
                      shop?.status ?? 'pending',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  ar: 'العمولة ${shop?.subscription.commissionRate.toStringAsFixed(0) ?? '0'}% • ${shop?.subscription.verifiedBadge == true ? 'شارة موثقة' : 'بدون شارة'}',
                  en: 'Commission ${shop?.subscription.commissionRate.toStringAsFixed(0) ?? '0'}% • ${shop?.subscription.verifiedBadge == true ? 'verified badge' : 'no badge'}',
                ),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (shop?.description.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  shop!.description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.shopSubscription),
                      icon: const Icon(Icons.workspace_premium_rounded),
                      label: Text(
                        context.tr(ar: 'إدارة الباقة', en: 'Manage plan'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.addProduct),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        context.tr(ar: 'إضافة منتج', en: 'Add product'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'منتجات', en: 'Products'),
                value: '${products.length}',
                background: AppColors.accentSoft,
                valueColor: AppColors.accentDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'المبيعات', en: 'Sales'),
                value: context.tr(
                  ar: '${revenue.toStringAsFixed(0)} ج.م',
                  en: 'EGP ${revenue.toStringAsFixed(0)}',
                ),
                background: AppColors.primarySoft,
                valueColor: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductsList extends StatelessWidget {
  const _ProductsList({required this.products});

  final List<ProductItem> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return AsyncPlaceholder(
        message: context.tr(
          ar: 'لا توجد منتجات لهذا المتجر بعد.',
          en: 'No products for this shop yet.',
        ),
      );
    }
    return Column(
      children: [
        SectionHeading(
          title: context.tr(ar: 'قائمة المنتجات', en: 'Product catalog'),
          subtitle: context.tr(
            ar: '${products.length} منتج داخل واجهة أوضح وأسهل للمراجعة',
            en: '${products.length} products in a clearer layout',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'إجمالي المنتجات', en: 'Total products'),
                value: '${products.length}',
                background: AppColors.primarySoft,
                valueColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricPill(
                label: context.tr(
                  ar: 'بانتظار القرار',
                  en: 'Awaiting decision',
                ),
                value:
                    '${products.where((item) => item.status == 'pending').length}',
                background: AppColors.accentSoft,
                valueColor: AppColors.accentDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...products.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProductCatalogCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _ProductCatalogCard extends StatelessWidget {
  const _ProductCatalogCard({required this.item});

  final ProductItem item;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentSoft, AppColors.primarySoft],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppStatusBadge(
                          label: _productStatusLabel(context, item.status),
                          foreground: _productStatusForeground(item.status),
                          background: _productStatusBackground(item.status),
                        ),
                        if (item.category.isNotEmpty)
                          AppStatusBadge(
                            label: item.category,
                            foreground: AppColors.primaryDark,
                            background: AppColors.primarySoft,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'السعر', en: 'Price'),
                  value: '${item.price.toStringAsFixed(0)} ${item.currency}',
                  background: AppColors.primarySoft,
                  valueColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricPill(
                  label: context.tr(ar: 'الحجم', en: 'Volume'),
                  value:
                      '${item.volumeLiters.toStringAsFixed(1)} ${context.tr(ar: 'لتر', en: 'L')}',
                  background: AppColors.secondarySoft,
                  valueColor: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({required this.pageData});

  final PaginatedOrders pageData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pageData.items.isEmpty) {
      return AsyncPlaceholder(
        message: context.tr(
          ar: 'لا توجد طلبات لهذا المتجر حتى الآن.',
          en: 'No orders for this shop yet.',
        ),
      );
    }

    return Column(
      children: [
        SectionHeading(
          title: context.tr(ar: 'طلبات المتجر', en: 'Store orders'),
          subtitle: context.tr(
            ar: 'فلترة أوضح ومتابعة أسرع لحالة كل طلب',
            en: 'Clearer filters and faster order tracking',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              label: context.tr(ar: 'الكل', en: 'All'),
              selected: ref.watch(myShopOrderStatusProvider) == null,
              onTap: () {
                ref.read(myShopOrderStatusProvider.notifier).state = null;
                ref.read(myShopOrderPageProvider.notifier).state = 1;
              },
            ),
            for (final status in const [
              'pending',
              'confirmed',
              'fulfilled',
              'cancelled',
            ])
              _StatusChip(
                label: _orderStatusLabel(context, status),
                selected: ref.watch(myShopOrderStatusProvider) == status,
                onTap: () {
                  ref.read(myShopOrderStatusProvider.notifier).state = status;
                  ref.read(myShopOrderPageProvider.notifier).state = 1;
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'في الصفحة', en: 'On page'),
                value: '${pageData.items.length}',
                background: AppColors.primarySoft,
                valueColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricPill(
                label: context.tr(ar: 'إجمالي الطلبات', en: 'Total orders'),
                value: '${pageData.total}',
                background: AppColors.accentSoft,
                valueColor: AppColors.accentDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...pageData.items.map(
          (order) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrderCard(order: order),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: pageData.page > 1
                    ? () => ref.read(myShopOrderPageProvider.notifier).state =
                          pageData.page - 1
                    : null,
                child: Text(context.tr(ar: 'السابق', en: 'Previous')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: pageData.hasMore
                    ? () => ref.read(myShopOrderPageProvider.notifier).state =
                          pageData.page + 1
                    : null,
                child: Text(context.tr(ar: 'التالي', en: 'Next')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order});

  final StoreOrder order;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final shortId = widget.order.id.substring(
      0,
      widget.order.id.length > 8 ? 8 : widget.order.id.length,
    );

    return AppSectionCard(
      child: InkWell(
        onTap: () => context.push('/orders/${widget.order.id}'),
        borderRadius: BorderRadius.circular(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(ar: 'طلب #$shortId', en: 'Order #$shortId'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AppStatusBadge(
                  label: _orderStatusLabel(context, widget.order.status),
                  foreground: _orderStatusForeground(widget.order.status),
                  background: _orderStatusBackground(widget.order.status),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.order.customerName} • ${widget.order.customerEmail}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'الإجمالي', en: 'Total'),
                    value:
                        '${widget.order.totalPrice.toStringAsFixed(0)} ${widget.order.currency}',
                    background: AppColors.primarySoft,
                    valueColor: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricPill(
                    label: context.tr(ar: 'العناصر', en: 'Items'),
                    value: '${widget.order.items.length}',
                    background: AppColors.accentSoft,
                    valueColor: AppColors.accentDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(
                ar: 'آخر خطوة: ${widget.order.timeline.isEmpty ? 'غير متاحة' : widget.order.timeline.last.label}',
                en: 'Latest step: ${widget.order.timeline.isEmpty ? 'Unavailable' : widget.order.timeline.last.label}',
              ),
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.order.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.order.notes,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.order.status == 'pending')
                  _ActionButton(
                    label: context.tr(ar: 'تأكيد', en: 'Confirm'),
                    busy: _busy,
                    onPressed: () => _update('confirm'),
                  ),
                if (widget.order.status == 'pending' ||
                    widget.order.status == 'confirmed')
                  _ActionButton(
                    label: context.tr(ar: 'تجهيز', en: 'Fulfill'),
                    busy: _busy,
                    onPressed: () => _update('fulfill'),
                  ),
                if (widget.order.status != 'fulfilled' &&
                    widget.order.status != 'cancelled')
                  _ActionButton(
                    label: context.tr(ar: 'إلغاء', en: 'Cancel'),
                    busy: _busy,
                    onPressed: () => _update('cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _update(String action) async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiServiceProvider)
          .updateOrderStatus(
            token: token,
            orderId: widget.order.id,
            action: action,
          );
      ref.invalidate(myShopOrdersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(ar: 'تم تحديث حالة الطلب', en: 'Order status updated'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
