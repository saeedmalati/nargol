import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'models.dart';

class ShopException implements Exception {
  final String message;
  ShopException(this.message);
  @override
  String toString() => message;
}

/// منبع داده اپ. دو پیاده‌سازی دارد:
///  - [ApiRepository]: اتصال به سرور واقعی (فروش واقعی و پرداخت زرین‌پال)
///  - [LocalRepository]: حالت نمایشی، همه چیز روی خود گوشی
abstract class ShopRepository {
  Future<Catalog> loadCatalog();
  Future<Order> placeOrder(CheckoutInfo info, List<CartItem> items);
  Future<List<Order>> myOrders(List<String> tokens);
  Future<Order> demoPay(String orderId);

  Future<bool> login(String password);
  Future<void> saveProduct(Product p);
  Future<void> deleteProduct(String id);
  Future<String> uploadImage(Uint8List bytes);
  Future<void> saveCategories(List<Category> cats);
  Future<void> saveSettings(ShopSettings s);
  Future<List<Order>> adminOrders();
  Future<void> setOrderStatus(String orderId, String status);
  Future<void> changePassword(String newPassword);

  static ShopRepository create() => isDemo ? LocalRepository() : ApiRepository(apiBase);
}

String _randomToken([int len = 24]) {
  final r = Random.secure();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
}

/// محاسبه اقلام سفارش از روی کاتالوگ (قیمت همیشه از کاتالوگ خوانده می‌شود)
List<OrderLine> buildLines(Catalog c, List<CartItem> items) {
  final lines = <OrderLine>[];
  for (final it in items) {
    final p = c.products.where((x) => x.id == it.productId).firstOrNull;
    final v = p?.variants.where((x) => x.id == it.variantId).firstOrNull;
    if (p == null || v == null || !p.available || !v.available) {
      throw ShopException('بعضی محصولات سبد خرید دیگر موجود نیستند. لطفاً سبد را بررسی کنید.');
    }
    lines.add(OrderLine(productId: p.id, variantId: v.id, name: p.name, label: v.label, price: v.price, qty: it.qty));
  }
  return lines;
}

// ---------------------------------------------------------------- حالت نمایشی
class LocalRepository implements ShopRepository {
  static const _kCatalog = 'demo_catalog_v1', _kOrders = 'demo_orders_v1', _kPass = 'demo_pass_v1';
  Catalog? _catalog;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<Catalog> loadCatalog() async {
    final prefs = await _prefs;
    final saved = prefs.getString(_kCatalog);
    final raw = saved ?? await rootBundle.loadString('assets/data/catalog.json');
    return _catalog = Catalog.fromJson(jsonDecode(raw));
  }

  Future<void> _persist() async => (await _prefs).setString(_kCatalog, jsonEncode(_catalog!.toJson()));

  Future<List<Order>> _orders() async {
    final raw = (await _prefs).getString(_kOrders);
    if (raw == null) return [];
    return [for (final o in jsonDecode(raw)) Order.fromJson(o)];
  }

  Future<void> _saveOrders(List<Order> list) async =>
      (await _prefs).setString(_kOrders, jsonEncode([for (final o in list) o.toJson()]));

  @override
  Future<Order> placeOrder(CheckoutInfo info, List<CartItem> items) async {
    final c = _catalog ?? await loadCatalog();
    final lines = buildLines(c, items);
    final subtotal = lines.fold<int>(0, (s, l) => s + l.price * l.qty);
    final fee = info.method == 'delivery' ? c.settings.deliveryCostFor(subtotal) : 0;
    final list = await _orders();
    final order = Order(
      id: '${1000 + list.length + 1}',
      token: _randomToken(),
      customerName: info.name,
      phone: info.phone,
      address: info.address,
      note: info.note,
      method: info.method,
      branchIndex: info.branchIndex,
      lines: lines,
      subtotal: subtotal,
      deliveryFee: fee,
      total: subtotal + fee,
      status: 'pending_payment',
      createdAt: DateTime.now(),
    );
    await _saveOrders([order, ...list]);
    return order;
  }

  @override
  Future<Order> demoPay(String orderId) async {
    final list = await _orders();
    final i = list.indexWhere((o) => o.id == orderId);
    final o = list[i];
    final paid = Order.fromJson({...o.toJson(), 'status': 'paid', 'refId': '${Random().nextInt(899999999) + 100000000}'});
    list[i] = paid;
    await _saveOrders(list);
    return paid;
  }

