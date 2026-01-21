import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/widget/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyIncomeScreen extends StatefulWidget {
  @override
  State<MonthlyIncomeScreen> createState() => _MonthlyIncomeScreenState();
}

class _MonthlyIncomeScreenState extends State<MonthlyIncomeScreen> {
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    _checkPassword();
  }

  Future<void> _checkPassword() async {
    final storedPass = await StorageService.getPassword() ?? '1234';
    final controller = TextEditingController();

    final authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('ادخل كلمة المرور'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'كلمة المرور'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text == storedPass) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('كلمة المرور غير صحيحة')),
                );
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    ) ?? false;

    setState(() {
      _authorized = authorized;
    });
  }

  Future<void> _changePassword() async {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final storedPass = await StorageService.getPassword() ?? '1234';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور القديمة'),
            ),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (oldPassController.text == storedPass && newPassController.text.isNotEmpty) {
                await StorageService.setPassword(newPassController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث كلمة المرور')),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('كلمة المرور القديمة غير صحيحة')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorized) {
      return const Scaffold(
        body: Center(child: Text('يرجى إدخال كلمة المرور')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الدخل الشهري')),
      body: FutureBuilder(
        future: StorageService.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final txs = snapshot.data as List<FinancialTransaction>;

          final monthTx = txs.where((t) {
            final isCurrentMonth = t.date.month == DateTime.now().month && t.date.year == DateTime.now().year;

            // التعديل الجوهري هنا:
            // نستبعد فقط "الفاتورة" و "المرتجع" لأنهم عمليات حسابية (مديونية)
            // ونسمح بظهور "قبض كاش" وأي عملية يدوية أخرى لأنها أموال فعلية
            final isNonCashAction = t.note.contains("فاتورة") ||
                t.note.contains("مرتجع");

            return isCurrentMonth && !isNonCashAction;
          }).toList();

          final income = monthTx
              .where((e) => e.type == TransactionType.income)
              .fold(0.0, (s, e) => s + e.amount);

          final expense = monthTx
              .where((e) => e.type == TransactionType.expense)
              .fold(0.0, (s, e) => s + e.amount);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(10),
                color: Colors.blueGrey[900],
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      // غيرت الاسم لـ "إجمالي الدخل النقدي" ليكون أدق
                      _buildSummaryRow('إجمالي الإيراد الكاش:', income, Colors.greenAccent),
                      _buildSummaryRow('إجمالي المصروفات:', expense, Colors.redAccent),
                      const Divider(color: Colors.white24),
                      _buildSummaryRow('صافي الخزينة:', income - expense, Colors.white, isBold: true),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: monthTx.isEmpty
                    ? const Center(child: Text("لا توجد عمليات مسجلة لهذا الشهر"))
                    : ListView.builder(
                  itemCount: monthTx.length,
                  itemBuilder: (_, i) {
                    final t = monthTx[i];
                    return ListTile(
                      // تمييز عمليات قبض الكاش بلون مختلف قليلاً إذا أردت
                      title: Text(t.note),
                      subtitle: Text(DateFormat('yyyy/MM/dd').format(t.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.type == TransactionType.income
                                ? '+${t.amount}'
                                : '-${t.amount}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: t.type == TransactionType.income
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              await StorageService.deleteTransaction(t.id);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IconButton(
                  icon: const Icon(Icons.lock_open, color: Colors.grey),
                  tooltip: 'تغيير كلمة المرور',
                  onPressed: _changePassword,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            '${value.toStringAsFixed(2)} ج',
            style: TextStyle(
                color: color,
                fontSize: isBold ? 18 : 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ],
      ),
    );
  }
}