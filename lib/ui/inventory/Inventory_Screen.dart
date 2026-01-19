

import 'package:al_farouq_factory/ui/inventory/inventory_item.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';

import 'package:flutter/material.dart';



class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem> inventoryList = [];

  @override
  void initState() {
    super.initState();
    loadInventory();
  }

  Future<void> loadInventory() async {
    inventoryList = await StorageService.getInventory();
    setState(() {});
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    inventoryList.add(item);
    await StorageService.saveInventory(inventoryList);
    setState(() {});
  }

  Future<void> editInventoryItem(int index, InventoryItem item) async {
    inventoryList[index] = item;
    await StorageService.saveInventory(inventoryList);
    setState(() {});
  }

  Future<void> deleteInventoryItem(int index) async {
    inventoryList.removeAt(index);
    await StorageService.saveInventory(inventoryList);
    setState(() {});
  }

  Future<void> updateInventoryQuantity(int index, int value) async {
    inventoryList[index].quantity += value;
    if (inventoryList[index].quantity < 0) inventoryList[index].quantity = 0;
    await StorageService.saveInventory(inventoryList);
    setState(() {});
  }

  void showAddDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة صنف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(hintText: "اسم الصنف")),
            TextField(controller: quantityController, decoration: const InputDecoration(hintText: "الكمية"), keyboardType: TextInputType.number),
            TextField(controller: unitController, decoration: const InputDecoration(hintText: "الوحدة")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final qty = int.tryParse(quantityController.text) ?? 0;
              final unit = unitController.text.trim();
              if (name.isNotEmpty && qty > 0 && unit.isNotEmpty) {
                addInventoryItem(InventoryItem(name: name, quantity: qty, unit: unit));
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزن'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: inventoryList.isEmpty
          ? const Center(child: Text('لا يوجد أصناف'))
          : ListView.builder(
        itemCount: inventoryList.length,
        itemBuilder: (context, index) {
          final item = inventoryList[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('الكمية: ${item.quantity} | الوحدة: ${item.unit}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.remove), onPressed: () => updateInventoryQuantity(index, -1)),
                IconButton(icon: const Icon(Icons.add), onPressed: () => updateInventoryQuantity(index, 1)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => deleteInventoryItem(index)),
              ],
            ),
          );
        },
      ),
    );
  }
}
