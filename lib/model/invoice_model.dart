import 'package:al_farouq_factory/ui/invoice/invoice_item.dart';

class Invoice {
  final int invoiceNumber;
  final String clientName;
  final DateTime date;
  final List<InvoiceItem> items;
  final double total;
  final bool isReturn; // جديد: لتحديد إذا كانت الفاتورة مرتجع

  Invoice({
    required this.invoiceNumber,
    required this.clientName,
    required this.date,
    required this.items,
    required this.total,
    this.isReturn = false, // الافتراضي false
  });

  /// تاريخ منسق للعرض و PDF
  String get formattedDate =>
      '${date.day}/${date.month}/${date.year}';

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'date': date.toIso8601String(),
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'isReturn': isReturn, // حفظ حالة المرتجع
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
      total: (map['total'] ?? 0).toDouble(),
      isReturn: map['isReturn'] ?? false, // قراءة حالة المرتجع
    );
  }
}
