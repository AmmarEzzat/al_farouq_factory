class ClientPayment {
  final String id;
  final String clientName;
  final double amount;
  final DateTime date;
  final String note;

  ClientPayment({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'clientName': clientName,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory ClientPayment.fromMap(Map<String, dynamic> map) {
    return ClientPayment(
      id: map['id'],
      clientName: map['clientName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }
}
