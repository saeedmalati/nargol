import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen> {
  Future<List<Order>>? future;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() => setState(() => future = context.read<ShopState>().myOrders());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سفارش‌های من'),
        actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<Order>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: NColors.orange));
          }
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.wifi_off,
              title: snap.error.toString(),
              action: OutlinedButton(onPressed: refresh, child: const Text('تلاش دوباره')),
            );
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: 'هنوز سفارشی ثبت نکرده‌اید');
          }
          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => OrderCard(order: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final Widget? adminActions;
  const OrderCard({super.key, required this.order, this.adminActions});

  @override
  Widget build(BuildContext context) {
    final o = order;
    final branches = context.read<ShopState>().catalog?.settings.branches ?? [];
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(
            children: [
              Text('سفارش ${faDigits(o.id)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              StatusChip(o.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${faDate(o.createdAt.toLocal())}  •  ${toman(o.total)}',
              style: const TextStyle(fontSize: 12, color: NColors.muted),
            ),
          ),
          children: [
            if (adminActions != null) ...[
              Text('${o.customerName}  •  ${faDigits(o.phone)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
            ],
            Text(
              o.method == 'pickup'
                  ? 'تحویل در شعبه: ${o.branchIndex != null && o.branchIndex! < branches.length ? branches[o.branchIndex!].name : '-'}'
                  : 'ارسال به: ${o.address}',
              style: const TextStyle(fontSize: 13, color: NColors.muted, height: 1.6),
            ),
            if (o.note.isNotEmpty) Text('توضیحات: ${o.note}', style: const TextStyle(fontSize: 13, color: NColors.muted)),
            const Divider(height: 20),
            for (final l in o.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text('${l.name} (${l.label}) × ${faDigits(l.qty)}', style: const TextStyle(fontSize: 13))),
                    Text(toman(l.price * l.qty), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            if (o.deliveryFee > 0)
              Row(
                children: [
                  const Expanded(
                    child: Text('هزینه ارسال', style: TextStyle(fontSize: 13, color: NColors.muted)),
                  ),
                  Text(toman(o.deliveryFee), style: const TextStyle(fontSize: 13)),
                ],
              ),
            if (o.refId != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'کد پیگیری پرداخت: ${faDigits(o.refId!)}',
                  style: const TextStyle(fontSize: 12, color: NColors.muted),
                ),
              ),
            if (adminActions == null && o.status == 'pending_payment' && o.paymentUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FilledButton(
                  onPressed: () => launchUrl(Uri.parse(o.paymentUrl!), mode: LaunchMode.externalApplication),
                  child: const Text('پرداخت این سفارش'),
                ),
              ),
            if (adminActions != null) ...[const SizedBox(height: 10), adminActions!],
          ],
        ),
      ),
    );
  }
}
