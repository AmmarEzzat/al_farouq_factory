import 'package:flutter/cupertino.dart';

class HomeItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final bool isProtected;
  final String imagePath;
  HomeItem({
    required this.title,
    required this.icon,
    required this.screen,
    this.isProtected = false, required this. imagePath,
  });
}