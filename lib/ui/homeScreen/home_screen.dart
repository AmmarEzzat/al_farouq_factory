import 'package:al_farouq_factory/model/home_item.dart';
import 'package:al_farouq_factory/ui/Customer_Screen/Customer_Screen.dart';
import 'package:al_farouq_factory/ui/dashboard/Dashboard_Screen.dart';
import 'package:al_farouq_factory/ui/employee/employee_screen.dart';
import 'package:al_farouq_factory/ui/expenses/Expenses_Screen.dart';
import 'package:al_farouq_factory/ui/inventory/Inventory_Screen.dart';
import 'package:al_farouq_factory/ui/invoice/Invoices_Screen.dart';
import 'package:al_farouq_factory/utils/app_Styles.dart';
import 'package:al_farouq_factory/widget/tab_event_widget.dart';
import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = 'HomeScreen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  late List<HomeItem> items;

  @override
  void initState() {
    super.initState();

    items = [
      HomeItem(
        title: 'العملاء',
        icon: Icons.people,
        screen: CustomersScreen(),
        imagePath: 'assets/elfarouk.png',
      ),
      HomeItem(
        title: 'العمال',
        icon: Icons.badge,
        screen: EmployeesScreen(),
        imagePath: 'assets/elfarouk.png',
      ),
      HomeItem(
        title: 'المخزن',
        icon: Icons.warehouse,
        screen: InventoryScreen(),
        imagePath: 'assets/elfarouk.png',
      ),
      HomeItem(
        title: 'المصروفات',
        icon: Icons.money_off,
        screen: ExpensesScreen(),
        imagePath: 'assets/elfarouk.png',
      ),
      HomeItem(
        title: 'الفواتير',
        icon: Icons.receipt_long,
        screen: InvoicesScreen(),
        imagePath: 'assets/elfarouk.png',
      ),
      HomeItem(
        title: 'الدخل الشهري',
        icon: Icons.bar_chart,
        screen: DashboardScreen(),
        imagePath: 'assets/elfarouk.png',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الفاروق', style: TextStyle(color: AppColors.text)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => selectedIndex = index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.screen),
                    );
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selectedIndex == index
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: selectedIndex == index
                              ? Colors.white
                              : AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: selectedIndex == index
                              ? AppStyles.semi16white
                              : AppStyles.semi16black,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

         
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                items[selectedIndex].imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Developed by Ammar Ezzat ",style: AppStyles.semi16Primary,),
            ],
          ),

        ],
      ),
    );
  }
}
