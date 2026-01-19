import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/widget/transaction.dart';
import 'package:flutter/material.dart';

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
          final monthTx = txs.where((t) =>
          t.date.month == DateTime.now().month &&
              t.date.year == DateTime.now().year
          ).toList();

          final income = monthTx
              .where((e) => e.type == TransactionType.income)
              .fold(0.0, (s, e) => s + e.amount);

          final expense = monthTx
              .where((e) => e.type == TransactionType.expense)
              .fold(0.0, (s, e) => s + e.amount);

          return Column(
            children: [
              ListTile(title: Text('إجمالي الدخل: $income')),
              ListTile(title: Text('إجمالي المصروفات: $expense')),
              ListTile(title: Text('الصافي: ${income - expense}')),

              Expanded(
                child: ListView.builder(
                  itemCount: monthTx.length,
                  itemBuilder: (_, i) {
                    final t = monthTx[i];
                    return ListTile(
                      title: Text(t.note),
                      subtitle: Text(t.date.toString().split(' ')[0]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.type == TransactionType.income
                                ? '+${t.amount}'
                                : '-${t.amount}',
                            style: TextStyle(
                              color: t.type == TransactionType.income
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'حذف العملية',
                            onPressed: () async {
                              await StorageService.deleteTransaction(t.id);
                              setState(() {}); // إعادة بناء الشاشة بعد الحذف
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              IconButton(
                icon: const Icon(Icons.lock),
                tooltip: 'تغيير كلمة المرور',
                onPressed: _changePassword,
              ),
            ],
          );
        },
      ),
    );
  }
}
