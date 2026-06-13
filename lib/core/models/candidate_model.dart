class Candidate {
  final String id;          // Firestore document ID
  final String candidateId; // candidate_id field
  final String name;
  final int age;
  final String qualification;
  final String experience;
  final String bio;
  final String achievements;
  final String slogan;
  final List<String> goals;
  final String image;

  const Candidate({
    required this.id,
    required this.candidateId,
    required this.name,
    required this.age,
    required this.qualification,
    required this.experience,
    required this.bio,
    required this.achievements,
    required this.slogan,
    required this.goals,
    required this.image,
  });

  factory Candidate.fromFirestore(String id, Map<String, dynamic> data) {
    return Candidate(
      id:            id,
      candidateId:   data['candidate_id']   as String? ?? id,
      name:          data['name']            as String? ?? '',
      age:           (data['age'] as num?)?.toInt() ?? 0,
      qualification: data['qualification']   as String? ?? '',
      experience:    data['experience']      as String? ?? '',
      bio:           data['bio']             as String? ?? '',
      achievements:  data['achievements']    as String? ?? '',
      slogan:        data['slogan']          as String? ?? '',
      goals:         _parseGoals(data['goals']),
      image:         data['image']           as String? ?? '',
    );
  }

  static List<String> _parseGoals(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[،,\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}
