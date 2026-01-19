class Client {
  String name;

  Client({required this.name});

  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(name: map['name']);
  }
}
