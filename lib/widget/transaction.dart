enum TransactionType { income, expense }

class FinancialTransaction {
  final String id;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String note;

  FinancialTransaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type.index,
    'note': note,
  };

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: TransactionType.values[map['type']],
      note: map['note'],
    );

  }

}
