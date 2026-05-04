class UserModel {
  final String name;
  final String nationalId;
  final String birthDate;
  final String gender;
  final String address;
  final String role;
  final String profileImage;
  final bool hasVoted;
  final String faceImageBase64;

  UserModel({
    required this.name,
    required this.nationalId,
    required this.birthDate,
    this.gender = '',
    this.address = '',
    this.role = 'user',
    this.profileImage = 'assets/images/image_6.jpg',
    this.hasVoted = false,
    this.faceImageBase64 = '',
  });

  factory UserModel.fromFirestore(String nationalId, Map<String, dynamic> data) {
    return UserModel(
      name: data['full_name'] as String? ?? '',
      nationalId: nationalId,
      birthDate: data['date_of_birth'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      address: data['address'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      hasVoted: data['has_voted'] as bool? ?? false,
      faceImageBase64: data['face_image_base64'] as String? ?? '',
    );
  }

  static UserModel mockUser() => UserModel(
    name: 'أحمد بن عبدالله العتيبي',
    nationalId: '1023948576',
    birthDate: '1990-05-15',
    gender: 'ذكر',
    address: 'الرياض، حي النرجس، شارع الملك فهد',
    role: 'user',
  );

  static UserModel mockAdmin() => UserModel(
    name: 'سارة خالد المحمد',
    nationalId: '1098765432',
    birthDate: '1985-11-20',
    gender: 'أنثى',
    address: 'الرياض، الإدارة العامة للانتخابات',
    role: 'admin',
  );
}
