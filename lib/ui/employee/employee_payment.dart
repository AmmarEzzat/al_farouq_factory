class EmployeePayment {
  final String id;
  final String employeeId;
  final double amount;
  final DateTime date;
  final String note;

  EmployeePayment({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory EmployeePayment.fromMap(Map<String, dynamic> map) {
    return EmployeePayment(
      id: map['id'],
      employeeId: map['employeeId'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }
}