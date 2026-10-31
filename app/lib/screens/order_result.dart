import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'shell.dart';

/// نتیجه پرداخت. در حالت سرور، پس از بازگشت از درگاه، وضعیت را دوباره می‌پرسد.
class OrderResultScreen extends StatefulWidget {
  final Order order;
  final bool waiting;
  const OrderResultScreen({super.key, required this.order, this.waiting = false});
  @override
  State<OrderResultScreen> createState() => _OrderResultScreenState();
}

class _OrderResultScreenState extends State<OrderResultScreen> with WidgetsBindingObserver {
  late Order order = widget.order;
  bool checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && order.status == 'pending_payment') _check();
  }

  Future<void> _check() async {
    setState(() => checking = true);
    try {
      final list = await context.read<ShopState>().repo.myOrders([order.token]);
      if (list.isNotEmpty && mounted) setState(() => order = list.first);
    } catch (_) {}
    if (mounted) setState(() => checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final paid = order.status != 'pending_payment' && order.status != 'canceled';
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('نتیجه سفارش')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(paid ? Icons.check_circle : Icons.hourglass_top, size: 84, color: paid ? NColors.success : NColors.orange),
              const SizedBox(height: 16),
              Text(
                paid ? 'سفارش شما با موفقیت ثبت شد' : 'در انتظار پرداخت',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                paid
                    ? 'از خرید شما متشکریم. سفارش شما به‌زودی آماده می‌شود.'
                    : 'اگر پرداخت را انجام داده‌اید، دکمه «بررسی وضعیت» را بزنید.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: NColors.muted, height: 1.7),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('شماره سفارش', faDigits(order.id)),
                      _row('مبلغ', toman(order.total)),
                      if (order.refId != null) _row('کد پیگیری پرداخت', faDigits(order.refId!)),
                      _row('وضعیت', order.statusText),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!paid) ...[
                OutlinedButton.icon(
                  onPressed: checking ? null : _check,
                  icon: const Icon(Icons.refresh),
                  label: const Text('بررسی وضعیت پرداخت'),
                ),
                if (order.paymentUrl != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(order.paymentUrl!), mode: LaunchMode.externalApplication),
                    child: const Text('رفتن دوباره به درگاه پرداخت'),
                  ),
                ],
                const SizedBox(height: 10),
              ],
              FilledButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  Shell.goTo(context, 2);
                },
                child: const Text('مشاهده سفارش‌های من'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(a, style: const TextStyle(color: NColors.muted)),
        ),
        Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
