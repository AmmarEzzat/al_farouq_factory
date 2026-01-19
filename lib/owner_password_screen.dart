import 'package:al_farouq_factory/ui/dashboard/Dashboard_Screen.dart';
import 'package:flutter/material.dart';
import 'package:al_farouq_factory/ui/inventory/storage_service.dart';


class OwnerPasswordScreen extends StatefulWidget {
  const OwnerPasswordScreen({super.key});

  @override
  State<OwnerPasswordScreen> createState() => _OwnerPasswordScreenState();
}

class _OwnerPasswordScreenState extends State<OwnerPasswordScreen> {
  final controller = TextEditingController();
  String? savedPassword;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPassword();
  }

  Future<void> loadPassword() async {
    savedPassword = await StorageService.getPassword();
    setState(() => loading = false);
  }

  Future<void> submit() async {
    if (savedPassword == null) {
      // أول مرة → حفظ باسورد
      await StorageService.setPassword(controller.text);
    } else {
      if (controller.text != savedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة المرور غير صحيحة')),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MonthlyIncomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('دخول المالك')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              savedPassword == null
                  ? 'تعيين كلمة مرور للمالك'
                  : 'أدخل كلمة المرور',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'كلمة المرور',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: submit,
              child: const Text('دخول'),
            ),
          ],
        ),
      ),
    );
  }
}
