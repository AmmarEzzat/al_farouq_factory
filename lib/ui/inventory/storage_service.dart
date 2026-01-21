import 'dart:convert';
import 'package:al_farouq_factory/client_payment.dart';
import 'package:al_farouq_factory/model/client_model.dart';
import 'package:al_farouq_factory/model/invoice_model.dart';
import 'package:al_farouq_factory/model/product_model.dart';
import 'package:al_farouq_factory/ui/employee/employee.dart';
import 'package:al_farouq_factory/ui/employee/employee_payment.dart';
import 'package:al_farouq_factory/ui/employee/employee_deduction.dart';
import 'package:al_farouq_factory/ui/inventory/inventory_item.dart';
import 'package:al_farouq_factory/widget/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String inventoryKey = 'inventory';
  static const String clientsKey = 'clients';
  static const String invoicesKey = 'invoices';
  static const String employeesKey = 'employees';
  static const String employeePaymentsKey = 'employee_payments';
  static const String employeeDeductionsKey = 'employee_deductions';
  static const String clientPaymentsKey = 'client_payments';
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

  // ================= Client Payments (سجل حركات العميل) =================
  static Future<void> addClientPayment(ClientPayment payment) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(clientPaymentsKey) ?? [];
    list.add(jsonEncode(payment.toMap()));
    await prefs.setStringList(clientPaymentsKey, list);
  }

  static Future<List<ClientPayment>> getClientPayments(String clientName) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(clientPaymentsKey) ?? [];
    return data
        .map((e) => ClientPayment.fromMap(jsonDecode(e)))
        .where((p) => p.clientName == clientName)
        .toList();
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

  static Future<void> deleteClientPayment(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(clientPaymentsKey) ?? [];
    list.removeWhere((e) => ClientPayment.fromMap(jsonDecode(e)).id == id);
    await prefs.setStringList(clientPaymentsKey, list);
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

  // ================= Transactions (الخزنة / الدخل الشهري) =================
  static Future<List<FinancialTransaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(transactionsKey) ?? [];
    return data.map((e) => FinancialTransaction.fromMap(jsonDecode(e))).toList();
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

  // ================= Invoice & Returns (تعديل الحسابات المطور) =================

  /// تسجيل دفع فاتورة: يسجل الكاش فقط في الخزنة، ويزيد المديونية بالباقي
  static Future<void> registerInvoicePayment({
    required String clientName,
    required double paidAmount, // الفلوس اللي مسكتها في ايدك
    required double debtAmount, // الباقي (الشكك)
    String? note,
  }) async {
    // 1. تحديث المديونية (زيادة الشكك)
    final currentDebt = await getClientDebt(clientName);
    await setClientDebt(clientName, currentDebt + debtAmount);

    // 2. تسجيل الفلوس "اللي في إيدك" فقط في الخزنة (الدخل الشهري) وسجل العميل
    if (paidAmount > 0) {
      await addTransaction(FinancialTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: paidAmount,
        date: DateTime.now(),
        type: TransactionType.income,
        note: note ?? 'دخل نقدي من فاتورة - $clientName',
      ));

      await addClientPayment(ClientPayment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientName: clientName,
        amount: paidAmount, // بالموجب لأنها دفعة للداخل
        date: DateTime.now(),
        note: note ?? 'دفعة من فاتورة مبيعات',
      ));
    }
  }

  /// تسجيل المرتجع: يخصم من مديونية العميل مباشرة ويوثق الحركة في سجله
  static Future<void> registerInvoiceReturn({
    required String clientName,
    required double returnTotalValue, // إجمالي قيمة البضاعة المرجعة (ثمنها)
    required double cashReturnedToClient, // لو طلعت كاش من الدرج للعميل
    String? note,
  }) async {
    // 1. خصم قيمة المرتجع من مديونية العميل مباشرة
    final currentDebt = await getClientDebt(clientName);
    final newDebt = (currentDebt - returnTotalValue).clamp(0.0, double.infinity);
    await setClientDebt(clientName, newDebt);

    // 2. تسجيل المرتجع في سجل مدفوعات العميل (بالسالب عشان يظهر كخصم في كشف حسابه)
    await addClientPayment(ClientPayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientName: clientName,
      amount: -returnTotalValue, // قيمة سالبة لتمييز المرتجع
      date: DateTime.now(),
      note: note ?? 'مرتجع بضاعة (خصم من المديونية)',
    ));

    // 3. لو تم دفع مبلغ نقدي للعميل مقابل المرتجع، يسجل كمصروف من الخزنة
    if (cashReturnedToClient > 0) {
      await addTransaction(FinancialTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: cashReturnedToClient,
        date: DateTime.now(),
        type: TransactionType.expense,
        note: 'مرتجع نقدي للعميل: $clientName',
      ));
    }
  }

  // ================= Employees (نظام العمال) =================
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

  static Future<void> addProductionToEmployee(String employeeId, ProductionTask task) async {
    final list = await getEmployees();
    final index = list.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      list[index].pendingTasks.add(task);
      await saveEmployees(list);
    }
  }

  static Future<void> payEmployee({
    required Employee employee,
    required double amount,
    String? note,
  }) async {
    if (amount <= 0) return;

    final allEmployees = await getEmployees();
    final index = allEmployees.indexWhere((e) => e.id == employee.id);

    if (index != -1) {
      final emp = allEmployees[index];
      double totalDeductionsSettled = emp.totalDeductions;

      emp.paymentHistory.add(PaymentRecord(
        amountPaid: amount,
        deductionsSettled: totalDeductionsSettled,
        totalBeforeDeductions: amount + totalDeductionsSettled,
        date: DateTime.now(),
      ));

      emp.completedTasks.addAll(emp.pendingTasks);
      emp.pendingTasks.clear();
      emp.completedDeductions.addAll(emp.deductions);
      emp.deductions.clear();

      await saveEmployees(allEmployees);

      await addTransaction(FinancialTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        note: note ?? 'صرف مستحقات عامل: ${emp.name}',
      ));
    }

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(employeePaymentsKey) ?? [];
    list.add(jsonEncode(EmployeePayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: employee.id,
      amount: amount,
      date: DateTime.now(),
      note: note ?? 'تسوية دورة إنتاج',
    ).toMap()));
    await prefs.setStringList(employeePaymentsKey, list);
  }

  static Future<List<EmployeePayment>> getEmployeePayments(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(employeePaymentsKey) ?? [];
    return data
        .map((e) => EmployeePayment.fromMap(jsonDecode(e)))
        .where((e) => e.employeeId == employeeId)
        .toList();
  }

  static Future<void> addEmployeeDeduction({
    required Employee employee,
    required double amount,
    required String reason,
  }) async {
    if (amount <= 0) return;
    final allEmployees = await getEmployees();
    final index = allEmployees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      allEmployees[index].deductions.add(EmployeeDeduction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: employee.id,
        amount: amount,
        reason: reason,
        date: DateTime.now(),
      ));
      await saveEmployees(allEmployees);
    }
  }

  static Future<List<EmployeeDeduction>> getEmployeeDeductions(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(employeeDeductionsKey) ?? [];
    return data
        .map((e) => EmployeeDeduction.fromMap(jsonDecode(e)))
        .where((e) => e.employeeId == employeeId)
        .toList();
  }

  // ================= Factory Expenses =================
  static Future<void> addFactoryExpense({
    required double amount,
    required String reason,
  }) async {
    if (amount <= 0) return;
    await addTransaction(FinancialTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.expense,
      note: reason,
    ));
  }

  static Future<List<FinancialTransaction>> getFactoryExpenses() async {
    final allTx = await getTransactions();
    return allTx.where((tx) => tx.type == TransactionType.expense).toList();
  }

  static const String productsKey = 'products_key';
// جلب المنتجات من المخزن
  // في ملف StorageService.dart عدل الدالتين دول بس:

  static Future<List<InventoryItem>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    // خليه يقرأ من inventoryKey اللي صفحة المخزن بتسجل فيه
    final data = prefs.getStringList(inventoryKey) ?? [];
    return data.map((e) => InventoryItem.fromMap(jsonDecode(e))).toList();
  }

  static Future<void> saveProducts(List<InventoryItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      inventoryKey, // لازم يسيف في نفس المكان
      list.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }
// حفظ المنتجات في المخزن

}