import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../format.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'admin_product_edit.dart';

class AdminProducts extends StatefulWidget {
  const AdminProducts({super.key});
  @override
  State<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends State<AdminProducts> {
  String? categoryId;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final cats = state.catalog!.categories;
    final list = state.productsIn(categoryId, query: query, includeHidden: true);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: NColors.orange,
        foregroundColor: Colors.white,
        onPressed: () => _open(null),
        icon: const Icon(Icons.add),
        label: const Text('محصول جدید'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(hintText: 'جستجو', prefixIcon: Icon(Icons.search), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('همه دسته‌ها')),
                      for (final c in cats)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => categoryId = v),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '${faDigits(list.length)} محصول — برای ویرایش قیمت و وزن روی محصول بزنید',
              style: const TextStyle(fontSize: 12, color: NColors.muted),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = list[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                    onTap: () => _open(p),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Opacity(
                        opacity: p.available ? 1 : 0.4,
                        child: SizedBox(width: 54, height: 54, child: ProductImage(p.image)),
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: TextStyle(fontWeight: FontWeight.w700, color: p.available ? null : NColors.muted),
                    ),
                    subtitle: Text(
                      p.variants
                          .map((v) => '${v.label}: ${faDigits(groupDigits(v.price))}${v.available ? '' : ' (ناموجود)'}')
                          .join('  |  '),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Switch(
                      value: p.available,
                      activeTrackColor: NColors.olive,
                      onChanged: (v) async {
                        final copy = p.copy()..available = v;
                        try {
                          await state.saveProduct(copy);
                        } catch (e) {
                          if (context.mounted) showMsg(context, e.toString(), error: true);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _open(Product? p) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminProductEdit(product: p)));
}
