import 'package:flutter/material.dart';
import 'dart:math';

class CompanyLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final String companyName;
  final double size;

  const CompanyLogoWidget({
    Key? key,
    required this.logoUrl,
    required this.companyName,
    this.size = 50,
  }) : super(key: key);

  // Fungsi membuat warna random yang soft (pastel)
  Color _generateRandomColor(String key) {
    // Gunakan hash dari nama perusahaan agar warnanya konsisten (tidak berubah-ubah tiap scroll)
    final int hash = key.codeUnits.fold(0, (prev, element) => prev + element);
    final Random random = Random(hash); 
    
    return Color.fromARGB(
      255,
      random.nextInt(100) + 150, // R (150-250) -> Terang
      random.nextInt(100) + 150, // G (150-250) -> Terang
      random.nextInt(100) + 150, // B (150-250) -> Terang
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jika ada URL Logo -> Tampilkan Gambar
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
          image: DecorationImage(
            image: NetworkImage(logoUrl!),
            fit: BoxFit.contain, // Agar logo tidak terpotong
          ),
        ),
      );
    }

    // Jika TIDAK ada Logo -> Tampilkan Inisial Warna-Warni
    String initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : "?";
    Color bgColor = _generateRandomColor(companyName);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}