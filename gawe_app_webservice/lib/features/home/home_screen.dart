// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coba_1/shared_widgets/app_drawer.dart';
import 'package:coba_1/core/theme_provider.dart';
import 'package:coba_1/shared_widgets/company_logo_widget.dart';
import 'package:coba_1/features/settings/widgets/color_palette_sheet.dart';
import 'package:coba_1/features/job/recent_job_screen.dart';
import 'package:coba_1/features/job/available_jobs_screen.dart';
import 'package:coba_1/features/job/add_job_screen.dart';
import 'package:coba_1/core/services/job_service.dart';
import 'package:coba_1/core/models/job_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final JobService _jobService = JobService();
  
  // 1. Controller untuk Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ""; // Menyimpan teks pencarian

  // Variabel Role (untuk FAB)
  String _userRole = "job_seeker"; 

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // Kita hanya fetch role sekali saja untuk logika tombol Post Job
  void _fetchUserRole() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (mounted && doc.exists) {
        setState(() {
          _userRole = doc['role'] ?? "job_seeker";
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showColorPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ColorPaletteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color titleColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final Color subtitleColor = Theme.of(context).hintColor;

    // Ambil User ID untuk Stream Header
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: _buildAppBar(context, themeProvider),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. HEADER DINAMIS (REALTIME FOTO & NAMA)
            if (currentUser != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(); // Loading diam
                  
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  String name = data['name'] ?? "User";
                  String photoUrl = data['photo_url'] ?? "";

                  return _buildHeader(titleColor, subtitleColor, name, photoUrl);
                },
              ),

            // 3. SEARCH BAR AKTIF
            _buildSearchBar(),

            // Jika sedang mencari, sembunyikan Banner & Kategori agar fokus ke hasil
            if (_searchQuery.isEmpty) ...[
              _buildRecomendedBanner(),
              _buildStatsCards(),
              _buildJobCategories(primaryColor),
              _buildSectionTitle("Featured Jobs", titleColor, primaryColor),
              StreamBuilder<List<JobModel>>(
                stream: _jobService.getJobs(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return _buildFeaturedJobsList(snapshot.data!.take(5).toList());
                },
              ),
            ],

            // 4. LIST JOB (TERINTEGRASI DENGAN SEARCH)
            _buildSectionTitle(
              _searchQuery.isEmpty ? "Recent Jobs List" : "Search Results", 
              titleColor, 
              primaryColor, 
              () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentJobScreen()));
              }
            ),
            
            StreamBuilder<List<JobModel>>(
              stream: _jobService.getJobs(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                List<JobModel> jobs = snapshot.data!;

                // --- LOGIKA FILTER PENCARIAN ---
                if (_searchQuery.isNotEmpty) {
                  jobs = jobs.where((job) {
                    final titleLower = job.jobTitle.toLowerCase();
                    final companyLower = job.companyName.toLowerCase();
                    final searchLower = _searchQuery.toLowerCase();
                    return titleLower.contains(searchLower) || companyLower.contains(searchLower);
                  }).toList();
                }

                if (jobs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text("No jobs found matching your search.")),
                  );
                }

                return _buildRecentJobsList(jobs);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      
      floatingActionButton: _userRole == 'company' 
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddJobScreen()),
                );
              },
              label: const Text("Post Job"),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF9634FF),
            )
          : null,
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    return AppBar(
      actions: [
        IconButton(
          icon: Icon(Icons.palette_outlined, color: Theme.of(context).hintColor),
          onPressed: () => _showColorPalette(context),
        ),
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: Theme.of(context).hintColor,
          ),
          onPressed: () {
            final provider = Provider.of<ThemeProvider>(context, listen: false);
            provider.toggleTheme(!provider.isDarkMode);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // Update Header menerima data dinamis
  Widget _buildHeader(Color titleColor, Color subtitleColor, String name, String photoUrl) {
    
    // Tentukan Image Provider (Network atau Asset)
    ImageProvider imageProvider;
    if (photoUrl.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl);
    } else {
      imageProvider = const AssetImage('assets/images/user1.jpg');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hello,", style: TextStyle(color: subtitleColor, fontSize: 20)),
                Text(
                  name, // Nama Realtime
                  style: TextStyle(color: titleColor, fontSize: 26, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 30,
            backgroundImage: imageProvider, // Foto Realtime
            backgroundColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: TextField(
          controller: _searchController, // Hubungkan Controller
          onChanged: (value) {
            // Update UI setiap kali mengetik
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color!),
          decoration: InputDecoration(
            hintText: "Search job title or company...",
            hintStyle: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.5)),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: Icon(Icons.clear, color: Theme.of(context).hintColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
              : Icon(Icons.search, color: Theme.of(context).hintColor.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS LAIN TETAP SAMA ---
  Widget _buildRecomendedBanner() {
    const Color bannerColor = Color.fromARGB(255, 111, 0, 255);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recomended Jobs", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("See our recommendations job for you based your skills", style: TextStyle(color: Color(0xFFE9DFFF), fontSize: 14)),
                ],
              ),
            ),
            Image.asset('assets/images/onboarding_image_2.png', width: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          _buildStatCard("45", "Jobs Applied"),
          const SizedBox(width: 16),
          _buildStatCard("28", "Interviews"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(number, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color!, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCategories(Color primaryColor) {
    final Color designerColor = const Color.fromARGB(255, 3, 88, 179);
    final Color managerColor = const Color(0xFF27AE60);
    final Color programmerColor = const Color(0xFF8B4513);
    final Color uiuxColor = const Color.fromARGB(255, 12, 126, 59);
    final Color potoColor = const Color.fromARGB(255, 139, 38, 221);

    void _navigateToRecentJobs() {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentJobScreen()));
    }

    return Column(
      children: [
        _buildSectionTitle("Job Categories", Theme.of(context).textTheme.bodyLarge!.color!, primaryColor, _navigateToRecentJobs),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildCategoryChip("Designer", designerColor, Colors.white, _navigateToRecentJobs),
              _buildCategoryChip("Manager", managerColor, Colors.white, _navigateToRecentJobs),
              _buildCategoryChip("Programmer", programmerColor, Colors.white, _navigateToRecentJobs),
              _buildCategoryChip("UI/UX", uiuxColor, Colors.white, _navigateToRecentJobs),
              _buildCategoryChip("Photo", potoColor, Colors.white, _navigateToRecentJobs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, Color color, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Chip(
          label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color titleColor, Color primaryColor, [VoidCallback? onMoreTap]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.bold)),
          if (onMoreTap != null)
            GestureDetector(
              onTap: onMoreTap,
              child: Text("More", style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedJobsList(List<JobModel> jobs) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildFeaturedJobCard(job);
        },
      ),
    );
  }

  Widget _buildFeaturedJobCard(JobModel job) {
    final Color cardColor = Theme.of(context).cardColor;
    final Color titleColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final Color subtitleColor = Theme.of(context).hintColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AvailableJobsScreen(job: job)),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CompanyLogoWidget(
                  logoUrl: job.companyLogoUrl, 
                  companyName: job.companyName,
                  size: 50,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(job.companyName, style: TextStyle(color: subtitleColor, fontSize: 16), overflow: TextOverflow.ellipsis),
                ),
                Icon(Icons.bookmark_border, color: subtitleColor),
              ],
            ),
            const Spacer(),
            Text(job.jobTitle, style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Text(job.location, style: TextStyle(color: subtitleColor, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(job.salaryRange, style: TextStyle(color: subtitleColor, fontSize: 16)),
                Icon(Icons.arrow_forward_ios_rounded, color: titleColor, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobsList(List<JobModel> jobs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: jobs.map((job) => _buildRecentJobCard(job)).toList(),
      ),
    );
  }

  Widget _buildRecentJobCard(JobModel job) {
    final Color cardColor = Theme.of(context).cardColor;
    final Color subtitleColor = Theme.of(context).hintColor;
    final Color primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AvailableJobsScreen(job: job)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3))]
        ),
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
                  Text(job.jobTitle, style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("${job.companyName} • ${job.location}", style: TextStyle(color: subtitleColor, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(job.salaryRange, style: TextStyle(color: subtitleColor, fontSize: 14)),
                ],
              ),
            ),
            Icon(Icons.bookmark_border_rounded, color: subtitleColor, size: 28),
          ],
        ),
      ),
    );
  }
}