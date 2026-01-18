import 'package:al_farouq_factory/ui/homeScreen/home_screen.dart';
import 'package:al_farouq_factory/utils/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    initialRoute: HomeScreen.routeName,
debugShowCheckedModeBanner: false,
      routes: {

        HomeScreen.routeName:(context)=> HomeScreen(),


      },

    );
  }
}
