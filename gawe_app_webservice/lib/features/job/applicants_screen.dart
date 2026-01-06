// lib/features/job/applicants_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coba_1/core/models/job_model.dart'; // Import JobModel

class ApplicantsScreen extends StatelessWidget {
  final JobModel job;

  const ApplicantsScreen({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Applicants List"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query: Ambil data dari 'applications' dimana job_id sama dengan job ini
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('job_id', isEqualTo: job.jobId)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error / Kosong
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("No applicants yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 3. Tampilkan Data
          var applicants = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applicants.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              var data = applicants[index].data() as Map<String, dynamic>;
              
              String name = data['applicant_name'] ?? 'Unknown';
              String email = data['applicant_email'] ?? 'No Email';
              // String date = data['applied_at'] ?? ''; // Jika mau menampilkan tanggal

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(name[0].toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(email),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  onPressed: () {
                    // Nanti bisa ditambahkan fitur lihat detail pelamar/resume disini
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("View Resume feature coming soon!")),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}