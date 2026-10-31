import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'order_result.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: context.read<ShopState>().savedCustomer['name']);
  late final phone = TextEditingController(text: context.read<ShopState>().savedCustomer['phone']);
  late final address = TextEditingController(text: context.read<ShopState>().savedCustomer['address']);
  final note = TextEditingController();
  String method = 'delivery';
  int branch = 0;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<ShopState>().catalog!.settings;
    if (!s.deliveryEnabled) method = 'pickup';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final s = state.catalog!.settings;
    final subtotal = state.cartSubtotal;
    final fee = method == 'delivery' ? s.deliveryCostFor(subtotal) : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('تکمیل خرید')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (s.deliveryEnabled && s.pickupEnabled) ...[
              const SectionTitle('نحوه دریافت'),
              SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: NColors.olive,
                  selectedForegroundColor: Colors.white,
                  textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w600),
                ),
                segments: const [
                  ButtonSegment(value: 'delivery', icon: Icon(Icons.delivery_dining), label: Text('ارسال با پیک')),
                  ButtonSegment(value: 'pickup', icon: Icon(Icons.store), label: Text('تحویل در شعبه')),
                ],
                selected: {method},
                onSelectionChanged: (v) => setState(() => method = v.first),
              ),
            ],
            if (method == 'pickup') ...[
              const SectionTitle('انتخاب شعبه'),
              RadioGroup<int>(
                groupValue: branch,
                onChanged: (v) => setState(() => branch = v!),
                child: Column(
                  children: [
                    for (var i = 0; i < s.branches.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: RadioListTile<int>(
                            value: i,
                            activeColor: NColors.olive,
                            title: Text(s.branches[i].name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(s.branches[i].address, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SectionTitle('مشخصات شما'),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v ?? '').trim().length < 3 ? 'نام را وارد کنید' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'شماره موبایل',
                hintText: '09xxxxxxxxx',
                prefixIcon: Icon(Icons.phone_iphone),
              ),
              validator: (v) => RegExp(r'^09\d{9}$').hasMatch(enDigits((v ?? '').trim())) ? null : 'شماره موبایل معتبر نیست',
            ),
            if (method == 'delivery') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: address,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'آدرس کامل',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v ?? '').trim().length < 10 ? 'آدرس کامل را وارد کنید' : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)', prefixIcon: Icon(Icons.edit_note)),
            ),
            const SectionTitle('خلاصه سفارش'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final i in state.cart)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${state.product(i.productId)!.name} (${state.variantOf(i)!.label}) × ${faDigits(i.qty)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(toman(state.variantOf(i)!.price * i.qty), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    const Divider(height: 20),
                    _row('جمع کالاها', toman(subtotal)),
                    if (method == 'delivery') _row('هزینه ارسال', fee == 0 ? 'رایگان' : toman(fee)),
                    const SizedBox(height: 4),
                    _row('مبلغ قابل پرداخت', toman(subtotal + fee), bold: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: FilledButton.icon(
            onPressed: busy ? null : () => _submit(subtotal + fee),
            icon: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_outline),
            label: Text('پرداخت آنلاین  •  ${toman(subtotal + fee)}'),
          ),
        ),
      ),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            a,
            style: TextStyle(color: bold ? NColors.text : NColors.muted, fontWeight: bold ? FontWeight.w700 : null),
          ),
        ),
        Text(
          b,
          style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? NColors.oliveDark : null),
        ),
      ],
    ),
  );

  Future<void> _submit(int total) async {
    if (!formKey.currentState!.validate()) return;
    final state = context.read<ShopState>();
    setState(() => busy = true);
    try {
      final order = await state.placeOrder(
        CheckoutInfo(
          name: name.text.trim(),
          phone: enDigits(phone.text.trim()),
          address: method == 'delivery' ? address.text.trim() : '',
          note: note.text.trim(),
          method: method,
          branchIndex: method == 'pickup' ? branch : null,
        ),
      );
      if (!mounted) return;
      if (isDemo) {
        await _demoPayment(order);
      } else if (order.paymentUrl != null) {
        await launchUrl(Uri.parse(order.paymentUrl!), mode: LaunchMode.externalApplication);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderResultScreen(order: order, waiting: true)));
      }
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// شبیه‌سازی درگاه پرداخت در حالت نمایشی
  Future<void> _demoPayment(Order order) async {
    final state = context.read<ShopState>();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('درگاه پرداخت (آزمایشی)'),
        content: Text('این یک پرداخت آزمایشی است و پولی کسر نمی‌شود.\n\nمبلغ: ${toman(order.total)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('پرداخت موفق')),
        ],
      ),
    );
    if (!mounted) return;
    final result = ok == true ? await state.repo.demoPay(order.id) : order;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderResultScreen(order: result)));
  }
}
