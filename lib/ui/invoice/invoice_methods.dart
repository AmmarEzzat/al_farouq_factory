import 'package:al_farouq_factory/model/client_model.dart';
import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/ui/invoice/invoice_item.dart';
import 'package:al_farouq_factory/widget/transaction.dart';

class InvoiceService {
  static Future<Invoice> createInvoice({
    required Client client,
    required List<InvoiceItem> items,
    bool isReturn = false,
  }) async {
    final inventoryList = await StorageService.getInventory();
    final invoices = await StorageService.getInvoices();
    final total = items.fold(0.0, (sum, e) => sum + e.total);

    if (isReturn) {
      // 1. إعادة الأصناف للمخزن فقط
      for (final item in items) {
        final inv = inventoryList.firstWhere(
              (e) => e.name == item.itemName,
          orElse: () => throw Exception('الصنف غير موجود'),
        );
        inv.add(item.quantity);
      }

      final invoice = Invoice(
        invoiceNumber: invoices.length + 1,
        clientName: client.name,
        date: DateTime.now(),
        items: items,
        total: -total,
        isReturn: true,
      );
      invoices.add(invoice);
      await StorageService.saveInvoices(invoices);
      await StorageService.saveInventory(inventoryList);

      return invoice;
    } else {
      // 2. خصم من المخزن فقط
      for (final item in items) {
        final inv = inventoryList.firstWhere(
              (e) => e.name == item.itemName,
          orElse: () => throw Exception('الصنف غير موجود'),
        );
        inv.deduct(item.quantity);
      }

      await StorageService.saveInventory(inventoryList);

      final invoice = Invoice(
        invoiceNumber: invoices.length + 1,
        clientName: client.name,
        date: DateTime.now(),
        items: items,
        total: total,
        isReturn: false,
      );
      invoices.add(invoice);
      await StorageService.saveInvoices(invoices);

      return invoice;
    }
    // تم حذف أكواد setClientDebt و addTransaction من هنا نهائياً
    // لأن الشاشة (CreateInvoiceScreen) هي التي ستقوم بهذا الدور بناءً على "المبلغ المدفوع"
  }

  static Future<List<Invoice>> getClientInvoices(String clientName) async {
    final invoices = await StorageService.getInvoices();
    return invoices
        .where((e) => e.clientName == clientName)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}