import 'package:flutter/material.dart';
import 'package:al_farouq_factory/ui/employee/employee.dart';
import 'package:al_farouq_factory/ui/employee/employee_payment.dart';
import 'package:al_farouq_factory/ui/employee/employee_deduction.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';
import 'package:al_farouq_factory/utils/app_colors.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Employee> employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final list = await StorageService.getEmployees();
    setState(() {
      employees = list;
    });
  }

  void _addEmployeeDialog() {
    final nameController = TextEditingController();
    final salaryController = TextEditingController();
    EmployeeType selectedType = EmployeeType.fixedSalary;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة عامل جديد'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم العامل'),
                ),
                const SizedBox(height: 10),
                DropdownButton<EmployeeType>(
                  value: selectedType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: EmployeeType.fixedSalary, child: Text('مرتب ثابت')),
                    DropdownMenuItem(value: EmployeeType.production, child: Text('بالإنتاج ')),
                  ],
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                if (selectedType == EmployeeType.fixedSalary)
                  TextField(
                    controller: salaryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'المرتب الشهري الثابت'),
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final employee = Employee(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                type: selectedType,
                salary: double.tryParse(salaryController.text) ?? 0,
              );
              final list = await StorageService.getEmployees();
              list.add(employee);
              await StorageService.saveEmployees(list);
              Navigator.pop(context);
              _loadEmployees();
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
        title: const Text('إدارة العمال'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _addEmployeeDialog,
        child: const Icon(Icons.person_add),
      ),
      body: employees.isEmpty
          ? const Center(child: Text('لا يوجد عمال مضافين حالياً'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          return _EmployeeCard(
            employee: employees[index],
            onRefresh: _loadEmployees,
          );
        },
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onRefresh;

  const _EmployeeCard({required this.employee, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isProduction = employee.type == EmployeeType.production;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(employee.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isProduction ? Colors.orange.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isProduction ? 'بالإنتاج' : 'مرتب ثابت',
                    style: TextStyle(fontSize: 12, color: isProduction ? Colors.orange.shade900 : Colors.blue.shade900),
                  ),
                ),
              ],
            ),
            const Divider(),
            if (!isProduction) Text('المرتب الثابت: ${employee.salary} ج'),
            if (isProduction) ...[
              Text('عدد الأصناف المنتجة حالياً: ${employee.pendingTasks.length}'),
              Text('إجمالي أجر الإنتاج: ${employee.productionTotal.toStringAsFixed(2)} ج',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 5),
            Text('إجمالي الخصومات: ${employee.totalDeductions.toStringAsFixed(2)} ج', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 5),
            Text(
              'صافي المستحق للقبض: ${employee.netEarned.toStringAsFixed(2)} ج',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isProduction)
                  _ActionButton(
                    icon: Icons.add_task,
                    label: 'إنتاج',
                    color: Colors.purple,
                    onTap: () => _showAddProductionDialog(context),
                  ),
                _ActionButton(
                  icon: Icons.money_off,
                  label: 'خصم',
                  color: Colors.orange,
                  onTap: () => _showDeductionDialog(context),
                ),
                _ActionButton(
                  icon: Icons.payments,
                  label: 'قبض',
                  color: Colors.green,
                  onTap: () => _showPayDialog(context),
                ),
                _ActionButton(
                  icon: Icons.history,
                  label: 'سجل',
                  color: Colors.blue,
                  onTap: () => _showHistoryDialog(context),
                ),
                _ActionButton(
                  icon: Icons.delete_forever,
                  label: 'حذف',
                  color: Colors.red,
                  onTap: () => _deleteEmployee(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductionDialog(BuildContext context) {
    final itemController = TextEditingController();
    final qtyController = TextEditingController();
    final rateController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل إنتاج جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: itemController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
            TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
            TextField(controller: rateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أجر القطعة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              final rate = double.tryParse(rateController.text) ?? 0;
              if (qty > 0) {
                await StorageService.addProductionToEmployee(
                  employee.id,
                  ProductionTask(itemName: itemController.text, quantity: qty, rate: rate, date: DateTime.now()),
                );
                Navigator.pop(context);
                onRefresh();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeductionDialog(BuildContext context) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة خصم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'السبب')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                await StorageService.addEmployeeDeduction(employee: employee, amount: amount, reason: reasonController.text);
                Navigator.pop(context);
                onRefresh();
              }
            },
            child: const Text('تطبيق الخصم'),
          ),
        ],
      ),
    );
  }

  void _showPayDialog(BuildContext context) {
    final controller = TextEditingController(text: employee.netEarned.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تسوية حساب ${employee.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'المبلغ المدفوع فعلياً'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                await StorageService.payEmployee(employee: employee, amount: amount);
                Navigator.pop(context);
                onRefresh();
              }
            },
            child: const Text('تأكيد القبض وتصفير الحساب', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('سجل العمليات الكامل - ${employee.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'الحساب الحالي'),
                    Tab(text: 'الأرشيف (سابقاً)'),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    children: [
                      _buildCurrentStatus(),
                      _buildArchiveStatus(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
      ),
    );
  }

  // التبويب الأول: الحالة الحالية
  Widget _buildCurrentStatus() {
    final tasks = employee.pendingTasks;
    final deductions = employee.deductions;
    if (tasks.isEmpty && deductions.isEmpty) {
      return const Center(child: Text('لا توجد مستحقات معلقة حالياً'));
    }
    return ListView(
      children: [
        if (tasks.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.all(8.0), child: Text('📌 إنتاج معلق:', style: TextStyle(fontWeight: FontWeight.bold))),
          ...tasks.map((t) => ListTile(
            dense: true,
            title: Text('${t.itemName} (عدد ${t.quantity})'),
            trailing: Text('${t.quantity * t.rate} ج'),
          )),
        ],
        if (deductions.isNotEmpty) ...[
          const Divider(),
          const Padding(padding: EdgeInsets.all(8.0), child: Text('📌 خصومات حالية:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
          ...deductions.map((d) => ListTile(
            dense: true,
            title: Text(d.reason),
            trailing: Text('- ${d.amount} ج', style: const TextStyle(color: Colors.red)),
          )),
        ],
      ],
    );
  }

  // التبويب الثاني: الأرشيف (بما في ذلك سجل القبض المالي)
  Widget _buildArchiveStatus() {
    final tasks = employee.completedTasks;
    final deductions = employee.completedDeductions;
    final history = employee.paymentHistory;

    if (tasks.isEmpty && deductions.isEmpty && history.isEmpty) {
      return const Center(child: Text('الأرشيف فارغ'));
    }

    return ListView(
      children: [
        // 1. سجل عمليات القبض (الأهم عشان الثابت والإنتاج يظهروا هنا)
        if (history.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.all(8.0), child: Text('💰 سجل المقبوضات المادية:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
          ...history.reversed.map((p) => Card(
            color: Colors.green.shade50,
            child: ListTile(
              dense: true,
              title: Text('استلم: ${p.amountPaid} ج', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              subtitle: Text('تاريخ: ${p.date.day}/${p.date.month}/${p.date.year}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('الخصم: ${p.deductionsSettled}', style: const TextStyle(fontSize: 10)),
                  Text('قبل الخصم: ${p.totalBeforeDeductions}', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          )),
        ],
        const Divider(),
        // 2. سجل الإنتاج القديم
        if (tasks.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.all(8.0), child: Text('✅ إنتاج تم قبضه سابقاً:', style: TextStyle(fontWeight: FontWeight.bold))),
          ...tasks.reversed.map((t) => ListTile(
            dense: true,
            title: Text('${t.itemName} (عدد ${t.quantity})'),
            subtitle: Text('${t.date.day}/${t.date.month}'),
            trailing: Text('${t.quantity * t.rate} ج'),
          )),
        ],
        // 3. سجل الخصومات القديمة
        if (deductions.isNotEmpty) ...[
          const Divider(),
          const Padding(padding: EdgeInsets.all(8.0), child: Text('✅ خصومات تمت تسويتها:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
          ...deductions.reversed.map((d) => ListTile(
            dense: true,
            title: Text(d.reason),
            subtitle: Text('${d.date.day}/${d.date.month}'),
            trailing: Text('- ${d.amount} ج', style: const TextStyle(color: Colors.red)),
          )),
        ],
      ],
    );
  }

  void _deleteEmployee(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف موظف'),
        content: Text('هل أنت متأكد من حذف ${employee.name}؟ ستفقد جميع بياناته.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final list = await StorageService.getEmployees();
      list.removeWhere((e) => e.id == employee.id);
      await StorageService.saveEmployees(list);
      onRefresh();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}