import 'package:al_farouq_factory/ui/invoice/invoice_screen_pdf.dart';
import 'package:flutter/material.dart';
import 'package:al_farouq_factory/model/invoice_model.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // جديد: callback للحذف

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.onDelete, // جديد
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        title: Text(
          "فاتورة بتاريخ: ${invoice.date.day}/${invoice.date.month}/${invoice.date.year}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("عدد الأصناف: ${invoice.items.length}"),
            Text("إجمالي المبلغ: ${invoice.total.toStringAsFixed(2)}"),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () {
                    InvoicePdfService.generate(invoice);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    if (onDelete != null) {
                      // تنفيذ callback الحذف
                      onDelete!();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
