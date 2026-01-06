// lib/features/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:image_picker/image_picker.dart'; // 1. Import Image Picker
import 'package:coba_1/shared_widgets/app_drawer.dart';
import 'package:coba_1/core/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker(); // Inisialisasi Picker
  
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isUploadingResume = false;
  bool _isUploadingImage = false; // Loading state untuk foto

  // --- FUNGSI GANTI FOTO PROFIL (BARU) ---
  void _handleUpdatePhoto() async {
    // 1. Buka Galeri
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploadingImage = true);

      try {
        File file = File(image.path);
        // 2. Upload ke Firebase
        await _authService.uploadProfilePicture(currentUser!.uid, file);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Photo Updated!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  // --- FUNGSI UPLOAD RESUME (TETAP) ---
  void _handleUploadResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isUploadingResume = true);
      try {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        await _authService.uploadResume(currentUser!.uid, file, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Resume Uploaded!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        // Handle error
      } finally {
        if (mounted) setState(() => _isUploadingResume = false);
      }
    }
  }

  // --- FUNGSI EDIT PROFILE DATA (PERBAIKAN) ---
  void _showEditProfileDialog(Map<String, dynamic> userData) {
    final TextEditingController _nameController = TextEditingController(text: userData['name']);
    final TextEditingController _bioController = TextEditingController(text: userData['bio'] ?? '');
    
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa tutup dengan klik luar saat loading
      builder: (dialogContext) { // Gunakan nama context yang berbeda agar tidak bingung
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: "Bio / Description"),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Tutup dialog
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () async {
                // 1. Simpan referensi ScaffoldMessenger SEBELUM async gap
                // Ini teknik paling aman untuk menghindari error context
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                try {
                  // 2. Lakukan Update
                  await _authService.updateUser(currentUser!.uid, {
                    'name': _nameController.text,
                    'bio': _bioController.text,
                  });

                  // 3. Tutup Dialog dulu
                  navigator.pop(); 

                  // 4. Tampilkan SnackBar menggunakan referensi yang disimpan di awal
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
                  );
                  
                } catch (e) {
                  // Jika error, tetap tutup dialog dulu (opsional), atau biarkan terbuka
                  // Di sini kita tutup saja agar user bisa coba lagi
                  // navigator.pop(); 
                  
                  messenger.showSnackBar(
                    SnackBar(content: Text("Error updating profile: $e")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9634FF)),
              child: const Text("SAVE", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color titleColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final Color subtitleColor = Theme.of(context).hintColor;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Profile", style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (currentUser != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return IconButton(
                  icon: Icon(Icons.edit, color: primaryColor),
                  onPressed: () {
                     Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
                    _showEditProfileDialog(userData);
                  },
                );
              }
            ),
          IconButton(
            icon: Icon(Icons.more_vert, color: subtitleColor),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? "No Name";
          String role = userData['role'] == 'company' ? "Company" : "Engineer";
          String bio = userData['bio'] ?? "No bio available yet.";
          String? resumeName = userData['resume_name'];
          
          // --- LOGIKA FOTO PROFIL ---
          String? photoUrl = userData['photo_url']; // Ambil URL dari database
          ImageProvider imageProvider;
          
          if (photoUrl != null && photoUrl.isNotEmpty) {
            imageProvider = NetworkImage(photoUrl); // Pakai foto dari internet
          } else {
            imageProvider = const AssetImage('assets/images/user1.jpg'); // Default
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- FOTO PROFIL DENGAN TOMBOL EDIT ---
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Lingkaran Foto
                    Container(
                      width: 120, // Diameter
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                        ]
                      ),
                      // Tampilkan Loading di atas foto jika sedang upload
                      child: _isUploadingImage 
                        ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
                        : null,
                    ),
                    
                    // Tombol Kamera Kecil
                    InkWell(
                      onTap: _isUploadingImage ? null : _handleUpdatePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),
                Text(name, style: TextStyle(color: titleColor, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(role, style: TextStyle(color: subtitleColor, fontSize: 16)),
                const SizedBox(height: 20),
                Text(bio, textAlign: TextAlign.center, style: TextStyle(color: subtitleColor, fontSize: 15, height: 1.5)),
                const SizedBox(height: 30),

                _buildResumeButton(context, primaryColor, resumeName),
                
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Skills", style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                _buildSkillBar(context, "Problem Solving", 70),
                _buildSkillBar(context, "Drawing", 35),
                _buildSkillBar(context, "Illustration", 80),
                _buildSkillBar(context, "Photoshop", 34),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumeButton(BuildContext context, Color primaryColor, String? resumeName) {
    return GestureDetector(
      onTap: _isUploadingResume ? null : _handleUploadResume,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("My Resume", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(
                    resumeName ?? "Upload your CV (PDF)",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _isUploadingResume 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.file_upload_outlined, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBar(BuildContext context, String skillName, int percentage) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color titleColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skillName, style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w500)),
              Text("$percentage%", style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}