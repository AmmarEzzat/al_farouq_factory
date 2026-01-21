import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:flutter/material.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/utils/app_colors.dart';
import 'package:intl/intl.dart'; // عشان تنسيق التاريخ

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Invoice> invoices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => isLoading = true);
    final list = await StorageService.getInvoices();
    setState(() {
      // بنعرض هنا الفواتير فقط (سحب البضاعة)
      invoices = list.reversed.toList(); // عرض الأحدث أولاً
      isLoading = false;
    });
  }

  // إجمالي المبيعات (الفواتير فقط بدون الدفعات)
  double get totalInvoices =>
      invoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المبيعات (الفواتير)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // كارت عرض إجمالي المبيعات فقط
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.blueGrey[900],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إجمالي المبيعات:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${totalInvoices.toStringAsFixed(2)} ج',
                    style: const TextStyle(fontSize: 18, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: invoices.isEmpty
                ? const Center(child: Text("لا توجد فواتير مبيعات مسجلة"))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final inv = invoices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.blue),
                    title: Text('عميل: ${inv.clientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('التاريخ: ${DateFormat('yyyy/MM/dd').format(inv.date)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${inv.totalAmount.toStringAsFixed(2)} ج',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('تأكيد حذف الفاتورة'),
                                content: Text('هل تريد حذف فاتورة ${inv.clientName}؟\nملحوظة: هذا لن يؤثر على مديونية العميل المسجلة مسبقاً.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              invoices.removeAt(index);
                              await StorageService.saveInvoices(invoices);
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    // شلنا هنا سجل الدفعات بناءً على طلبك
                    onTap: null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}