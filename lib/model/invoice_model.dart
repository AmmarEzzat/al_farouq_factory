import 'package:al_farouq_factory/ui/invoice/invoice_item.dart';

class Invoice {
  final int invoiceNumber;
  final String clientName;
  final DateTime date;
  final List<InvoiceItem> items;
  final bool isReturn;

  Invoice({
    required this.invoiceNumber,
    required this.clientName,
    required this.date,
    required this.items,
    this.isReturn = false,
  });

  /// إجمالي الفاتورة محسوب من الأصناف
  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  String get formattedDate => '${date.day}/${date.month}/${date.year}';

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'date': date.toIso8601String(),
      'items': items.map((e) => e.toMap()).toList(),
      'isReturn': isReturn,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      invoiceNumber: map['invoiceNumber'] ?? 0,
      clientName: map['clientName'] ?? '',
      date: DateTime.parse(map['date']),
      items: (map['items'] as List)
          .map((e) => InvoiceItem.fromMap(e))
          .toList(),
      isReturn: map['isReturn'] ?? false,
    );
  }
}
