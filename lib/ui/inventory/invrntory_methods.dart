
import 'package:al_farouq_factory/ui/inventory/Inventory_Screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المخزن')),
      body: ListView.builder(
        itemCount: inventoryList.length,
        itemBuilder: (context, index) {
          final item = inventoryList[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('الكمية: ${item.quantity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => updateInventoryQuantity(index, -1),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => updateInventoryQuantity(index, 1),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteInventoryItem(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
