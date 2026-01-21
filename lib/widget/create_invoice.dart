import 'package:al_farouq_factory/model/client_model.dart';
import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:al_farouq_factory/ui/inventory/inventory_item.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/ui/invoice/invoice_item.dart';
import 'package:al_farouq_factory/ui/invoice/invoice_methods.dart';
import 'package:al_farouq_factory/ui/invoice/invoice_screen_pdf.dart';
import 'package:flutter/material.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Client client;
  const CreateInvoiceScreen({super.key, required this.client});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  List<InventoryItem> inventory = [];
  List<InvoiceItem> items = [];
  double clientDebt = 0;

  @override
  void initState() {
    super.initState();
    loadInventory();
    loadClientDebt();
  }

  Future<void> loadInventory() async {
    inventory = await StorageService.getInventory();
    setState(() {});
  }

  Future<void> loadClientDebt() async {
    // جلب الدين من التخزين مباشرة لضمان الدقة
    clientDebt = await StorageService.getClientDebt(widget.client.name);
    setState(() {});
  }

  double get total => items.fold(0, (sum, e) => sum + e.total);

  void addItem(InventoryItem inv, int qty, double price) {
    setState(() {
      items.add(InvoiceItem(itemName: inv.name, quantity: qty, price: price));
    });
  }

  Future<void> saveInvoice({required double paidAmount, bool isReturn = false}) async {
    if (items.isEmpty) return;

    final double invoiceTotal = total;

    // حفظ الفاتورة في السجل العام للفواتير
    await InvoiceService.createInvoice(
      client: widget.client,
      items: items,
      isReturn: isReturn,
    );

    if (isReturn) {
      // --- في حالة المرتجع ---
      // invoiceTotal: هو إجمالي قيمة البضاعة اللي رجعت
      // paidAmount: هو لو أنت طلعت فلوس كاش من جيبك للعميل (غالباً هتكون 0 لو هتخصم من دينه)
      await StorageService.registerInvoiceReturn(
        clientName: widget.client.name,
        returnTotalValue: invoiceTotal, // دي اللي هتتخصم من مديونيته
        cashReturnedToClient: paidAmount, // دي اللي هتسمع في المصاريف لو دفعتله كاش
        note: 'مرتجع أصناف من العميل ${widget.client.name}',
      );
    } else {
      // --- في حالة البيع ---
      // invoiceTotal هو إجمالي الفاتورة
      // paidAmount هو اللي دفعه كاش (يسمع في الدخل)
      // المتبقي (remainingDebt) هو اللي هيزيد على مديونيته
      final double remainingDebt = (invoiceTotal - paidAmount).clamp(0.0, double.infinity);

      await StorageService.registerInvoicePayment(
        clientName: widget.client.name,
        paidAmount: paidAmount,   // الفلوس اللي مسكتها في إيدك
        debtAmount: remainingDebt, // الشكك اللي هيزيد عليه
        note: 'فاتورة مبيعات للعميل ${widget.client.name}',
      );
    }

    // تحديث البيانات في الشاشة
    await loadClientDebt();
    setState(() {
      items.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت العملية بنجاح وتحديث الحسابات')),
    );
  }

  // ... باقي الدوال (showPaymentDialog, showAddItemDialog, printInvoicePdf) تبقى كما هي بدون تغيير
  // سأضع الـ build لضمان اكتمال الصورة لديك

  Future<void> showPaymentDialog({bool isReturn = false}) async {
    final controller = TextEditingController(text: isReturn ? '0' : total.toStringAsFixed(2));

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isReturn ? 'المبلغ المسترد نقداً للعميل' : 'المبلغ المدفوع نقداً من العميل'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'المبلغ المستلم/المدفوع كاش'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final paid = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context);
              saveInvoice(paidAmount: paid, isReturn: isReturn);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void showAddItemDialog(InventoryItem inv) {
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: inv.sellPrice.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إضافة ${inv.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? inv.sellPrice;
              if (qty > 0) {
                addItem(inv, qty, price);
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> printInvoicePdf() async {
    if (items.isEmpty) return;
    final invoice = Invoice(
      invoiceNumber: DateTime.now().millisecondsSinceEpoch,
      clientName: widget.client.name,
      date: DateTime.now(),
      items: List.from(items),

    );
    await InvoicePdfService.generate(invoice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('فاتورة: ${widget.client.name}'),
        actions: [

          IconButton(icon: const Icon(Icons.save), onPressed: () => showPaymentDialog(isReturn: false)),

        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: Colors.blue.shade50,
              child: ListTile(
                title: const Text('مديونية العميل الحالية', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('${clientDebt.toStringAsFixed(2)} جنيه',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ),
          ),
          Expanded(
            child: inventory.isEmpty
                ? const Center(child: Text('لا توجد أصناف في المخزون'))
                : ListView.builder(
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final inv = inventory[index];
                return ListTile(
                  title: Text(inv.name),
                  subtitle: Text('المتوفر: ${inv.quantity} | السعر: ${inv.sellPrice}'),
                  trailing: IconButton(icon: const Icon(Icons.add), onPressed: () => showAddItemDialog(inv)),
                );
              },
            ),
          ),
          if (items.isNotEmpty)
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إجمالي الفاتورة الحالية: ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  ...items.map((e) => Text('${e.itemName} : ${e.quantity} × ${e.price}')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}