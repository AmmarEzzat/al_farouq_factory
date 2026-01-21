class EmployeeDeduction {
  final String id;
  final String employeeId;
  final double amount;
  final String reason;
  final DateTime date;

  EmployeeDeduction({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.reason,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'employeeId': employeeId,
    'amount': amount,
    'reason': reason,
    'date': date.toIso8601String(),
  };

  factory EmployeeDeduction.fromMap(Map<String, dynamic> map) {
    return EmployeeDeduction(
      id: map['id'],
      employeeId: map['employeeId'],
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}