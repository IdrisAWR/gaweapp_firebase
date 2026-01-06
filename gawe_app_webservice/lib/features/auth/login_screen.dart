// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:coba_1/shared_widgets/custom_form_field.dart';
import 'forgot_password_screen.dart';
import 'create_account_screen.dart';
import 'package:coba_1/features/home/home_screen.dart';
import 'package:coba_1/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final int initialTabIndex; // 0 untuk Job Seeker, 1 untuk Company

  const LoginScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  Color primaryColor = const Color(0xFF9634FF);
  Color secondaryColor = const Color(0xFF569AFF);
  Color backgroundColor = const Color(0xFFF9F7FF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI LOGIN EMAIL BIASA ---
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI LOGIN GOOGLE (BARU) ---
  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      // Tentukan role berdasarkan tab yang sedang aktif
      // Index 0 = Job Seeker, Index 1 = Company
      String role = _tabController.index == 0 ? 'job_seeker' : 'company';
      
      await _authService.signInWithGoogle(role: role);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign In Failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/gawee.png',
                    width: 200,
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              indicatorWeight: 3.0,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: "JOB SEEKER"),
                Tab(text: "COMPANY"),
              ],
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJobSeekerTab(context),
                  _buildCompanyTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobSeekerTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Sign in to your registered account",
            style: TextStyle(fontSize: 26,fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 20),
          CustomFormField(hintText: "Email Address", controller: _emailController),
          const SizedBox(height: 20),
          CustomFormField(hintText: "Password", obscureText: true, controller: _passwordController),
          const SizedBox(height: 30),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildLoginButton("LOGIN", primaryColor, _handleLogin),

          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
            ),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black54),
                children: [
                  const TextSpan(text: "Forgot your password? "),
                  TextSpan(
                    text: "Reset here",
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Center(child: Text("Or sign in with", style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TOMBOL GOOGLE DISINI
              _buildSocialButton('assets/images/google.png', _handleGoogleLogin),
              const SizedBox(width: 20),
              // TOMBOL FACEBOOK (Sementara kosong dulu)
              _buildSocialButton('assets/images/facebook.png', () {}),
            ],
          ),
          const SizedBox(height: 30),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateAccountScreen(role: 'job_seeker')),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: primaryColor, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "CREATE ACCOUNT",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Company account",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,color: Colors.black),
          ),
          const SizedBox(height: 20),
          CustomFormField(hintText: "Company Email", controller: _emailController),
          const SizedBox(height: 20),
          CustomFormField(hintText: "Password", obscureText: true, controller: _passwordController),
          const SizedBox(height: 30),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildLoginButton("LOGIN", primaryColor, _handleLogin),
          
           const SizedBox(height: 30),
           const Center(child: Text("Or sign in with", style: TextStyle(color: Colors.grey))),
           const SizedBox(height: 20),
           Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TOMBOL GOOGLE DISINI
              _buildSocialButton('assets/images/google.png', _handleGoogleLogin),
              const SizedBox(width: 20),
              _buildSocialButton('assets/images/facebook.png', () {}),
            ],
          ),
          const SizedBox(height: 30),
           OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateAccountScreen(role: 'company')),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: primaryColor, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "REGISTER COMPANY",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildSocialButton(String assetPath, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        assetPath,
        width: 50,
        height: 50,
      ),
    );
  }
}