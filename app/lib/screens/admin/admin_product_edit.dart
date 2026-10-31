import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../format.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// ویرایش یا ساخت محصول: عکس، نام، دسته، توضیح و گزینه‌های وزن/قیمت
class AdminProductEdit extends StatefulWidget {
  final Product? product;
  const AdminProductEdit({super.key, this.product});
  @override
  State<AdminProductEdit> createState() => _AdminProductEditState();
}

class _VariantCtrl {
  final String id;
  final TextEditingController label, price;
  bool available;
  _VariantCtrl(Variant v)
    : id = v.id,
      label = TextEditingController(text: v.label),
      price = TextEditingController(text: v.price.toString()),
      available = v.available;
}

class _AdminProductEditState extends State<AdminProductEdit> {
  final formKey = GlobalKey<FormState>();
  late final Product p;
  late final TextEditingController name, desc;
  late List<_VariantCtrl> variants;
  bool busy = false;

  bool get isNew => widget.product == null;

  @override
  void initState() {
    super.initState();
    final cats = context.read<ShopState>().catalog!.categories;
    final id = 'p${DateTime.now().millisecondsSinceEpoch}';
    p =
        widget.product?.copy() ??
        Product(
          id: id,
          name: '',
          categoryId: cats.first.id,
          image: '',
          sort: 100000,
          variants: [Variant(id: '${id}_v0', label: '۵۰۰ گرم', price: 100000)],
        );
    name = TextEditingController(text: p.name);
    desc = TextEditingController(text: p.description);
    variants = [for (final v in p.variants) _VariantCtrl(v)];
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<ShopState>().catalog!.categories;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'محصول جدید' : 'ویرایش محصول'),
        actions: [
          if (!isNew)
            IconButton(
              tooltip: 'حذف محصول',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, color: NColors.danger),
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(width: 180, height: 180, child: ProductImage(p.image)),
                    ),
                    PositionedDirectional(
                      bottom: 8,
                      end: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: NColors.oliveDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('تغییر عکس', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'نام محصول'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'نام را وارد کنید' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: cats.any((c) => c.id == p.categoryId) ? p.categoryId : cats.first.id,
              decoration: const InputDecoration(labelText: 'دسته‌بندی'),
              items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) => p.categoryId = v!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: p.available,
              activeTrackColor: NColors.olive,
              onChanged: (v) => setState(() => p.available = v),
              title: const Text('نمایش در فروشگاه'),
              subtitle: Text(
                p.available ? 'مشتری‌ها این محصول را می‌بینند' : 'محصول مخفی است',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            SectionTitle(
              'گزینه‌های وزن و قیمت',
              trailing: TextButton.icon(onPressed: _addVariant, icon: const Icon(Icons.add), label: const Text('افزودن گزینه')),
            ),
            for (var i = 0; i < variants.length; i++) _variantEditor(i),
            const SizedBox(height: 4),
            const Text(
              'مثال: «۵۰۰ گرم»، «۱ کیلو»، «۱ مثقال»، «شیشه‌ای»، «بسته ۱۰ عددی». قیمت به تومان است.',
              style: TextStyle(fontSize: 12, color: NColors.muted),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: FilledButton(
            onPressed: busy ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: NColors.olive),
            child: Text(busy ? 'در حال ذخیره…' : 'ذخیره'),
          ),
        ),
      ),
    );
  }

  Widget _variantEditor(int i) {
    final v = variants[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 4, 6),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: v.label,
                      decoration: const InputDecoration(labelText: 'وزن / اندازه', isDense: true),
                      validator: (s) => (s ?? '').trim().isEmpty ? 'لازم است' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: v.price,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹]'))],
                      decoration: const InputDecoration(labelText: 'قیمت (تومان)', isDense: true),
                      onChanged: (_) => setState(() {}),
                      validator: (s) => int.tryParse(enDigits(s ?? '')) == null ? 'عدد وارد کنید' : null,
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف گزینه',
                    onPressed: variants.length == 1 ? null : () => setState(() => variants.removeAt(i)),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      int.tryParse(enDigits(v.price.text)) != null ? toman(int.parse(enDigits(v.price.text))) : '',
                      style: const TextStyle(fontSize: 12, color: NColors.muted),
                    ),
                  ),
                  const Text('موجود', style: TextStyle(fontSize: 13)),
                  Checkbox(
                    value: v.available,
                    activeColor: NColors.olive,
                    onChanged: (x) => setState(() => v.available = x ?? true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addVariant() => setState(
    () => variants.add(
      _VariantCtrl(
        Variant(
          id: '${p.id}_v${DateTime.now().millisecondsSinceEpoch}',
          label: '',
          price: variants.isEmpty ? 100000 : int.tryParse(enDigits(variants.last.price.text)) ?? 100000,
        ),
      ),
    ),
  );

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 78);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    try {
      final ref = await context.read<ShopState>().repo.uploadImage(bytes);
      setState(() => p.image = ref);
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    p
      ..name = name.text.trim()
      ..description = desc.text.trim()
      ..variants = [
        for (final v in variants)
          Variant(id: v.id, label: v.label.text.trim(), price: int.parse(enDigits(v.price.text)), available: v.available),
      ];
    setState(() => busy = true);
    try {
      await context.read<ShopState>().saveProduct(p);
      if (!mounted) return;
      showMsg(context, 'ذخیره شد');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف محصول'),
        content: Text('«${p.name}» برای همیشه حذف شود؟\n(اگر فقط موقتاً تمام شده، به جای حذف آن را مخفی یا ناموجود کنید.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<ShopState>().deleteProduct(p.id);
    if (mounted) Navigator.of(context).pop();
  }
}
