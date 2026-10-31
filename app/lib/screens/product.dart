import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class ProductScreen extends StatefulWidget {
  final String productId;
  const ProductScreen({super.key, required this.productId});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String? variantId;
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final p = state.product(widget.productId);
    if (p == null)
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.error_outline, title: 'این محصول دیگر وجود ندارد'),
      );
    final variants = p.variants;
    final available = p.availableVariants;
    variantId ??= available.isNotEmpty ? available.first.id : null;
    final selected = variants.where((v) => v.id == variantId).firstOrNull;
    final cat = state.catalog!.categories.where((c) => c.id == p.categoryId).firstOrNull;
    final wide = MediaQuery.sizeOf(context).width > 700;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(wide ? 20 : 0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Hero(tag: 'img-${p.id}', child: ProductImage(p.image)),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cat != null)
          Text(
            cat.name,
            style: const TextStyle(color: NColors.orange, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        const SizedBox(height: 4),
        Text(
          p.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: NColors.oliveDark),
        ),
        if (p.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(p.description, style: const TextStyle(color: NColors.muted, height: 1.7)),
        ],
        const SectionTitle('انتخاب وزن / اندازه'),
        for (final v in variants) _variantTile(v),
        if (!p.inStock)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'این محصول فعلاً موجود نیست.',
              style: TextStyle(color: NColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [CartIconButton(onTap: () => Navigator.of(context).popUntil((r) => r.isFirst))],
      ),
      body: ListView(
        padding: EdgeInsets.all(wide ? 24 : 0),
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: image),
                const SizedBox(width: 28),
                Expanded(child: details),
              ],
            )
          else ...[
            image,
            Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), child: details),
          ],
        ],
      ),
      bottomNavigationBar: (selected == null || !p.inStock)
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEFE8D8))),
                ),
                child: Row(
                  children: [
                    QtyStepper(deletable: false, qty: qty, onChanged: (q) => setState(() => qty = q < 1 ? 1 : q)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          state.addToCart(p.id, selected.id, qty);
                          showMsg(context, '«${p.name}» (${selected.label}) به سبد خرید اضافه شد');
                          Navigator.of(context).pop();
                        },
                        child: FittedBox(child: Text('افزودن به سبد  •  ${toman(selected.price * qty)}')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _variantTile(Variant v) {
    final selected = v.id == variantId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? NColors.olive.withValues(alpha: 0.07) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? NColors.olive : const Color(0xFFE6DFCD), width: selected ? 1.6 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: v.available ? () => setState(() => variantId = v.id) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: v.available ? NColors.olive : NColors.muted.withValues(alpha: 0.5),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    v.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: v.available ? NColors.text : NColors.muted,
                    ),
                  ),
                ),
                v.available
                    ? Text(
                        toman(v.price),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: NColors.oliveDark),
                      )
                    : const Text(
                        'ناموجود',
                        style: TextStyle(color: NColors.danger, fontWeight: FontWeight.w600),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
