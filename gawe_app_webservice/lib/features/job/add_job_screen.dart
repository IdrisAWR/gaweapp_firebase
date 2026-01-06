// lib/features/job/add_job_screen.dart
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:coba_1/shared_widgets/custom_form_field.dart';
import 'package:coba_1/core/services/job_service.dart';
import 'package:coba_1/core/models/job_model.dart';

class AddJobScreen extends StatefulWidget {
  final JobModel? jobToEdit; // Parameter Opsional untuk Edit

  const AddJobScreen({Key? key, this.jobToEdit}) : super(key: key);

  @override
  _AddJobScreenState createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final JobService _jobService = JobService();
  
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _reqController = TextEditingController(); 

  // Variable untuk Gambar
  File? _logoFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Cek apakah ini mode Edit?
    if (widget.jobToEdit != null) {
      _isEditing = true;
      _titleController.text = widget.jobToEdit!.jobTitle;
      _locationController.text = widget.jobToEdit!.location;
      _salaryController.text = widget.jobToEdit!.salaryRange;
      _descController.text = widget.jobToEdit!.description;
      _reqController.text = widget.jobToEdit!.requirements.join(', ');
    }
  }

  // --- FUNGSI PILIH GAMBAR ---
  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
      });
    }
  }

  void _handleSubmit() async {
    if (_titleController.text.isEmpty || 
        _locationController.text.isEmpty || 
        _salaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all main fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> reqList = _reqController.text.split(',').map((e) => e.trim()).toList();

      if (_isEditing) {
        // --- LOGIKA UPDATE ---
        // (Saat ini update logo belum diaktifkan di service agar simpel, jadi hanya text)
        await _jobService.updateJob(widget.jobToEdit!.jobId, {
          'job_title': _titleController.text,
          'location': _locationController.text,
          'salary_range': _salaryController.text,
          'description': _descController.text,
          'requirements': reqList,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job Updated Successfully!"), backgroundColor: Colors.green),
        );
      } else {
        // --- LOGIKA ADD BARU ---
        await _jobService.addJob(
          jobTitle: _titleController.text,
          location: _locationController.text,
          salaryRange: _salaryController.text,
          description: _descController.text,
          requirements: reqList,
          logoFile: _logoFile, // <--- Kirim file logo ke Service
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job Posted Successfully!"), backgroundColor: Colors.green),
        );
      }

      if (mounted) {
        Navigator.pop(context); // Kembali
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Job" : "Post a New Job"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- UI UPLOAD LOGO ---
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                    // Tampilkan gambar: File Baru > URL Lama > Kosong
                    image: _logoFile != null 
                      ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover)
                      : (_isEditing && widget.jobToEdit?.companyLogoUrl != null)
                          ? DecorationImage(image: NetworkImage(widget.jobToEdit!.companyLogoUrl!), fit: BoxFit.cover)
                          : null,
                  ),
                  child: (_logoFile == null && (!_isEditing || widget.jobToEdit?.companyLogoUrl == null))
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, color: Colors.grey),
                          SizedBox(height: 5),
                          Text("Add Logo", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Job Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            CustomFormField(hintText: "Job Title", controller: _titleController),
            const SizedBox(height: 15),
            CustomFormField(hintText: "Location", controller: _locationController),
            const SizedBox(height: 15),
            CustomFormField(hintText: "Salary Range", controller: _salaryController),
            const SizedBox(height: 15),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Job Description..."),
              ),
            ),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: TextField(
                controller: _reqController,
                maxLines: 3,
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Requirements (Separate with comma , )"),
              ),
            ),
            
            const SizedBox(height: 30),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9634FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _isEditing ? "UPDATE JOB" : "POST JOB",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}