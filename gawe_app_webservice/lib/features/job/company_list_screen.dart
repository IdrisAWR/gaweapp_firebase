// lib/company_list_screen.dart
import 'package:flutter/material.dart';
import 'package:coba_1/shared_widgets/app_drawer.dart';
import 'package:coba_1/features/job/available_jobs_screen.dart'; // Halaman Detail
import 'package:coba_1/core/services/job_service.dart'; // Service Backend
import 'package:coba_1/core/models/job_model.dart'; // Model Backend

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({Key? key}) : super(key: key);

  @override
  _CompanyListScreenState createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // 1. Panggil Service
  final JobService _jobService = JobService();

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          "Job Feed", // Saya ganti jadi Job Feed agar lebih relevan
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: subtitleColor),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          )
        ],
      ),
      body: Column( // Ganti SingleScrollView jadi Column agar StreamBuilder bisa expand
        children: [
          // --- Search Bar (Tetap) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                style: TextStyle(color: titleColor),
                decoration: InputDecoration(
                  hintText: "Type Company Name or Job Title",
                  hintStyle: TextStyle(color: subtitleColor.withOpacity(0.7)),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: subtitleColor.withOpacity(0.7)),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),

          // --- 2. STREAM BUILDER (DATA ASLI) ---
          Expanded(
            child: StreamBuilder<List<JobModel>>(
              stream: _jobService.getJobs(), // Ambil data dari Firebase
              builder: (context, snapshot) {
                // Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error State
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                // Empty State
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No jobs available right now."));
                }

                // Data Ready
                List<JobModel> jobs = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return _buildCompanyCard(context, job);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper yang sudah dimodifikasi untuk menerima JobModel
  Widget _buildCompanyCard(BuildContext context, JobModel job) {
    return GestureDetector(
      onTap: () {
        // --- PERBAIKAN UTAMA DI SINI ---
        // Kita kirim data 'job' yang asli ke halaman Detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AvailableJobsScreen(job: job),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo (Karena di database belum ada URL logo, kita pakai aset default/random)
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/cosax.png', // Logo default agar tidak error
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Perusahaan
                  Text(
                    job.companyName, 
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  
                  // Lokasi
                  Text(
                    job.location,
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  
                  // Judul Pekerjaan (Sebagai pengganti "10 Jobs")
                  Text(
                    job.jobTitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge!.color!, 
                      fontSize: 14, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ),
            // Ikon Panah (Opsional)
             Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}