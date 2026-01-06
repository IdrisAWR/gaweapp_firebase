// lib/shared_widgets/custom_form_field.dart
import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final IconData? icon;
  final TextEditingController? controller; // 1. Kita tambahkan variabel controller

  const CustomFormField({
    Key? key,
    required this.hintText,
    this.obscureText = false,
    this.icon,
    this.controller, // 2. Kita masukkan ke constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller, // 3. Kita hubungkan controller ke TextField
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400) : null,
        ),
      ),
    );
  }
}