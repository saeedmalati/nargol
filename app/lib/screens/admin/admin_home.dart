import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_orders.dart';
import 'admin_products.dart';
import 'admin_settings.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل مدیریت نارگل'),
          actions: [
            IconButton(
              tooltip: 'خروج',
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<ShopState>().adminLogout();
                Navigator.of(context).pop();
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: NColors.olive,
            indicatorColor: NColors.orange,
            labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'محصولات'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'سفارش‌ها'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'تنظیمات'),
            ],
          ),
        ),
        body: const Column(
          children: [
            DemoBanner(),
            Expanded(child: TabBarView(children: [AdminProducts(), AdminOrders(), AdminSettings()])),
          ],
        ),
      ),
    );
  }
}
