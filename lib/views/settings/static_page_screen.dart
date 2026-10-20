import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StaticPageScreen extends StatelessWidget {
  final String title;
  final String body;
  const StaticPageScreen({super.key, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(body, style: const TextStyle(
          fontSize: 14, height: 1.7, color: AppColors.textPrimary,
        )),
      ),
    );
  }
}