class InvoiceItem {
  final String itemName;
  final int quantity;
  final double price;

  InvoiceItem({
    required this.itemName,
    required int quantity,
    required double price,
  })  : quantity = quantity < 0 ? 0 : quantity,
        price = price < 0 ? 0 : price;

  /// إجمالي الصنف
  double get total => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      itemName: map['itemName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}
