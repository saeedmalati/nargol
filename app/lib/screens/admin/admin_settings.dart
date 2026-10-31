import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../format.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});
  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  late ShopSettings s;
  late final Map<String, TextEditingController> t;
  late List<List<TextEditingController>> branches;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    s = ShopSettings.fromJson(context.read<ShopState>().catalog!.settings.toJson());
    t = {
      'shopName': TextEditingController(text: s.shopName),
      'slogan': TextEditingController(text: s.slogan),
      'deliveryFee': TextEditingController(text: '${s.deliveryFee}'),
      'freeDeliveryOver': TextEditingController(text: '${s.freeDeliveryOver}'),
      'minOrder': TextEditingController(text: '${s.minOrder}'),
      'healthCertificate': TextEditingController(text: s.healthCertificate),
      'healthCard': TextEditingController(text: s.healthCard),
    };
    branches = [
      for (final b in s.branches)
        [TextEditingController(text: b.name), TextEditingController(text: b.address), TextEditingController(text: b.phone)],
    ];
  }

  int _num(String k) => int.tryParse(enDigits(t[k]!.text.trim())) ?? 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        const SectionTitle('فروشگاه'),
        _field('shopName', 'نام فروشگاه'),
        _field('slogan', 'شعار'),
        const SectionTitle('ارسال و سفارش'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('ارسال با پیک'),
          value: s.deliveryEnabled,
          activeTrackColor: NColors.olive,
          onChanged: (v) => setState(() => s.deliveryEnabled = v || !s.pickupEnabled),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('تحویل حضوری در شعبه'),
          value: s.pickupEnabled,
          activeTrackColor: NColors.olive,
          onChanged: (v) => setState(() => s.pickupEnabled = v || !s.deliveryEnabled),
        ),
        _field('deliveryFee', 'هزینه ارسال (تومان)', number: true),
        _field('freeDeliveryOver', 'ارسال رایگان برای خرید بالای (تومان) — ۰ یعنی هیچ‌وقت', number: true),
        _field('minOrder', 'حداقل مبلغ سفارش (تومان) — ۰ یعنی بدون حداقل', number: true),
        const SectionTitle('مجوزها'),
        _field('healthCertificate', 'شماره گواهینامه بهداشت'),
        _field('healthCard', 'شماره کارت بهداشت'),
        SectionTitle(
          'شعبه‌ها',
          trailing: TextButton.icon(
            onPressed: () =>
                setState(() => branches.add([TextEditingController(), TextEditingController(), TextEditingController()])),
            icon: const Icon(Icons.add),
            label: const Text('شعبه جدید'),
          ),
        ),
        for (var i = 0; i < branches.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: branches[i][0],
                            decoration: const InputDecoration(labelText: 'نام شعبه', isDense: true),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => branches.removeAt(i)),
                          icon: const Icon(Icons.delete_outline, color: NColors.danger),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: branches[i][1],
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'آدرس', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: branches[i][2],
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'تلفن', isDense: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: busy ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: NColors.olive),
          child: Text(busy ? 'در حال ذخیره…' : 'ذخیره تنظیمات'),
        ),
        const SectionTitle('دسته‌بندی‌ها'),
        const CategoriesEditor(),
        const SectionTitle('امنیت'),
        OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.key), label: const Text('تغییر رمز مدیریت')),
      ],
    );
  }

  Widget _field(String k, String label, {bool number = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: t[k],
      keyboardType: number ? TextInputType.number : null,
      inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹]'))] : null,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Future<void> _save() async {
    s
      ..shopName = t['shopName']!.text.trim()
      ..slogan = t['slogan']!.text.trim()
      ..deliveryFee = _num('deliveryFee')
      ..freeDeliveryOver = _num('freeDeliveryOver')
      ..minOrder = _num('minOrder')
      ..healthCertificate = t['healthCertificate']!.text.trim()
      ..healthCard = t['healthCard']!.text.trim()
      ..branches = [
        for (final b in branches)
          if (b[0].text.trim().isNotEmpty)
            Branch(name: b[0].text.trim(), address: b[1].text.trim(), phone: enDigits(b[2].text.trim())),
      ];
    setState(() => busy = true);
    try {
      await context.read<ShopState>().saveSettings(s);
      if (mounted) showMsg(context, 'تنظیمات ذخیره شد');
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _changePassword() async {
    final ctrl = TextEditingController();
    final pass = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('رمز جدید'),
        content: TextField(
          controller: ctrl,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: 'حداقل ۴ حرف'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, enDigits(ctrl.text.trim())), child: const Text('ذخیره')),
        ],
      ),
    );
    if (pass == null || !mounted) return;
    if (pass.length < 4) return showMsg(context, 'رمز باید حداقل ۴ حرف باشد', error: true);
    try {
      await context.read<ShopState>().repo.changePassword(pass);
      if (mounted) showMsg(context, 'رمز تغییر کرد');
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }
}

/// ویرایش نام، ترتیب و افزودن/حذف دسته‌بندی‌ها
class CategoriesEditor extends StatelessWidget {
  const CategoriesEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final cats = state.catalog!.categories;
    Future<void> save(List<Category> list) async {
      for (var i = 0; i < list.length; i++) {
        list[i].sort = i;
      }
      try {
        await state.saveCategories(list);
      } catch (e) {
        if (context.mounted) showMsg(context, e.toString(), error: true);
      }
    }

    Future<String?> ask(String title, [String initial = '']) {
      final ctrl = TextEditingController(text: initial);
      return showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: TextField(controller: ctrl, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('ذخیره')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Card(
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (a, b) {
              final list = List.of(cats);
              list.insert(b, list.removeAt(a));
              save(list);
            },
            children: [
              for (var i = 0; i < cats.length; i++)
                ListTile(
                  key: ValueKey(cats[i].id),
                  leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                  title: Text(cats[i].name),
                  subtitle: Text(
                    '${faDigits(state.catalog!.products.where((p) => p.categoryId == cats[i].id).length)} محصول',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () async {
                          final n = await ask('نام دسته', cats[i].name);
                          if (n != null && n.isNotEmpty) {
                            final list = List.of(cats);
                            list[i] = Category(id: cats[i].id, name: n, sort: i);
                            save(list);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          if (state.catalog!.products.any((p) => p.categoryId == cats[i].id)) {
                            showMsg(context, 'اول محصولات این دسته را به دسته دیگری منتقل کنید', error: true);
                            return;
                          }
                          save(List.of(cats)..removeAt(i));
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final n = await ask('دسته جدید');
            if (n != null && n.isNotEmpty) {
              save([...cats, Category(id: 'c${DateTime.now().millisecondsSinceEpoch}', name: n)]);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('افزودن دسته'),
        ),
      ],
    );
  }
}
