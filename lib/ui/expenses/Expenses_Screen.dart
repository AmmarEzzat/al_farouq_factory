import 'package:flutter/material.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/widget/transaction.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<FinancialTransaction> expenses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => isLoading = true);
    final list = await StorageService.getFactoryExpenses();
    setState(() {
      // عرض الأحدث أولاً
      expenses = list.reversed.toList();
      isLoading = false;
    });
  }

  // دالة الحذف النهائي
  Future<void> _deleteExpensePermanently(FinancialTransaction tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف النهائي'),
        content: const Text('هل تريد حذف هذا المصروف نهائياً؟ لن يظهر في هذه القائمة مرة أخرى.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // حذف من ملف التخزين (لن ينادى مرة أخرى عند فتح الشاشة)
      await StorageService.deleteTransaction(tx.id);
      _loadExpenses(); // إعادة تحميل القائمة

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحذف النهائي بنجاح')),
        );
      }
    }
  }

  Future<void> _addExpense() async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مصروف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ جنيهاً'),
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'السبب (الملاحظة)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                final reason = reasonController.text.trim();
                Navigator.pop(context, {'amount': amount, 'reason': reason});
              },
              child: const Text('إضافة')),
        ],
      ),
    );

    if (result != null && result['amount'] > 0 && result['reason'].isNotEmpty) {
      await StorageService.addFactoryExpense(
        amount: result['amount'],
        reason: result['reason'],
      );
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصاريف'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addExpense,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
          ? const Center(child: Text('لا توجد مصاريف مسجلة'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final exp = expenses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.money_off, color: Colors.white, size: 20),
              ),
              title: Text(
                '${exp.amount.toStringAsFixed(2)} ج',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${exp.note}\n${DateFormat('yyyy/MM/dd - hh:mm a').format(exp.date)}',
              ),
              // زرار الحذف النهائي
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () => _deleteExpensePermanently(exp),
              ),
            ),
          );
        },
      ),
    );
  }
}