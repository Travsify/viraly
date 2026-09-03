class UserProfile {
  final String id;
  final String role; // 'creator', 'agency', 'admin'
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? tiktokHandle;
  final String? bio;
  final bool isVerified;
  final bool bvnVerified;
  final String? bvnLast4;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.tiktokHandle,
    this.bio,
    required this.isVerified,
    required this.bvnVerified,
    this.bvnLast4,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'creator',
      fullName: json['full_name'] as String? ?? 'Viraly Member',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      tiktokHandle: json['tiktok_handle'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      bvnVerified: json['bvn_verified'] as bool? ?? false,
      bvnLast4: json['bvn_last4'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get isCreator => role == 'creator';
  bool get isAgency => role == 'agency';
  bool get isAdmin => role == 'admin';
}
