// lib/core/models/job_model.dart

class JobModel {
  final String jobId;
  final String companyId;
  final String companyName;
  final String jobTitle;
  final String location;
  final String salaryRange;
  final String description;
  final List<String> requirements;
  final DateTime createdAt;
  final String? companyLogoUrl; 

  JobModel({
    required this.jobId,
    required this.companyId,
    required this.companyName,
    required this.jobTitle,
    required this.location,
    required this.salaryRange,
    required this.description,
    required this.requirements,
    required this.createdAt,
    this.companyLogoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'company_id': companyId,
      'company_name': companyName,
      'job_title': jobTitle,
      'location': location,
      'salary_range': salaryRange,
      'description': description,
      'requirements': requirements,
      'created_at': createdAt.toIso8601String(),
      'company_logo_url': companyLogoUrl, 
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> data, String id) {
    return JobModel(
      jobId: id,
      companyId: data['company_id'] ?? '',
      companyName: data['company_name'] ?? '',
      jobTitle: data['job_title'] ?? '',
      location: data['location'] ?? '',
      salaryRange: data['salary_range'] ?? '',
      description: data['description'] ?? '',
      requirements: List<String>.from(data['requirements'] ?? []),
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      companyLogoUrl: data['company_logo_url'], 
    );
  }
}