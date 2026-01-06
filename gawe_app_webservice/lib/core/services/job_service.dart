// lib/core/services/job_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- HELPER: Upload Logo Job ---
  Future<String?> _uploadJobLogo(String jobId, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('job_logos').child('$jobId.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // --- UPDATE FUNGSI ADD JOB ---
  Future<void> addJob({
    required String jobTitle,
    required String location,
    required String salaryRange,
    required String description,
    required List<String> requirements,
    File? logoFile, // <--- Parameter baru (Gambar Logo)
  }) async {
    try {
      String uid = _auth.currentUser!.uid;
      // Buat ID Job duluan agar bisa dipakai nama file gambar
      DocumentReference docRef = _firestore.collection('jobs').doc(); 
      
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      String companyName = userDoc['name'] ?? 'Unknown Company';
      
      String? logoUrl;
      // Jika ada file logo, upload dulu
      if (logoFile != null) {
        logoUrl = await _uploadJobLogo(docRef.id, logoFile);
      }

      Map<String, dynamic> jobData = {
        'company_id': uid,
        'company_name': companyName,
        'job_title': jobTitle,
        'location': location,
        'salary_range': salaryRange,
        'description': description,
        'requirements': requirements,
        'created_at': DateTime.now().toIso8601String(),
        'company_logo_url': logoUrl, // Simpan URL
      };

      // Simpan dengan ID yang sudah dibuat
      await docRef.set(jobData);
    } catch (e) {
      throw e;
    }
  }

  // --- JOB SEEKER: AMBIL SEMUA LOKER ---
  Stream<List<JobModel>> getJobs() {
    return _firestore
        .collection('jobs')
        .orderBy('created_at', descending: true) // Yang terbaru di atas
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- JOB SEEKER: APPLY LOKER ---
  Future<void> applyJob(JobModel job, String applicantName, String applicantEmail) async {
    try {
      String uid = _auth.currentUser!.uid;

      // 1. Cek apakah user sudah pernah apply di job ini?
      var existingApp = await _firestore
          .collection('applications')
          .where('job_id', isEqualTo: job.jobId)
          .where('applicant_id', isEqualTo: uid)
          .get();

      if (existingApp.docs.isNotEmpty) {
        throw "You have already applied for this job!";
      }

      // 2. Simpan Data Lamaran
      Map<String, dynamic> appData = {
        'job_id': job.jobId,
        'job_title': job.jobTitle,
        'applicant_id': uid,
        'applicant_name': applicantName,
        'applicant_email': applicantEmail,
        'company_id': job.companyId,
        'status': 'pending',
        'applied_at': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('applications').add(appData);
    } catch (e) {
      throw e;
    }
  }
  
  // --- COMPANY: UPDATE JOB ---
  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update(data);
    } catch (e) {
      throw e;
    }
  }

  // --- COMPANY: DELETE JOB ---
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
    } catch (e) {
      throw e;
    }
  }
  
  // --- CEK STATUS APPLY (Untuk merubah tombol jadi 'Applied') ---
  Future<bool> hasApplied(String jobId) async {
    String uid = _auth.currentUser!.uid;
    var result = await _firestore
        .collection('applications')
        .where('job_id', isEqualTo: jobId)
        .where('applicant_id', isEqualTo: uid)
        .get();
    return result.docs.isNotEmpty;
  }
}