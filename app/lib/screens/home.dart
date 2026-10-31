import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'product.dart';
import 'shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? categoryId;
  String query = '';
  final searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final c = state.catalog!;
    final products = state.productsIn(categoryId, query: query);
    final width = MediaQuery.sizeOf(context).width;
    final cols = width > 900
        ? 5
        : width > 650
        ? 4
        : width > 430
        ? 3
        : 2;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: NColors.orange,
        onRefresh: state.reload,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: DemoBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Image.asset('assets/logo.png', width: 58, height: 58),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.settings.shopName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NColors.oliveDark),
                          ),
                          if (c.settings.slogan.isNotEmpty)
                            Text(
                              c.settings.slogan,
                              style: const TextStyle(fontSize: 13, color: NColors.orange, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    CartIconButton(onTap: () => Shell.goTo(context, 1)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (v) => setState(() => query = v),
                  decoration: InputDecoration(
                    hintText: 'جستجوی محصول… (مثلاً سبزی، ترشی، مربا)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              query = '';
                              searchCtrl.clear();
                            }),
                          ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 54,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _catChip('همه محصولات', null),
                    for (final cat in c.categories)
                      if (c.products.any((p) => p.categoryId == cat.id && p.available)) _catChip(cat.name, cat.id),
                  ],
                ),
              ),
            ),
            if (products.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.search_off, title: 'محصولی پیدا نشد', subtitle: 'عبارت دیگری را جستجو کنید'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: (width / cols) + 84,
                  ),
                  delegate: SliverChildBuilderDelegate((_, i) => ProductCard(product: products[i]), childCount: products.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _catChip(String label, String? id) {
    final selected = categoryId == id;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: NColors.olive,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          color: selected ? Colors.white : NColors.text,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        onSelected: (_) => setState(() => categoryId = id),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final state = context.read<ShopState>();
    final minPrice = p.minPrice;
    final multi = p.availableVariants.length > 1;
    void open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(productId: p.id)));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: 'img-${p.id}', child: ProductImage(p.image)),
                  if (!p.inStock)
                    Container(
                      color: Colors.white.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: NColors.text.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ناموجود',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (multi)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${faDigits(p.availableVariants.length)} گزینه',
                          style: const TextStyle(fontSize: 11, color: NColors.olive, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.35),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: minPrice == null
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      multi ? 'از' : p.availableVariants.first.label,
                                      style: const TextStyle(fontSize: 11, color: NColors.muted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      toman(minPrice),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: NColors.oliveDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                        ),
                        if (p.inStock)
                          Material(
                            color: NColors.orange,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                if (multi) return open();
                                state.addToCart(p.id, p.availableVariants.first.id);
                                showMsg(context, '«${p.name}» به سبد خرید اضافه شد');
                              },
                              child: const SizedBox(width: 34, height: 34, child: Icon(Icons.add, color: Colors.white, size: 22)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
