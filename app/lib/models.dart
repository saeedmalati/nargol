class Category {
  String id;
  String name;
  int sort;
  Category({required this.id, required this.name, this.sort = 0});
  factory Category.fromJson(Map<String, dynamic> j) => Category(id: j['id'], name: j['name'], sort: (j['sort'] ?? 0) as int);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'sort': sort};
}

class Variant {
  String id;
  String label; // مثلا «۵۰۰ گرم» یا «۱ کیلو»
  int price; // تومان
  bool available;
  Variant({required this.id, required this.label, required this.price, this.available = true});
  factory Variant.fromJson(Map<String, dynamic> j) =>
      Variant(id: j['id'], label: j['label'], price: (j['price'] as num).toInt(), available: j['available'] ?? true);
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'price': price, 'available': available};
  Variant copy() => Variant.fromJson(toJson());
}

class Product {
  String id;
  String name;
  String categoryId;
  String image;
  String description;
  bool available;
  int sort;
  List<Variant> variants;
  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.image,
    this.description = '',
    this.available = true,
    this.sort = 0,
    required this.variants,
  });
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'],
    name: j['name'],
    categoryId: j['categoryId'],
    image: j['image'] ?? '',
    description: j['description'] ?? '',
    available: j['available'] ?? true,
    sort: (j['sort'] ?? 0) as int,
    variants: [for (final v in (j['variants'] as List)) Variant.fromJson(v)],
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'image': image,
    'description': description,
    'available': available,
    'sort': sort,
    'variants': [for (final v in variants) v.toJson()],
  };
  Product copy() => Product.fromJson(toJson());

  List<Variant> get availableVariants => [
    for (final v in variants)
      if (v.available) v,
  ];
  bool get inStock => available && availableVariants.isNotEmpty;
  int? get minPrice => availableVariants.isEmpty ? null : availableVariants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
}

class Branch {
  String name, address, phone;
  Branch({required this.name, required this.address, required this.phone});
  factory Branch.fromJson(Map<String, dynamic> j) => Branch(name: j['name'], address: j['address'], phone: j['phone']);
  Map<String, dynamic> toJson() => {'name': name, 'address': address, 'phone': phone};
}

class ShopSettings {
  String shopName, slogan, healthCertificate, healthCard;
  int deliveryFee, freeDeliveryOver, minOrder;
  bool deliveryEnabled, pickupEnabled;
  List<Branch> branches;
  ShopSettings({
    required this.shopName,
    required this.slogan,
    required this.healthCertificate,
    required this.healthCard,
    required this.deliveryFee,
    required this.freeDeliveryOver,
    required this.minOrder,
    required this.deliveryEnabled,
    required this.pickupEnabled,
    required this.branches,
  });
  factory ShopSettings.fromJson(Map<String, dynamic> j) => ShopSettings(
    shopName: j['shopName'] ?? '',
    slogan: j['slogan'] ?? '',
    healthCertificate: j['healthCertificate'] ?? '',
    healthCard: j['healthCard'] ?? '',
    deliveryFee: (j['deliveryFee'] ?? 0) as int,
    freeDeliveryOver: (j['freeDeliveryOver'] ?? 0) as int,
    minOrder: (j['minOrder'] ?? 0) as int,
    deliveryEnabled: j['deliveryEnabled'] ?? true,
    pickupEnabled: j['pickupEnabled'] ?? true,
    branches: [for (final b in (j['branches'] as List? ?? [])) Branch.fromJson(b)],
  );
  Map<String, dynamic> toJson() => {
    'shopName': shopName,
    'slogan': slogan,
    'healthCertificate': healthCertificate,
    'healthCard': healthCard,
    'deliveryFee': deliveryFee,
    'freeDeliveryOver': freeDeliveryOver,
    'minOrder': minOrder,
    'deliveryEnabled': deliveryEnabled,
    'pickupEnabled': pickupEnabled,
    'branches': [for (final b in branches) b.toJson()],
  };

  /// هزینه ارسال برای یک مبلغ سفارش (۰ اگر رایگان باشد).
  int deliveryCostFor(int subtotal) => (freeDeliveryOver > 0 && subtotal >= freeDeliveryOver) ? 0 : deliveryFee;
}

