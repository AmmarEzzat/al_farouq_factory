import 'package:al_farouq_factory/ui/employee/employee_deduction.dart';

enum EmployeeType {
  fixedSalary,
  production,
}

/// سجل مالي لعملية قبض تمت فعلياً
class PaymentRecord {
  final double amountPaid;           // المبلغ اللي استلمه في إيده فعلاً
  final double deductionsSettled;    // إجمالي الخصومات اللي اتخصمت منه في المرة دي
  final double totalBeforeDeductions; // كان المفروض يقبض كام قبل الخصم
  final DateTime date;

  PaymentRecord({
    required this.amountPaid,
    required this.deductionsSettled,
    required this.totalBeforeDeductions,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'amountPaid': amountPaid,
    'deductionsSettled': deductionsSettled,
    'totalBeforeDeductions': totalBeforeDeductions,
    'date': date.toIso8601String(),
  };

  factory PaymentRecord.fromMap(Map<String, dynamic> map) => PaymentRecord(
    amountPaid: (map['amountPaid'] as num).toDouble(),
    deductionsSettled: (map['deductionsSettled'] as num).toDouble(),
    totalBeforeDeductions: (map['totalBeforeDeductions'] as num).toDouble(),
    date: DateTime.parse(map['date']),
  );
}

/// كلاس تمثيل عملية إنتاج صنف معين
class ProductionTask {
  final String itemName;
  final int quantity;
  final double rate;
  final DateTime date;

  ProductionTask({
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'quantity': quantity,
    'rate': rate,
    'date': date.toIso8601String(),
  };

  factory ProductionTask.fromMap(Map<String, dynamic> map) => ProductionTask(
    itemName: map['itemName'],
    quantity: map['quantity'],
    rate: (map['rate'] as num).toDouble(),
    date: DateTime.parse(map['date']),
  );
}

class Employee {
  String id;
  String name;
  EmployeeType type;
  double salary;

  List<ProductionTask> pendingTasks;
  List<ProductionTask> completedTasks;
  List<EmployeeDeduction> deductions;
  List<EmployeeDeduction> completedDeductions;

  /// [جديد] سجل الدفعات المالية التاريخي
  List<PaymentRecord> paymentHistory;

  Employee({
    required this.id,
    required this.name,
    required this.type,
    this.salary = 0,
    List<ProductionTask>? pendingTasks,
    List<ProductionTask>? completedTasks,
    List<EmployeeDeduction>? deductions,
    List<EmployeeDeduction>? completedDeductions,
    List<PaymentRecord>? paymentHistory,
  })  : pendingTasks = pendingTasks ?? [],
        completedTasks = completedTasks ?? [],
        deductions = deductions ?? [],
        completedDeductions = completedDeductions ?? [],
        paymentHistory = paymentHistory ?? [];

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      type: map['type'] == 'production' ? EmployeeType.production : EmployeeType.fixedSalary,
      salary: (map['salary'] ?? 0).toDouble(),
      pendingTasks: (map['pendingTasks'] as List<dynamic>?)?.map((t) => ProductionTask.fromMap(t)).toList() ?? [],
      completedTasks: (map['completedTasks'] as List<dynamic>?)?.map((t) => ProductionTask.fromMap(t)).toList() ?? [],
      deductions: (map['deductions'] as List<dynamic>?)?.map((d) => EmployeeDeduction.fromMap(d)).toList() ?? [],
      completedDeductions: (map['completedDeductions'] as List<dynamic>?)?.map((d) => EmployeeDeduction.fromMap(d)).toList() ?? [],
      paymentHistory: (map['paymentHistory'] as List<dynamic>?)?.map((p) => PaymentRecord.fromMap(p)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type == EmployeeType.production ? 'production' : 'fixed',
      'salary': salary,
      'pendingTasks': pendingTasks.map((t) => t.toMap()).toList(),
      'completedTasks': completedTasks.map((t) => t.toMap()).toList(),
      'deductions': deductions.map((d) => d.toMap()).toList(),
      'completedDeductions': completedDeductions.map((d) => d.toMap()).toList(),
      'paymentHistory': paymentHistory.map((p) => p.toMap()).toList(),
    };
  }

  // --- الحسابات ---
  double get productionTotal => pendingTasks.fold(0.0, (sum, task) => sum + (task.quantity * task.rate));

  double get baseIncome => type == EmployeeType.production ? productionTotal : salary;

  double get totalDeductions => deductions.fold(0.0, (sum, d) => sum + d.amount);

  double get netEarned => baseIncome - totalDeductions;
}