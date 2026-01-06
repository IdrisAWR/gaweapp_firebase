// lib/core/models/application_model.dart

class ApplicationModel {
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String applicantId; // ID Job Seeker
  final String applicantName;
  final String applicantEmail;
  final String companyId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime appliedAt;

  ApplicationModel({
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.companyId,
    required this.status,
    required this.appliedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'job_title': jobTitle,
      'applicant_id': applicantId,
      'applicant_name': applicantName,
      'applicant_email': applicantEmail,
      'company_id': companyId,
      'status': status,
      'applied_at': appliedAt.toIso8601String(),
    };
  }
}