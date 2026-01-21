class Product {
  String name;
  double quantity;
  double price;

  Product({required this.name, required this.quantity, required this.price});

  // تحويل البيانات لـ Map عشان التخزين
  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'price': price,
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    name: map['name'],
    quantity: map['quantity'],
    price: map['price'],
  );
}