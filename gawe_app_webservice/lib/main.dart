// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coba_1/features/auth/splash_screen.dart';
import 'package:coba_1/core/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:coba_1/core/app_theme.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. PENTING: Tambahkan options ini
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Gawee App',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          
          theme: AppTheme.lightTheme(
            themeProvider.primaryColor, 
            themeProvider.lightScaffoldColor, 
          ),
          darkTheme: AppTheme.darkTheme(
            themeProvider.primaryColor, 
          ),
          
          home: const SplashScreen(),
        );
      },
    );
  }
}