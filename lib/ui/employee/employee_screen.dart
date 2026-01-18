import 'package:al_farouq_factory/utils/app_colors.dart';
import 'package:flutter/material.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(



      appBar: AppBar(

        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_outlined)),

      ),
    );
  }
}
