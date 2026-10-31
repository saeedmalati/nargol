import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'checkout.dart';
import 'shell.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final s = state.catalog!.settings;
    final subtotal = state.cartSubtotal;
    final belowMin = s.minOrder > 0 && subtotal < s.minOrder;

    return Scaffold(
      appBar: AppBar(title: const Text('سبد خرید')),
      body: state.cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'سبد خرید شما خالی است',
              subtitle: 'محصولات خانگی نارگل منتظر شما هستند',
              action: FilledButton(onPressed: () => Shell.goTo(context, 0), child: const Text('مشاهده محصولات')),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final item in List.of(state.cart))
                  Builder(
                    builder: (context) {
                      final p = state.product(item.productId)!;
                      final v = state.variantOf(item)!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(width: 76, height: 76, child: ProductImage(p.image)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(v.label, style: const TextStyle(color: NColors.muted, fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              toman(v.price * item.qty),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: NColors.oliveDark,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          QtyStepper(compact: true, qty: item.qty, onChanged: (q) => state.setQty(item, q)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _row('جمع سبد خرید', toman(subtotal), bold: true),
                        if (s.deliveryEnabled && s.freeDeliveryOver > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtotal >= s.freeDeliveryOver
                                ? 'ارسال این سفارش رایگان است 🎉'
                                : 'با ${toman(s.freeDeliveryOver - subtotal)} خرید بیشتر، ارسال رایگان می‌شود',
                            style: const TextStyle(color: NColors.success, fontSize: 13),
                          ),
                        ],
                        if (belowMin) ...[
                          const SizedBox(height: 8),
                          Text(
                            'حداقل مبلغ سفارش ${toman(s.minOrder)} است.',
                            style: const TextStyle(color: NColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: state.cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: FilledButton(
                  onPressed: belowMin
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                  child: const Text('ادامه و تکمیل خرید'),
                ),
              ),
            ),
    );
  }

  static Widget _row(String a, String b, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(a, style: TextStyle(color: color ?? NColors.muted)),
        ),
        Text(
          b,
          style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? NColors.text),
        ),
      ],
    ),
  );
}
