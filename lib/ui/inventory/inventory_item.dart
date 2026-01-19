class InventoryItem {
  final String name;
  final String unit;
  int quantity;
  final double buyPrice;
  final double sellPrice;

  InventoryItem({
    required this.name,
    required this.unit,
    required int quantity,
    double buyPrice = 0,
    double sellPrice = 0,
  })  : quantity = quantity < 0 ? 0 : quantity,
        buyPrice = buyPrice < 0 ? 0 : buyPrice,
        sellPrice = sellPrice < 0 ? 0 : sellPrice;

  /// هل متاح للبيع
  bool get isAvailable => quantity > 0;

  /// خصم كمية من المخزن
  void deduct(int qty) {
    if (qty <= 0) return;
    quantity -= qty;
    if (quantity < 0) quantity = 0;
  }

  /// إضافة كمية للمخزن (مرتجع)
  void add(int qty) {
    if (qty <= 0) return;
    quantity += qty;
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'unit': unit,
    'quantity': quantity,
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
  };

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity'] ?? 0,
      buyPrice: (map['buyPrice'] ?? 0).toDouble(),
      sellPrice: (map['sellPrice'] ?? 0).toDouble(),
    );
  }
}