  @override
  Future<List<Order>> myOrders(List<String> tokens) async => [
    for (final o in await _orders())
      if (tokens.contains(o.token)) o,
  ];

  @override
  Future<bool> login(String password) async {
    final saved = (await _prefs).getString(_kPass) ?? demoAdminPassword;
    return password == saved;
  }

  @override
  Future<void> changePassword(String newPassword) async => (await _prefs).setString(_kPass, newPassword);

  @override
  Future<void> saveProduct(Product p) async {
    final list = _catalog!.products;
    final i = list.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      list[i] = p;
    } else {
      list.add(p);
    }
    await _persist();
  }

  @override
  Future<void> deleteProduct(String id) async {
    _catalog!.products.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<String> uploadImage(Uint8List bytes) async => 'data:image/jpeg;base64,${base64Encode(bytes)}';

  @override
  Future<void> saveCategories(List<Category> cats) async {
    _catalog!.categories = cats;
    await _persist();
  }

  @override
  Future<void> saveSettings(ShopSettings s) async {
    _catalog!.settings = s;
    await _persist();
  }

  @override
  Future<List<Order>> adminOrders() => _orders();

  @override
  Future<void> setOrderStatus(String orderId, String status) async {
    final list = await _orders();
    final i = list.indexWhere((o) => o.id == orderId);
    list[i] = Order.fromJson({...list[i].toJson(), 'status': status});
    await _saveOrders(list);
  }
}

// ---------------------------------------------------------------- سرور واقعی
class ApiRepository implements ShopRepository {
  final String base;
  String? _adminToken;
  ApiRepository(this.base);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
  };

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final uri = Uri.parse('$base$path');
    late http.Response r;
    try {
      final req = http.Request(method, uri)..headers.addAll(_headers);
      if (body != null) req.body = jsonEncode(body);
      r = await http.Response.fromStream(await req.send()).timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ShopException('ارتباط با سرور برقرار نشد. اتصال اینترنت را بررسی کنید.');
    }
    final data = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) {
      throw ShopException((data is Map ? data['error'] : null) ?? 'خطا در سرور (${r.statusCode})');
    }
    return data;
  }

  @override
  Future<Catalog> loadCatalog() async => Catalog.fromJson(await _send('GET', '/api/catalog'));

  @override
  Future<Order> placeOrder(CheckoutInfo info, List<CartItem> items) async {
    final data = await _send('POST', '/api/orders', {
      ...info.toJson(),
      'items': [for (final i in items) i.toJson()],
    });
    return Order.fromJson(data);
  }

  @override
  Future<List<Order>> myOrders(List<String> tokens) async {
    if (tokens.isEmpty) return [];
    final data = await _send('POST', '/api/orders/mine', {'tokens': tokens});
    return [for (final o in data) Order.fromJson(o)];
  }

  @override
  Future<Order> demoPay(String orderId) => throw UnsupportedError('demo only');

  @override
  Future<bool> login(String password) async {
    try {
      final data = await _send('POST', '/api/admin/login', {'password': password});
      _adminToken = data['token'];
      return true;
    } on ShopException {
      return false;
    }
  }

  @override
  Future<void> changePassword(String newPassword) => _send('POST', '/api/admin/password', {'password': newPassword});

  @override
  Future<void> saveProduct(Product p) => _send('PUT', '/api/admin/products/${p.id}', p.toJson());

  @override
  Future<void> deleteProduct(String id) => _send('DELETE', '/api/admin/products/$id');

  @override
  Future<String> uploadImage(Uint8List bytes) async {
    final r = await http.post(
      Uri.parse('$base/api/admin/upload'),
      headers: {'Content-Type': 'image/jpeg', 'Authorization': 'Bearer $_adminToken'},
      body: bytes,
    );
    if (r.statusCode >= 400) throw ShopException('آپلود عکس انجام نشد');
    return jsonDecode(r.body)['image'];
  }

  @override
  Future<void> saveCategories(List<Category> cats) => _send('PUT', '/api/admin/categories', [for (final c in cats) c.toJson()]);

  @override
  Future<void> saveSettings(ShopSettings s) => _send('PUT', '/api/admin/settings', s.toJson());

  @override
  Future<List<Order>> adminOrders() async {
    final data = await _send('GET', '/api/admin/orders');
    return [for (final o in data) Order.fromJson(o)];
  }

  @override
  Future<void> setOrderStatus(String orderId, String status) => _send('PATCH', '/api/admin/orders/$orderId', {'status': status});
}
