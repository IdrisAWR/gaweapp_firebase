// lib/features/job/recent_job_screen.dart
import 'package:flutter/material.dart';
import 'package:coba_1/shared_widgets/app_drawer.dart';
import 'package:coba_1/features/job/available_jobs_screen.dart'; // Halaman Detail
import 'package:coba_1/core/services/job_service.dart'; // Service Backend
import 'package:coba_1/core/models/job_model.dart'; // Model Backend
import 'package:coba_1/shared_widgets/company_logo_widget.dart';

class RecentJobScreen extends StatefulWidget {
  final String? initialQuery;

  const RecentJobScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  _RecentJobScreenState createState() => _RecentJobScreenState();
}

class _RecentJobScreenState extends State<RecentJobScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final JobService _jobService = JobService(); // Panggil Service
  
  // 1. Controller untuk Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ""; // Variabel penyimpan teks pencarian

  @override
  void initState() {
    super.initState();
    // 2. Jika ada initialQuery, isi search bar dan query
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
    }
  }

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
          "Recent Job",
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
      body: Column(
        children: [
          // 2. Search Bar dengan Logika
          _buildSearchBar(Theme.of(context).cardColor, subtitleColor, titleColor),
          
          // List Job dari Database
          Expanded(
            child: StreamBuilder<List<JobModel>>(
              stream: _jobService.getJobs(), // Ambil data realtime
              builder: (context, snapshot) {
                // Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Error / Empty State (Database Kosong)
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No jobs available."));
                }

                List<JobModel> jobs = snapshot.data!;

                // 3. LOGIKA FILTER PENCARIAN
                if (_searchQuery.isNotEmpty) {
                  jobs = jobs.where((job) {
                    final titleLower = job.jobTitle.toLowerCase();
                    final companyLower = job.companyName.toLowerCase();
                    final searchLower = _searchQuery.toLowerCase();
                    // Cari berdasarkan Judul ATAU Nama Perusahaan
                    return titleLower.contains(searchLower) || companyLower.contains(searchLower);
                  }).toList();
                }

                // Empty State (Hasil Pencarian Kosong)
                if (jobs.isEmpty) {
                  return const Center(child: Text("No jobs found matching your search."));
                }

                return ListView.separated(
                  itemCount: jobs.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return _buildRecentJobListItem(context, job);
                  },
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context).hintColor.withOpacity(0.1),
                    indent: 24,
                    endIndent: 24,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color cardColor, Color hintColor, Color inputColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: TextField(
          controller: _searchController, // Hubungkan Controller
          onChanged: (value) {
            // Update UI setiap kali user mengetik
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(color: inputColor),
          decoration: InputDecoration(
            hintText: "Search job title or company...",
            hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
            border: InputBorder.none,
            // Tombol Clear (X) muncul jika ada teks, jika tidak tombol Search
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: hintColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = "";
                      });
                    },
                  )
                : Icon(Icons.search, color: hintColor.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  // Widget List Item (Sudah disesuaikan dengan JobModel)
  Widget _buildRecentJobListItem(BuildContext context, JobModel job) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color subtitleColor = Theme.of(context).hintColor;

    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail Job yang benar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AvailableJobsScreen(job: job),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            CompanyLogoWidget(
              logoUrl: job.companyLogoUrl, 
              companyName: job.companyName,
              size: 50,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.jobTitle, 
                    style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${job.companyName} • ${job.location}", 
                    style: TextStyle(color: subtitleColor, fontSize: 14)
                  ),
                  const SizedBox(height: 5),
                  Text(
                    job.salaryRange, 
                    style: TextStyle(color: subtitleColor, fontSize: 14)
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.bookmark_border_rounded, // Bookmark statis dulu
                color: subtitleColor,
                size: 28,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}