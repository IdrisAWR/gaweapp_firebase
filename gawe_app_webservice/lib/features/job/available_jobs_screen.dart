// lib/features/job/available_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coba_1/features/job/widgets/apply_job_sheet.dart';
import 'package:coba_1/features/job/add_job_screen.dart'; // Import AddJobScreen untuk Edit
import 'package:coba_1/core/services/job_service.dart'; // Import Service untuk Delete
import 'package:coba_1/shared_widgets/app_drawer.dart';
import 'package:coba_1/features/job/applicants_screen.dart';
import 'gallery_screen.dart'; 
import 'package:coba_1/core/models/job_model.dart'; 

class AvailableJobsScreen extends StatefulWidget {
  final JobModel job; 

  const AvailableJobsScreen({Key? key, required this.job}) : super(key: key);

  @override
  _AvailableJobsScreenState createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBookmarked = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final JobService _jobService = JobService();
  
  String _userRole = "job_seeker";
  bool _isOwner = false; // Penanda apakah user adalah pemilik loker ini

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // 1. Cek Role
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      // 2. Cek Kepemilikan (Apakah ID User == Company ID di Job?)
      bool isOwnerCheck = currentUser.uid == widget.job.companyId;

      if (mounted) {
        setState(() {
          _userRole = doc['role'] ?? "job_seeker";
          _isOwner = isOwnerCheck;
        });
      }
    }
  }

  // --- FUNGSI DELETE ---
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Job"),
        content: const Text("Are you sure you want to delete this job posting?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _jobService.deleteJob(widget.job.jobId);
              if (mounted) {
                Navigator.pop(context); // Tutup Dialog
                Navigator.pop(context); // Kembali ke Home
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Job deleted successfully")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI EDIT ---
  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddJobScreen(jobToEdit: widget.job), // Kirim data job
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showApplySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ApplyJobSheet(job: widget.job),
      ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/cosax.png', width: 40),
            const SizedBox(width: 10),
            Expanded( // Agar teks tidak overflow
              child: Text(
                widget.job.companyName, 
                style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // --- LOGIKA ACTIONS BAR ---
          if (_isOwner) ...[
            // 1. TOMBOL LIHAT PELAMAR (BARU)
            IconButton(
              icon: const Icon(Icons.people_alt_outlined, color: Colors.green),
              tooltip: "View Applicants",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplicantsScreen(job: widget.job),
                  ),
                );
              },
            ),
            // 2. Tombol Edit
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _navigateToEdit,
            ),
            // 3. Tombol Hapus
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            ),
          ] else ...[
            // Jika Bukan Owner
            IconButton(
              icon: Icon(Icons.more_vert, color: subtitleColor),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTag("FULLTIME", primaryColor),
                const SizedBox(width: 10),
                _buildTag("CONTRACT", primaryColor),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.job.jobTitle, 
              style: TextStyle(
                color: titleColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.job.location, 
              style: TextStyle(color: subtitleColor, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.job.salaryRange, 
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Salary range (monthly)",
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 30),
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: subtitleColor,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: "Job Description"),
                Tab(text: "Our Gallery"),
              ],
            ),
            const SizedBox(height: 20),
            [
              _buildJobDescriptionTab(titleColor, subtitleColor), 
              _buildOurGalleryTab(titleColor), 
            ][_tabController.index],
          ],
        ),
      ),
      
      // Hanya tampilkan tombol Apply jika role == 'job_seeker'
      bottomNavigationBar: _userRole == 'job_seeker' 
          ? _buildBottomBar(context, primaryColor, subtitleColor)
          : null, 
    );
  }

  // ... (Widget _buildTag, _buildJobDescriptionTab, _buildRequirementRow, _buildBottomBar, _buildOurGalleryTab SAMA SEPERTI SEBELUMNYA)
  Widget _buildTag(String text, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildJobDescriptionTab(Color titleColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.job.description,
          style: TextStyle(color: subtitleColor, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 20),
        Text(
          "Requirements",
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        if (widget.job.requirements.isNotEmpty)
          ...widget.job.requirements.map((req) => _buildRequirementRow(req, subtitleColor)).toList()
        else
          Text("No specific requirements.", style: TextStyle(color: subtitleColor)),
      ],
    );
  }

  Widget _buildRequirementRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Color primaryColor, Color subtitleColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _isBookmarked
                    ? const Color.fromARGB(55, 255, 255, 255).withOpacity(0.1)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isBookmarked
                      ? const Color.fromARGB(73, 53, 53, 52)
                      : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked ? Colors.yellow[800] : Colors.grey,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showApplySheet(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "APPLY JOB",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOurGalleryTab(Color titleColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GalleryScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: titleColor),
            const SizedBox(width: 10),
            Text(
              "View Gallery",
              style: TextStyle(
                color: titleColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}