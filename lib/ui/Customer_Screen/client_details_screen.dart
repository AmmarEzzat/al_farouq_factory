import 'dart:convert';
import 'dart:io';

import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/ui/invoice/invoice_screen_pdf.dart';
import 'package:al_farouq_factory/ui/invoice_card.dart';
import 'package:al_farouq_factory/widget/create_invoice.dart';
import 'package:al_farouq_factory/widget/transaction.dart';
import 'package:flutter/material.dart';
import 'package:al_farouq_factory/model/client_model.dart';
import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:path_provider/path_provider.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;
  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  List<Invoice> invoiceList = [];
  double clientDebt = 0;

  @override
  void initState() {
    super.initState();
    loadClientData();
  }

  Future<void> loadClientData() async {
    final allInvoices = await StorageService.getInvoices();
    invoiceList = allInvoices
        .where((i) => i.clientName == widget.client.name)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    clientDebt = await StorageService.getClientDebt(widget.client.name);
    setState(() {});
  }

  // ======== تسجيل دفعة ========
  void recordPayment() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل دفعة من العميل'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'المبلغ (الحد الأقصى ${clientDebt.toStringAsFixed(2)})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final payment = double.tryParse(controller.text) ?? 0.0;
              if (payment <= 0 || payment > clientDebt) return;

              // تسجيل الدخل للدفعة
              await StorageService.addTransaction(
                FinancialTransaction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: payment,
                  date: DateTime.now(),
                  type: TransactionType.income,
                  note: 'دفعة من العميل ${widget.client.name}',
                ),
              );

              // تقليل المديونية
              clientDebt -= payment;
              await StorageService.setClientDebt(widget.client.name, clientDebt);

              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('تسجيل الدفعة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              for (final invoice in invoiceList) {
                InvoicePdfService.generate(invoice);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: recordPayment,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'مديونية العميل الحالية: ${clientDebt.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: invoiceList.length,
              itemBuilder: (context, index) {
                final invoice = invoiceList[index];
                return InvoiceCard(
                  invoice: invoice,
                  onTap: () {
                    InvoicePdfService.generate(invoice);
                  },
                  onDelete: () async {
                    setState(() {
                      invoiceList.removeAt(index);
                    });

                    await StorageService.saveInvoices(invoiceList);

                    final dir = await getApplicationDocumentsDirectory();
                    final file = File('${dir.path}/invoice_${invoice.invoiceNumber}.pdf');
                    if (await file.exists()) await file.delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف الفاتورة')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateInvoiceScreen(client: widget.client),
            ),
          );

          if (result != null) loadClientData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
