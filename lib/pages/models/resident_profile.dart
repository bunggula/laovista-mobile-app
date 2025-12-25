class ResidentProfile {
  final String name;
  final String birthdate;
  final int age;
  final String gender;
  final String civilStatus;
  final String address;
  final String phone;
  final String email;

  ResidentProfile({
    required this.name,
    required this.birthdate,
    required this.age,
    required this.gender,
    required this.civilStatus,
    required this.address,
    required this.phone,
    required this.email,
  });

  factory ResidentProfile.fromJson(Map<String, dynamic> json) {
    return ResidentProfile(
      name: '${json['first_name']} ${json['middle_name'] ?? ''} ${json['last_name']} ${json['suffix'] ?? ''}'.trim(),
      birthdate: json['birthdate'],
      age: json['age'],
      gender: json['gender'],
      civilStatus: json['civil_status'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
    );
  }
}
