// lib/features/job/widgets/apply_job_sheet.dart
import 'package:flutter/material.dart';
import 'package:coba_1/shared_widgets/custom_form_field.dart';
import 'package:coba_1/core/models/job_model.dart'; // Import Model
import 'package:coba_1/core/services/job_service.dart'; // Import Service

class ApplyJobSheet extends StatefulWidget {
  final JobModel job; // Menerima data Job

  const ApplyJobSheet({Key? key, required this.job}) : super(key: key);

  @override
  _ApplyJobSheetState createState() => _ApplyJobSheetState();
}

class _ApplyJobSheetState extends State<ApplyJobSheet> {
  final JobService _jobService = JobService();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  void _submitApplication() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in Name and Email")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil Service Apply
      await _jobService.applyJob(
        widget.job, 
        _nameController.text, 
        _emailController.text
      );

      if (mounted) {
        Navigator.pop(context); // Tutup sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application Sent Successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Judul Sheet (Opsional, agar user tahu melamar ke mana)
          Text(
            "Apply for ${widget.job.jobTitle}",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
          ),
          const SizedBox(height: 20),

          // Form Fields (Pasang Controller)
          CustomFormField(hintText: "User Name", controller: _nameController),
          const SizedBox(height: 20),
          CustomFormField(hintText: "Email Address", controller: _emailController),
          const SizedBox(height: 20),
          CustomFormField(hintText: "Phone number", controller: _phoneController),
          const SizedBox(height: 30),

          // Tombol Submit
          ElevatedButton(
            onPressed: _isLoading ? null : _submitApplication,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  "SUBMIT",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10), 
        ],
      ),
    );
  }
}