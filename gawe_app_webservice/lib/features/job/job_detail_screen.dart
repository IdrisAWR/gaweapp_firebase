// lib/features/job/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:coba_1/core/models/job_model.dart'; // 1. Import Model
import 'available_jobs_screen.dart'; // 2. Import halaman Apply
import 'package:coba_1/shared_widgets/app_drawer.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job; // 3. Terima data Job agar dinamis

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _scrollController.addListener(() {
      const double scrollThreshold = 150.0;
      if (_scrollController.offset > scrollThreshold) {
        if (_appBarOpacity != 1.0) setState(() => _appBarOpacity = 1.0);
      } else {
        if (_appBarOpacity != 0.0) setState(() => _appBarOpacity = 0.0);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color titleColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final Color subtitleColor = Theme.of(context).hintColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Gambar Gedung
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/detail_jobs.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Logo Perusahaan
                Transform.translate(
                  offset: const Offset(0.0, -35.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                    ),
                    // Logo Default (karena di DB belum ada URL gambar)
                    child: Image.asset(
                      'assets/images/cosax4.png', 
                      width: 60,
                      height: 60,
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // --- DATA DINAMIS DARI DATABASE ---
                Text(
                  widget.job.jobTitle, // Judul Pekerjaan Asli
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.job.location, // Lokasi Asli
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subtitleColor, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.job.companyName, // Nama Perusahaan Asli
                  textAlign: TextAlign.center,
                  style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _buildAvailableJobsBanner(context),
                const SizedBox(height: 20),

                TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: subtitleColor,
                  indicatorColor: primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: const [
                    Tab(text: "ABOUT US"),
                    Tab(text: "RATINGS"),
                    Tab(text: "REVIEW"),
                  ],
                ),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  child: [
                    _buildAboutUsTab(titleColor, subtitleColor),
                    _buildRatingsTab(titleColor, subtitleColor),
                    _buildReviewTab(titleColor, subtitleColor),
                  ][_tabController.index],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // Custom AppBar dengan Animasi
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _appBarOpacity,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: backgroundColor,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: titleColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    widget.job.jobTitle, // Judul Dinamis
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Theme.of(context).hintColor),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tombol Back Statis (Saat AppBar transparan)
          Positioned(
            top: 0, left: 0, right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black), // Ikon Hitam agar terlihat di gambar
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Opacity(
                opacity: 1.0 - _appBarOpacity,
                child: const Text(""), // Kosongkan title saat transparan
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // --- WIDGET HELPER ---

  Widget _buildAvailableJobsBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman APPLY (AvailableJobsScreen)
        // Kita kirim data job yang sama
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AvailableJobsScreen(job: widget.job),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Interested?",
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                ),
                Text(
                  "View Job & Apply", // Ubah teks agar lebih masuk akal
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor, size: 18),
          ],
        ),
      ),
    );
  }

  // --- TAB CONTENT (Dibiarkan Statis untuk Dummy) ---
  Widget _buildAboutUsTab(Color titleColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.job.description, style: TextStyle(color: subtitleColor, fontSize: 15, height: 1.5)),
        const SizedBox(height: 20),
        Text("Requirements", style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Menampilkan Requirements Dinamis
        ...widget.job.requirements.map((req) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(children: [
            Icon(Icons.check_circle, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(req, style: TextStyle(color: subtitleColor)))
          ]),
        )).toList()
      ],
    );
  }

  Widget _buildRatingsTab(Color titleColor, Color subtitleColor) {
    return const Center(child: Text("Ratings Feature Coming Soon")); 
  }

  Widget _buildReviewTab(Color titleColor, Color subtitleColor) {
    return const Center(child: Text("Reviews Feature Coming Soon"));
  }
}