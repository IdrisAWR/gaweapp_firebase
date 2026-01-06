// lib/core/services/auth_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import standar
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Sekarang ini pasti dikenali

  // Mendapatkan user yang sedang login
  User? get currentUser => _auth.currentUser;

  // --- LOGIN EMAIL & PASSWORD ---
  Future<UserModel?> signIn({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(result.user!.uid).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, result.user!.uid);
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  // --- REGISTER EMAIL & PASSWORD ---
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String role, 
    String? companyId,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email,
        name: name,
        role: role,
        companyId: companyId,
      );

      await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());

      return newUser;
    } catch (e) {
      throw e;
    }
  }

  // --- LOGIN GOOGLE ---
  Future<UserModel?> signInWithGoogle({String role = 'job_seeker'}) async {
    try {
      // 1. Trigger Pop-up Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null; // User membatalkan login

      // 2. Ambil Auth Detail
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Buat Kredensial Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          // User Baru -> Simpan
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'No Name',
            role: role, 
            phoneNumber: user.phoneNumber,
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
          return newUser;
        } else {
          // User Lama -> Load
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
        }
      }
      return null;
    } catch (e) {
      print("Error Google Sign In: $e"); // Debugging
      throw e;
    }
  }

  // --- LOGOUT ---
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Ignore
    }
  }
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }
  // --- UPDATE DATA USER (Profile) ---
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw e;
    }
  }
  // --- FUNGSI UPLOAD RESUME (BARU) ---
  Future<void> uploadResume(String uid, File file, String fileName) async {
    try {
      // 1. Buat referensi lokasi file di Storage: resumes/UID/nama_file.pdf
      Reference ref = _storage.ref().child('resumes').child(uid).child(fileName);

      // 2. Upload file
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // 3. Ambil Link Download (URL)
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. Simpan URL dan Nama File ke Database User
      await _firestore.collection('users').doc(uid).update({
        'resume_url': downloadUrl,
        'resume_name': fileName,
      });
    } catch (e) {
      throw e;
    }
  }
  // --- FUNGSI UPLOAD FOTO PROFIL (BARU) ---
  Future<void> uploadProfilePicture(String uid, File imageFile) async {
    try {
      // 1. Buat referensi: profile_images/UID.jpg
      // Kita pakai nama tetap (profile.jpg) agar file lama otomatis tertimpa (hemat storage)
      Reference ref = _storage.ref().child('profile_images').child(uid).child('profile.jpg');

      // 2. Upload file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // 3. Ambil URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. Update field 'photo_url' di Firestore
      await _firestore.collection('users').doc(uid).update({
        'photo_url': downloadUrl,
      });
    } catch (e) {
      throw e;
    }
  }
}