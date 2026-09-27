import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../models/product_item.dart';
import '../../models/store_order.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';

final productsProvider = FutureProvider.autoDispose<List<ProductItem>>((
  ref,
) async {
  return ref.watch(apiServiceProvider).getProducts();
});

final myStoreOrdersProvider = FutureProvider.autoDispose<PaginatedOrders>((
  ref,
) async {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) {
    return const PaginatedOrders(
      items: [],
      total: 0,
      page: 1,
      pageSize: 3,
      hasMore: false,
    );
  }
  return ref.watch(apiServiceProvider).getMyOrders(token, pageSize: 3);
});

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final Map<String, int> _cart = <String, int>{};
  bool _submittingOrder = false;

  int get _cartItemsCount => _cart.values.fold<int>(0, (sum, qty) => sum + qty);

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final myOrders = ref.watch(myStoreOrdersProvider);

    return products.when(
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(productsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            DashboardHero(
              title: context.tr(
                ar: 'المتجر الآن أوضح وأقرب لقرار شراء أسرع',
                en: 'The shop is now clearer and closer to faster buying decisions',
              ),
              subtitle: context.tr(ar: 'متجر Homix', en: 'Homix shop'),
              chips: [
                HeroTagChip(
                  label: context.tr(
                    ar: '${items.length} منتجات',
                    en: '${items.length} products',
                  ),
                ),
                HeroTagChip(
                  label: context.tr(
                    ar: 'سلة $_cartItemsCount',
                    en: 'Cart $_cartItemsCount',
                  ),
                  highlight: true,
                ),
              ],
              searchHint: context.tr(
                ar: 'أضف المنتجات إلى السلة وراجع أحدث طلباتك من نفس الشاشة',
                en: 'Add products to cart and review your latest orders from the same screen',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: context.tr(ar: 'المنتجات', en: 'Products'),
                    value: '${items.length}',
                    color: AppColors.primary,
                    icon: Icons.storefront_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    label: context.tr(ar: 'السلة الحالية', en: 'Current cart'),
                    value: '$_cartItemsCount',
                    color: AppColors.accent,
                    icon: Icons.shopping_bag_rounded,
                  ),
                ),
              ],
            ),
            if (_cart.isNotEmpty) ...[
              const SizedBox(height: 16),
              _CartSummaryCard(
                itemsCount: _cartItemsCount,
                totalPrice: _cartTotal(items),
                submitting: _submittingOrder,
                onSubmit: _submitOrder,
              ),
            ],
            const SizedBox(height: 18),
            SectionHeading(
              title: context.tr(ar: 'منتجات مختارة', en: 'Selected products'),
              subtitle: context.tr(
                ar: 'بطاقات أوضح للمقارنة السريعة والإضافة المباشرة للسلة.',
                en: 'Clearer product cards for faster comparison and direct cart actions.',
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              AsyncPlaceholder(
                message: context.tr(
                  ar: 'لا توجد منتجات معتمدة حاليًا.',
                  en: 'There are no approved products right now.',
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.74,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _StoreTile(
                    item: item,
                    quantity: _cart[item.id] ?? 0,
                    onAdd: () => _increment(item.id),
                    onRemove: () => _decrement(item.id),
                  );
                },
              ),
            const SizedBox(height: 18),
            SectionHeading(
              title: context.tr(ar: 'أحدث الطلبات', en: 'Latest orders'),
              subtitle: context.tr(
                ar: 'تابع ما أنشأته مؤخرًا ثم انتقل إلى التفاصيل الكاملة بسهولة.',
                en: 'Review recent orders and open full details easily.',
              ),
            ),
            const SizedBox(height: 12),
            myOrders.when(
              data: (pageData) {
                if (pageData.items.isEmpty) {
                  return AsyncPlaceholder(
                    message: context.tr(
                      ar: 'لا توجد طلبات متجر حتى الآن.',
                      en: 'There are no shop orders yet.',
                    ),
                    icon: Icons.shopping_bag_outlined,
                  );
                }
                return Column(
                  children: pageData.items
                      .map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OrderTile(order: order),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AsyncPlaceholder(message: error.toString()),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AsyncPlaceholder(message: error.toString()),
    );
  }

  void _increment(String productId) {
    setState(() => _cart[productId] = (_cart[productId] ?? 0) + 1);
  }

  void _decrement(String productId) {
    setState(() {
      final current = _cart[productId] ?? 0;
      if (current <= 1) {
        _cart.remove(productId);
      } else {
        _cart[productId] = current - 1;
      }
    });
  }

  double _cartTotal(List<ProductItem> items) {
    final byId = {for (final item in items) item.id: item};
    double total = 0;
    for (final entry in _cart.entries) {
      total += (byId[entry.key]?.price ?? 0) * entry.value;
    }
    return total;
  }

  Future<void> _submitOrder() async {
    final token = ref.read(authControllerProvider).token;
    if (token == null || _cart.isEmpty || _submittingOrder) return;

    setState(() => _submittingOrder = true);
    try {
      final order = await ref
          .read(apiServiceProvider)
          .createOrder(
            token: token,
            items: _cart.entries
                .map(
                  (entry) => {'product_id': entry.key, 'quantity': entry.value},
                )
                .toList(),
          );
      ref.invalidate(myStoreOrdersProvider);
      if (!mounted) return;
      setState(() => _cart.clear());
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr(ar: 'تم إنشاء الطلب', en: 'Order created')),
          content: Text(
            context.tr(
              ar: 'رقم الطلب: ${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
              en: 'Order number: ${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr(ar: 'إغلاق', en: 'Close')),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submittingOrder = false);
    }
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final ProductItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 86,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentSoft, AppColors.primarySoft],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.format_color_fill_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          AppStatusBadge(
            label: item.category,
            foreground: AppColors.accentDark,
            background: AppColors.accentSoft,
          ),
          const SizedBox(height: 8),
          Text(
            item.description.isEmpty ? item.category : item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${item.price.toStringAsFixed(0)} ${item.currency}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.volumeLiters.toStringAsFixed(1)} ${context.tr(ar: 'لتر', en: 'L')}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (quantity == 0)
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text(context.tr(ar: 'إضافة', en: 'Add')),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({
    required this.itemsCount,
    required this.totalPrice,
    required this.submitting,
    required this.onSubmit,
  });

  final int itemsCount;
  final double totalPrice;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      color: AppColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(
                    ar: '$itemsCount منتجات داخل السلة',
                    en: '$itemsCount products in cart',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AppStatusBadge(
                label: context.tr(ar: 'جاهز للطلب', en: 'Ready'),
                foreground: AppColors.primary,
                background: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              ar: 'راجع قيمة السلة الحالية ثم أنشئ الطلب مباشرة من نفس الشاشة.',
              en: 'Review the current cart total and place the order from this screen.',
            ),
            style: const TextStyle(
              color: AppColors.textMuted,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${totalPrice.toStringAsFixed(0)} ${context.tr(ar: 'ج.م', en: 'EGP')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                child: Text(
                  submitting
                      ? context.tr(ar: 'جارٍ الإرسال...', en: 'Submitting...')
                      : context.tr(ar: 'تأكيد الطلب', en: 'Place order'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final latestStep = order.timeline.isEmpty
        ? context.tr(ar: 'غير متاحة', en: 'Unavailable')
        : order.timeline.last.label;

    return AppSectionCard(
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(
                      ar: 'طلب #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                      en: 'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                AppStatusBadge(
                  label: _orderStatusLabel(context, order.status),
                  foreground: _orderStatusForeground(order.status),
                  background: _orderStatusBackground(order.status),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.tr(
                ar: 'آخر خطوة: $latestStep',
                en: 'Latest step: $latestStep',
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${order.totalPrice.toStringAsFixed(0)} ${order.currency}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
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
