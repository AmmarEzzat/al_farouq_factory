import 'package:flutter/material.dart';
import 'package:al_farouq_factory/model/client_model.dart';
import 'package:al_farouq_factory/ui/Customer_Screen/client_details_screen.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';

class CustomersScreen extends StatefulWidget {
  static const String routeName = 'CustomersScreen';

  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Client> clientList = [];
  List<Client> filteredList = [];
  Map<String, double> clientDebts = {};
  Map<String, int> clientOperationsCount = {};

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  // تحديث البيانات عند فتح الشاشة أو العودة من صفحة التفاصيل
  Future<void> loadClients() async {
    final list = await StorageService.getClients();

    Map<String, double> debts = {};
    Map<String, int> counts = {};

    for (var client in list) {
      // جلب المديونية الحالية
      debts[client.name] = await StorageService.getClientDebt(client.name);

      // جلب عدد العمليات المسجلة (دفعات + مرتجعات) لظهورها في القائمة بره
      final history = await StorageService.getClientPayments(client.name);
      counts[client.name] = history.length;
    }

    if (mounted) {
      setState(() {
        clientList = list;
        filteredList = List.from(clientList);
        clientDebts = debts;
        clientOperationsCount = counts;
      });
    }
  }

  Future<void> saveClients() async {
    await StorageService.saveClients(clientList);
  }

  void addClientDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة عميل جديد'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "اسم العميل"),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                clientList.add(Client(name: name));
                await StorageService.setClientDebt(name, 0);
                await saveClients();
                Navigator.pop(context);
                loadClients();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void deleteClient(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف عميل'),
        content: const Text('هل أنت متأكد؟ سيتم حذف بيانات العميل ومديونيته تماماً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final client = clientList[index];
      clientList.removeAt(index);
      await StorageService.setClientDebt(client.name, 0);
      await saveClients();
      loadClients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة العملاء'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ClientSearchDelegate(clientList),
              ).then((_) => loadClients());
            },
          )
        ],
      ),
      body: filteredList.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا يوجد عملاء مضافين حالياً', style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredList.length,
        separatorBuilder: (_, __) => const Divider(indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final client = filteredList[index];
          final debt = clientDebts[client.name] ?? 0;
          final opsCount = clientOperationsCount[client.name] ?? 0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                client.name.isNotEmpty ? client.name.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              "المديونية: ${debt.toStringAsFixed(2)} ج | العمليات: $opsCount",
              style: TextStyle(
                color: debt > 0 ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => deleteClient(clientList.indexOf(client)),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientDetailsScreen(client: client),
                ),
              ).then((_) => loadClients());
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addClientDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ====== Search Delegate ======
class ClientSearchDelegate extends SearchDelegate<Client?> {
  final List<Client> clients;
  ClientSearchDelegate(this.clients);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = clients.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, index) {
        final client = results[index];
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(client.name),
          onTap: () {
            close(context, client);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClientDetailsScreen(client: client),
              ),
            );
          },
        );
      },
    );
  }
}