class Catalog {
  List<Category> categories;
  List<Product> products;
  ShopSettings settings;
  Catalog({required this.categories, required this.products, required this.settings});
  factory Catalog.fromJson(Map<String, dynamic> j) => Catalog(
    categories: [for (final c in j['categories']) Category.fromJson(c)]..sort((a, b) => a.sort.compareTo(b.sort)),
    products: [for (final p in j['products']) Product.fromJson(p)]..sort((a, b) => a.sort.compareTo(b.sort)),
    settings: ShopSettings.fromJson(j['settings']),
  );
  Map<String, dynamic> toJson() => {
    'categories': [for (final c in categories) c.toJson()],
    'products': [for (final p in products) p.toJson()],
    'settings': settings.toJson(),
  };
}

class CartItem {
  final String productId;
  final String variantId;
  int qty;
  CartItem({required this.productId, required this.variantId, this.qty = 1});
  factory CartItem.fromJson(Map<String, dynamic> j) =>
      CartItem(productId: j['productId'], variantId: j['variantId'], qty: j['qty']);
  Map<String, dynamic> toJson() => {'productId': productId, 'variantId': variantId, 'qty': qty};
  String get key => '$productId|$variantId';
}

class OrderLine {
  final String productId, variantId, name, label;
  final int price, qty;
  OrderLine({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.label,
    required this.price,
    required this.qty,
  });
  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
    productId: j['productId'],
    variantId: j['variantId'],
    name: j['name'],
    label: j['label'],
    price: (j['price'] as num).toInt(),
    qty: (j['qty'] as num).toInt(),
  );
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'variantId': variantId,
    'name': name,
    'label': label,
    'price': price,
    'qty': qty,
  };
}

/// وضعیت‌های سفارش
const orderStatuses = {
  'pending_payment': 'در انتظار پرداخت',
  'paid': 'پرداخت شد',
  'preparing': 'در حال آماده‌سازی',
  'sending': 'ارسال شد',
  'ready': 'آماده تحویل در شعبه',
  'done': 'تحویل شد',
  'canceled': 'لغو شد',
};

class Order {
  final String id;
  final String token; // کلید مشتری برای دیدن سفارش خودش
  final String customerName, phone, address, note;
  final String method; // delivery | pickup
  final int? branchIndex;
  final List<OrderLine> lines;
  final int subtotal, deliveryFee, total;
  String status;
  final String? refId;
  final String? paymentUrl;
  final DateTime createdAt;
  Order({
    required this.id,
    required this.token,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.note,
    required this.method,
    required this.branchIndex,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.createdAt,
    this.refId,
    this.paymentUrl,
  });
  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'].toString(),
    token: j['token'] ?? '',
    customerName: j['customerName'] ?? '',
    phone: j['phone'] ?? '',
    address: j['address'] ?? '',
    note: j['note'] ?? '',
    method: j['method'] ?? 'delivery',
    branchIndex: j['branchIndex'],
    lines: [for (final l in (j['lines'] as List)) OrderLine.fromJson(l)],
    subtotal: (j['subtotal'] as num).toInt(),
    deliveryFee: (j['deliveryFee'] as num).toInt(),
    total: (j['total'] as num).toInt(),
    status: j['status'],
    refId: j['refId']?.toString(),
    paymentUrl: j['paymentUrl'],
    createdAt: DateTime.parse(j['createdAt']),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'token': token,
    'customerName': customerName,
    'phone': phone,
    'address': address,
    'note': note,
    'method': method,
    'branchIndex': branchIndex,
    'lines': [for (final l in lines) l.toJson()],
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'total': total,
    'status': status,
    'refId': refId,
    'paymentUrl': paymentUrl,
    'createdAt': createdAt.toIso8601String(),
  };
  String get statusText => orderStatuses[status] ?? status;
}

/// اطلاعاتی که مشتری در صفحه تکمیل خرید وارد می‌کند.
class CheckoutInfo {
  final String name, phone, address, note, method;
  final int? branchIndex;
  CheckoutInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.note,
    required this.method,
    this.branchIndex,
  });
  Map<String, dynamic> toJson() => {
    'customerName': name,
    'phone': phone,
    'address': address,
    'note': note,
    'method': method,
    'branchIndex': branchIndex,
  };
}
