class Expense {
  final String id;
  final double amount;
  final String reason;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.reason,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'reason': reason,
    'date': date.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'],
      date: DateTime.parse(map['date']),
    );
  }
}
