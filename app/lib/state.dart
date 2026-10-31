import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'repo.dart';

/// وضعیت کلی اپ: کاتالوگ، سبد خرید، سفارش‌های مشتری و ورود مدیر.
class ShopState extends ChangeNotifier {
  final ShopRepository repo;
  ShopState(this.repo);

  Catalog? catalog;
  String? loadError;
  bool loading = true;
  final List<CartItem> cart = [];
  List<String> orderTokens = [];
  bool isAdmin = false;
  Map<String, String> savedCustomer = {};

  static const _kCart = 'cart_v1', _kTokens = 'order_tokens_v1', _kCustomer = 'customer_v1';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      for (final c in jsonDecode(prefs.getString(_kCart) ?? '[]')) {
        cart.add(CartItem.fromJson(c));
      }
      orderTokens = prefs.getStringList(_kTokens) ?? [];
      savedCustomer = Map<String, String>.from(jsonDecode(prefs.getString(_kCustomer) ?? '{}'));
    } catch (_) {}
    await reload();
  }

  Future<void> reload() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      catalog = await repo.loadCatalog();
      _pruneCart();
    } catch (e) {
      loadError = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  // ----------------------------------------------------------- جستجو در کاتالوگ
  Product? product(String id) => catalog?.products.where((p) => p.id == id).firstOrNull;

  List<Product> productsIn(String? categoryId, {String query = '', bool includeHidden = false}) {
    final q = query.trim();
    return [
      for (final p in catalog?.products ?? <Product>[])
        if ((includeHidden || p.available) &&
            (categoryId == null || p.categoryId == categoryId) &&
            (q.isEmpty || p.name.contains(q)))
          p,
    ];
  }

  // ----------------------------------------------------------- سبد خرید
  int get cartCount => cart.fold(0, (s, i) => s + i.qty);

  int get cartSubtotal {
    var sum = 0;
    for (final i in cart) {
      final v = variantOf(i);
      if (v != null) sum += v.price * i.qty;
    }
    return sum;
  }

  Variant? variantOf(CartItem i) => product(i.productId)?.variants.where((v) => v.id == i.variantId).firstOrNull;

  int qtyInCart(String productId, String variantId) =>
      cart.where((i) => i.productId == productId && i.variantId == variantId).firstOrNull?.qty ?? 0;

  void addToCart(String productId, String variantId, [int qty = 1]) {
    final existing = cart.where((i) => i.productId == productId && i.variantId == variantId).firstOrNull;
    if (existing != null) {
      existing.qty += qty;
    } else {
      cart.add(CartItem(productId: productId, variantId: variantId, qty: qty));
    }
    _saveCart();
  }

  void setQty(CartItem item, int qty) {
    if (qty <= 0) {
      cart.remove(item);
    } else {
      item.qty = qty;
    }
    _saveCart();
  }

  void clearCart() {
    cart.clear();
    _saveCart();
  }

  void _pruneCart() {
    cart.removeWhere((i) {
      final p = product(i.productId);
      final v = variantOf(i);
      return p == null || v == null || !p.available || !v.available;
    });
  }

  Future<void> _saveCart() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCart, jsonEncode([for (final i in cart) i.toJson()]));
  }

  // ----------------------------------------------------------- سفارش
  Future<Order> placeOrder(CheckoutInfo info) async {
    final order = await repo.placeOrder(info, List.of(cart));
    orderTokens = [order.token, ...orderTokens];
    savedCustomer = {'name': info.name, 'phone': info.phone, 'address': info.address};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kTokens, orderTokens);
    await prefs.setString(_kCustomer, jsonEncode(savedCustomer));
    clearCart();
    return order;
  }

  Future<List<Order>> myOrders() => repo.myOrders(orderTokens);

  // ----------------------------------------------------------- مدیریت
  Future<bool> adminLogin(String password) async {
    isAdmin = await repo.login(password);
    notifyListeners();
    return isAdmin;
  }

  void adminLogout() {
    isAdmin = false;
    notifyListeners();
  }

  Future<void> saveProduct(Product p) async {
    await repo.saveProduct(p);
    await reload();
  }

  Future<void> deleteProduct(String id) async {
    await repo.deleteProduct(id);
    await reload();
  }

  Future<void> saveCategories(List<Category> cats) async {
    await repo.saveCategories(cats);
    await reload();
  }

  Future<void> saveSettings(ShopSettings s) async {
    await repo.saveSettings(s);
    await reload();
  }
}
