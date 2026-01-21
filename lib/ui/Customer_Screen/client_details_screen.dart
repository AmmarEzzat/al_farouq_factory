import 'dart:io';
import 'package:al_farouq_factory/client_payment.dart';
import 'package:al_farouq_factory/ui/inventory/inventory_item.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/ui/invoice/invoice_screen_pdf.dart';
import 'package:al_farouq_factory/ui/invoice_card.dart';
import 'package:al_farouq_factory/widget/create_invoice.dart';
import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:flutter/material.dart';
import 'package:al_farouq_factory/model/client_model.dart';
import 'package:intl/intl.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;
  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  List<ClientPayment> history = [];
  List<Invoice> invoiceList = [];
  List<InventoryItem> availableProducts = [];
  double clientDebt = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadClientData();
  }

  Future<void> loadClientData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    clientDebt = await StorageService.getClientDebt(widget.client.name);
    final allHistory = await StorageService.getClientPayments(widget.client.name);
    final allInvoices = await StorageService.getInvoices();
    availableProducts = await StorageService.getInventory();

    setState(() {
      history = allHistory.reversed.toList();
      invoiceList = allInvoices.where((i) => i.clientName == widget.client.name).toList();
      isLoading = false;
    });
  }

  // دالة الحذف مع التأكيد
  void confirmDeletePayment(ClientPayment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: Text("هل أنت متأكد من حذف حركة (${payment.note})؟\nسيتم إعادة ضبط مديونية العميل تلقائياً."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          TextButton(
            onPressed: () async {
              await StorageService.deleteClientPayment(payment.id);
              if (!mounted) return;
              Navigator.pop(ctx);
              loadClientData(); // تحديث المديونية والسجل
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف الحركة وتحديث المديونية")));
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showPaymentDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('استلام مبلغ نقدى'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'المبلغ جنيهاً', suffixText: 'ج'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                await StorageService.registerInvoicePayment(
                  clientName: widget.client.name,
                  paidAmount: amount,
                  debtAmount: -amount,
                  note: "قبض كاش (مبلغ مستلم)",
                );
                Navigator.pop(context);
                loadClientData();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void showSmartReturnDialog() async {
    final products = await StorageService.getInventory();
    if (products.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("المخزن فارغ!")));
      return;
    }

    InventoryItem? selectedProduct;
    final qtyController = TextEditingController();
    final priceController = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('مرتجع بضاعة للمخزن'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<InventoryItem>(
                  isExpanded: true,
                  hint: const Text("اختر الصنف"),
                  value: selectedProduct,
                  items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedProduct = val;
                      priceController.text = val?.sellPrice.toString() ?? "";
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الوحدة')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  final double qty = double.tryParse(qtyController.text) ?? 0;
                  final double price = double.tryParse(priceController.text) ?? 0;
                  if (selectedProduct != null && qty > 0) {
                    await StorageService.registerInvoiceReturn(
                      clientName: widget.client.name,
                      returnTotalValue: qty * price,
                      cashReturnedToClient: 0,
                      note: "مرتجع: ${selectedProduct!.name} (عدد ${qty.toInt()})",
                    );
                    final allInventory = await StorageService.getInventory();
                    for (var item in allInventory) {
                      if (item.name == selectedProduct!.name) item.quantity += qty.toInt();
                    }
                    await StorageService.saveInventory(allInventory);
                    if (!mounted) return;
                    Navigator.pop(context);
                    loadClientData();
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.client.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: "كشف الحساب", icon: Icon(Icons.assignment)),
              Tab(text: "الفواتير (PDF)", icon: Icon(Icons.picture_as_pdf)),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildHistoryTab(),
            _buildInvoicesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildBalanceCard(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateInvoiceScreen(client: widget.client)));
                        loadClientData();
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text("سحب بضاعة"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: showSmartReturnDialog,
                      icon: const Icon(Icons.assignment_return, size: 18),
                      label: const Text("مرتجع صنف"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: showPaymentDialog,
                icon: const Icon(Icons.payments),
                label: const Text("تسجيل مبلغ مستلم (كاش)"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45)
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: history.isEmpty
              ? const Center(child: Text("السجل فارغ"))
              : ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final isReturn = item.amount < 0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: Icon(isReturn ? Icons.assignment_return : Icons.add_circle, color: isReturn ? Colors.orange : Colors.green),
                  title: Text(item.note, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('yyyy/MM/dd - hh:mm a').format(item.date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${item.amount.abs().toStringAsFixed(2)} ج",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      // زرار الحذف الجديد
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => confirmDeletePayment(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesTab() {
    return invoiceList.isEmpty
        ? const Center(child: Text("لا توجد فواتير مطبوعة"))
        : ListView.builder(
      itemCount: invoiceList.length,
      itemBuilder: (context, index) => InvoiceCard(
        invoice: invoiceList[index],
        onTap: () => InvoicePdfService.generate(invoiceList[index]),
        onDelete: () async {
          invoiceList.removeAt(index);
          await StorageService.saveInvoices(invoiceList);
          loadClientData();
        },
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          const Text("المديونية الحالية", style: TextStyle(color: Colors.white70)),
          Text("${clientDebt.toStringAsFixed(2)} ج", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}