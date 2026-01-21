class ClientTransaction {
  String clientName;
  String type; // invoice / return / payment
  double amount;
  DateTime date;

  ClientTransaction({
    required this.clientName,
    required this.type,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory ClientTransaction.fromMap(Map<String, dynamic> map) {
    return ClientTransaction(
      clientName: map['clientName'],
      type: map['type'],
      amount: map['amount']?.toDouble() ?? 0,
      date: DateTime.parse(map['date']),
    );
  }
}
