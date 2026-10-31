import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../state.dart';
import '../theme.dart';
import 'about.dart';
import 'cart.dart';
import 'home.dart';
import 'orders.dart';

/// قاب اصلی اپ با نوار پایین
class Shell extends StatefulWidget {
  Shell() : super(key: _key);
  static final _key = GlobalKey<_ShellState>();
  static void goTo(BuildContext context, int tab) => _key.currentState?.setTab(tab);
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  final ordersKey = GlobalKey<OrdersScreenState>();

  void setTab(int t) {
    setState(() => tab = t);
    if (t == 2) ordersKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    if (state.loading && state.catalog == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo.png', width: 180),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: NColors.orange),
            ],
          ),
        ),
      );
    }
    if (state.catalog == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', width: 140),
                const SizedBox(height: 20),
                Text(state.loadError ?? 'خطا', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: state.reload, child: const Text('تلاش دوباره')),
              ],
            ),
          ),
        ),
      );
    }
    final cartCount = state.cartCount;
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          const HomeScreen(),
          const CartScreen(),
          OrdersScreen(key: ordersKey),
          const AboutScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: setTab,
        backgroundColor: Colors.white,
        indicatorColor: NColors.orange.withValues(alpha: 0.18),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'فروشگاه',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              backgroundColor: NColors.orange,
              label: Text(faDigits(cartCount)),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              backgroundColor: NColors.orange,
              label: Text(faDigits(cartCount)),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'سبد خرید',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'سفارش‌ها',
          ),
          const NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'درباره ما'),
        ],
      ),
    );
  }
}
