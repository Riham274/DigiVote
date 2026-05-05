class Candidate {
  final String id;
  final String name;
  final String nameAr;
  final String dateOfBirth;
  final String description;
  final String affiliation;
  final String qualification;
  final String experience;
  final String district;
  final List<String> goals;
  final String image;

  const Candidate({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.dateOfBirth,
    required this.description,
    required this.affiliation,
    required this.qualification,
    required this.experience,
    required this.district,
    required this.goals,
    required this.image,
  });

  factory Candidate.fromFirestore(String id, Map<String, dynamic> data) {
    return Candidate(
      id: id,
      name: data['name'] as String? ?? '',
      nameAr: data['name_ar'] as String? ?? '',
      dateOfBirth: data['date_of_birth'] as String? ?? '',
      description: data['description'] as String? ?? '',
      affiliation: data['affiliation'] as String? ?? '',
      qualification: data['qualification'] as String? ?? '',
      experience: data['experience'] as String? ?? '',
      district: data['district'] as String? ?? '',
      goals: _parseGoals(data['goals']),
      image: data['image'] as String? ?? '',
    );
  }

  static List<String> _parseGoals(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      // Split by Arabic comma ،  regular comma ,  or newline
      return value
          .split(RegExp(r'[،,\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}
