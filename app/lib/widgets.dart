import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'format.dart';
import 'models.dart';
import 'state.dart';
import 'theme.dart';

/// نمایش عکس محصول؛ عکس داخل اپ، عکس سرور، یا عکس آپلودشده در حالت نمایشی
class ProductImage extends StatelessWidget {
  final String image;
  final BoxFit fit;
  const ProductImage(this.image, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext c, Object e, StackTrace? s) => Container(
      color: const Color(0xFFE4EFED),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: NColors.muted, size: 36),
    );
    if (image.isEmpty) return fallback(context, '', null);
    if (image.startsWith('data:')) {
      return Image.memory(base64Decode(image.split(',').last), fit: fit, errorBuilder: fallback);
    }
    if (image.startsWith('http')) return Image.network(image, fit: fit, errorBuilder: fallback);
    if (image.startsWith('/')) return Image.network('$apiBase$image', fit: fit, errorBuilder: fallback);
    return Image.asset('assets/products/$image', fit: fit, errorBuilder: fallback);
  }
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool deletable;
  const QtyStepper({super.key, required this.qty, required this.onChanged, this.compact = false, this.deletable = true});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 38.0;
    Widget btn(IconData icon, VoidCallback onTap) => InkResponse(
      onTap: onTap,
      radius: size / 2 + 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: NColors.olive.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: compact ? 18 : 20, color: NColors.olive),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.add, () => onChanged(qty + 1)),
        SizedBox(
          width: compact ? 30 : 40,
          child: Text(
            faDigits(qty),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 14 : 16),
          ),
        ),
        btn(qty <= 1 && deletable ? Icons.delete_outline : Icons.remove, () => onChanged(qty - 1)),
      ],
    );
  }
}

class CartIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const CartIconButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final n = context.watch<ShopState>().cartCount;
    return IconButton(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: n > 0,
        backgroundColor: NColors.warm,
        label: Text(faDigits(n)),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: NColors.olive.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(color: NColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending_payment' => NColors.muted,
      'canceled' => NColors.danger,
      'done' => NColors.success,
      'paid' || 'preparing' => NColors.orange,
      _ => NColors.olive,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        orderStatuses[status] ?? status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: NColors.oliveDark),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) {
    if (!isDemo) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: NColors.orange.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: const Text(
        'نسخه نمایشی — پرداخت‌ها آزمایشی هستند',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: NColors.brown),
      ),
    );
  }
}

void showMsg(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontFamily: 'Vazirmatn')),
        backgroundColor: error ? NColors.danger : NColors.oliveDark,
      ),
    );
}
