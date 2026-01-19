import 'dart:convert';
import 'package:al_farouq_factory/model/client_model.dart';
import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:al_farouq_factory/ui/inventory/inventory_item.dart';
import 'package:al_farouq_factory/widget/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String inventoryKey = 'inventory';
  static const String clientsKey = 'clients';
  static const String invoicesKey = 'invoices';
  static const String debtKeyPrefix = 'client_debt_';
  static const String ownerPasswordKey = 'owner_password';
  static const String transactionsKey = 'transactions';

  // ====== Inventory ======
  static Future<List<InventoryItem>> getInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(inventoryKey) ?? [];
    return data.map((e) => InventoryItem.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> saveInventory(List<InventoryItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      inventoryKey,
      list.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  // ====== Clients ======
  static Future<List<Client>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(clientsKey) ?? [];
    return data.map((e) => Client.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> saveClients(List<Client> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      clientsKey,
      list.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  // ====== Invoices ======
  static Future<List<Invoice>> getInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(invoicesKey) ?? [];
    return data.map((e) => Invoice.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> saveInvoices(List<Invoice> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      invoicesKey,
      list.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  // ====== Client Debt ======
  static Future<double> getClientDebt(String clientName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$debtKeyPrefix$clientName') ?? 0.0;
  }

  static Future<void> setClientDebt(String clientName, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$debtKeyPrefix$clientName', amount);
  }

  // ====== Owner Password ======
  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ownerPasswordKey, password);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ownerPasswordKey);
  }

  // ====== Transactions ======
  static Future<List<FinancialTransaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(transactionsKey) ?? [];
    return data
        .map((e) => FinancialTransaction.fromMap(jsonDecode(e)))
        .toList();
  }

  static Future<void> addTransaction(FinancialTransaction tx) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(transactionsKey) ?? [];
    list.add(jsonEncode(tx.toMap()));
    await prefs.setStringList(transactionsKey, list);
  }

  static Future<void> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(transactionsKey) ?? [];
    list.removeWhere((e) => FinancialTransaction.fromMap(jsonDecode(e)).id == id);
    await prefs.setStringList(transactionsKey, list);
  }

  // ====== تسجيل مالي صحيح للفاتورة ======
  static Future<void> registerInvoicePayment({
    required String clientName,
    required double paidAmount, // المبلغ اللي اندفع ايد بإيد
    required double debtAmount, // المبلغ اللي "اتسحب" عالحساب (باقي الفاتورة)
    String? note,
  }) async {
    // 1. تحديث الدين: نأخذ القديم ونزود عليه "فقط" الجزء المتبقي
    final currentDebt = await getClientDebt(clientName);
    await setClientDebt(clientName, currentDebt + debtAmount);

    // 2. تسجيل الدخل: نسجل "فقط" الكاش الفعلي
    if (paidAmount > 0) {
      final tx = FinancialTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: paidAmount,
        date: DateTime.now(),
        type: TransactionType.income,
        note: note ?? 'دخل نقدي من فاتورة - العميل: $clientName',
      );
      await addTransaction(tx);
    }
  }

  // ====== تسجيل مالي صحيح للمرتجع ======
  static Future<void> registerInvoiceReturn({
    required String clientName,
    required double paidReturn, // مبلغ رجعته للعميل من جيبك (كاش)
    required double debtReturn, // مبلغ هيتم مسحه من مديونية العميل
    String? note,
  }) async {
    // 1. تقليل الدين: نأخذ القديم ونطرح منه مبلغ المرتجع اللي كان "عالحساب"
    final currentDebt = await getClientDebt(clientName);
    final newDebt = (currentDebt - debtReturn).clamp(0.0, double.infinity);
    await setClientDebt(clientName, newDebt);

    // 2. تسجيل المصروف: إذا طلعت فلوس كاش للعميل، نسجلها كخرج (Expense)
    if (paidReturn > 0) {
      final tx = FinancialTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: paidReturn,
        date: DateTime.now(),
        type: TransactionType.expense,
        note: note ?? 'مرتجع نقدي للعميل: $clientName',
      );
      await addTransaction(tx);
    }
  }
}