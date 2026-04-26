class UserModel {
  final String name;
  final String nationalId;
  final String birthDate;
  final String gender;
  final String address;
  final String role;
  final String profileImage;

  UserModel({
    required this.name,
    required this.nationalId,
    required this.birthDate,
    required this.gender,
    required this.address,
    required this.role,
    this.profileImage = 'assets/images/image_6.jpg',
  });

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
