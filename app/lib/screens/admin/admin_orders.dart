import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../format.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../orders.dart';

class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});
  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders> {
  Future<List<Order>>? future;
  String filter = 'active';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => future = context.read<ShopState>().repo.adminOrders());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final f in const {
                'active': 'در جریان',
                'pending_payment': 'پرداخت‌نشده',
                'done': 'تحویل‌شده',
                'all': 'همه',
              }.entries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(f.value),
                    selected: filter == f.key,
                    showCheckmark: false,
                    selectedColor: NColors.olive,
                    labelStyle: TextStyle(fontFamily: 'Vazirmatn', color: filter == f.key ? Colors.white : NColors.text),
                    onSelected: (_) => setState(() => filter = f.key),
                  ),
                ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Order>>(
            future: future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return EmptyState(icon: Icons.error_outline, title: snap.error.toString());
              final list = snap.data!.where((o) {
                return switch (filter) {
                  'active' => const ['paid', 'preparing', 'sending', 'ready'].contains(o.status),
                  'all' => true,
                  _ => o.status == filter,
                };
              }).toList();
              if (list.isEmpty) return const EmptyState(icon: Icons.inbox_outlined, title: 'سفارشی در این بخش نیست');
              return RefreshIndicator(
                onRefresh: () async => _load(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => OrderCard(order: list[i], adminActions: _actions(list[i])),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actions(Order o) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: o.status,
            isDense: true,
            decoration: const InputDecoration(labelText: 'تغییر وضعیت', isDense: true),
            items: [for (final e in orderStatuses.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) async {
              if (v == null) return;
              try {
                await context.read<ShopState>().repo.setOrderStatus(o.id, v);
                if (mounted) {
                  showMsg(context, 'وضعیت سفارش ${faDigits(o.id)} تغییر کرد');
                  _load();
                }
              } catch (e) {
                if (mounted) showMsg(context, e.toString(), error: true);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(onPressed: () => launchUrl(Uri.parse('tel:${o.phone}')), icon: const Icon(Icons.call)),
      ],
    );
  }
}
