class User {
  final int id;
  final String email;
  final String role;         // buyer | pasabuyer | admin
  final String status;       // pending | accepted | declined
  final bool emailVerified;
  final bool profileCompleted;
  final String kycStatus;    // none | pending | accepted | declined

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.profileCompleted,
    required this.kycStatus,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        email: j['email'],
        role: j['role'] ?? 'buyer',
        status: j['status'] ?? 'pending',
        emailVerified: j['email_verified'] ?? false,
        profileCompleted: j['profile_completed'] ?? false,
        kycStatus: j['kyc_status'] ?? 'none',
      );
}