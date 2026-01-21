import 'dart:convert';
import 'package:al_farouq_factory/model/client_model.dart';
import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:al_farouq_factory/ui/employee/employee.dart';
import 'package:al_farouq_factory/ui/employee/employee_payment.dart';
import 'package:al_farouq_factory/ui/inventory/inventory_item.dart';
import 'package:al_farouq_factory/widget/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // ================= Keys =================
  static const String inventoryKey = 'inventory';
  static const String clientsKey = 'clients';
  static const String invoicesKey = 'invoices';
  static const String employeesKey = 'employees';
  static const String employeePaymentsKey = 'employee_payments';
  static const String debtKeyPrefix = 'client_debt_';
  static const String ownerPasswordKey = 'owner_password';
  static const String transactionsKey = 'transactions';

  // ================= Inventory =================
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

  // ================= Clients =================
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

  // ================= Invoices =================
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

  // ================= Client Debt =================
  static Future<double> getClientDebt(String clientName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$debtKeyPrefix$clientName') ?? 0.0;
  }

  static Future<void> setClientDebt(String clientName, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$debtKeyPrefix$clientName', amount);
  }

  // ================= Owner Password =================
  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ownerPasswordKey, password);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ownerPasswordKey);
  }

  // ================= Transactions =================
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

  // ================= Invoice Accounting =================
  static Future<void> registerInvoicePayment({
    required String clientName,
    required double paidAmount,
    required double debtAmount,
  }) async {
    final currentDebt = await getClientDebt(clientName);
    await setClientDebt(clientName, currentDebt + debtAmount);

    if (paidAmount > 0) {
      await addTransaction(
        FinancialTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: paidAmount,
          date: DateTime.now(),
          type: TransactionType.income,
          note: 'دخل نقدي من فاتورة - $clientName',
        ),
      );
    }
  }

  static Future<void> registerInvoiceReturn({
    required String clientName,
    required double paidReturn,
    required double debtReturn,
  }) async {
    final currentDebt = await getClientDebt(clientName);
    final newDebt = (currentDebt - debtReturn).clamp(0.0, double.infinity);
    await setClientDebt(clientName, newDebt);

    if (paidReturn > 0) {
      await addTransaction(
        FinancialTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: paidReturn,
          date: DateTime.now(),
          type: TransactionType.expense,
          note: 'مرتجع نقدي - $clientName',
        ),
      );
    }
  }

  // ================= Employees =================
  static Future<List<Employee>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(employeesKey) ?? [];
    return data.map((e) => Employee.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> saveEmployees(List<Employee> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      employeesKey,
      list.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  // ================= Employee Payments =================
  static Future<void> payEmployee({
    required Employee employee,
    required double amount,
    String? note,
  }) async {
    if (amount <= 0) return;

    // 1️⃣ مصروف من الدخل
    await addTransaction(
      FinancialTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        note: note ?? 'قبض عامل: ${employee.name}',
      ),
    );

    // 2️⃣ سجل قبض العامل
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(employeePaymentsKey) ?? [];

    list.add(jsonEncode(
      EmployeePayment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: employee.id,
        amount: amount,
        date: DateTime.now(),
        note: note ?? '',
      ).toMap(),
    ));

    await prefs.setStringList(employeePaymentsKey, list);
  }

  static Future<List<EmployeePayment>> getEmployeePayments(
      String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(employeePaymentsKey) ?? [];

    return data
        .map((e) => EmployeePayment.fromMap(jsonDecode(e)))
        .where((e) => e.employeeId == employeeId)
        .toList();
  }
}
