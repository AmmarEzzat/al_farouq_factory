import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(



      appBar: AppBar(

        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_outlined)),

      ),
    );
  }
}
