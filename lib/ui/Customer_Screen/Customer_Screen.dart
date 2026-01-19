import 'dart:convert';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:al_farouq_factory/model/client_model.dart';

import 'package:al_farouq_factory/ui/Customer_Screen/client_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  static const String routeName = 'CustomersScreen';

  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Client> clientList = [];

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  Future<void> loadClients() async {
    clientList = await StorageService.getClients();
    setState(() {});
  }

  Future<void> saveClients() async {
    await StorageService.saveClients(clientList);
    setState(() {});
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                clientList.add(Client(name: name));
                saveClients();
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void deleteClient(int index) {
    clientList.removeAt(index);
    saveClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة العملاء'),
        centerTitle: true,
      ),
      body: clientList.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا يوجد عملاء مضافين حالياً',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: clientList.length,
        separatorBuilder: (_, __) => const Divider(indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final client = clientList[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                client.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              client.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("رقم العميل: ${index + 1}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteClient(index),
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addClientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
