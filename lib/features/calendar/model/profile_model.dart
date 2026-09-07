class ProfileModel {
  final String name;
  final String birthDate; // 'yyyy-MM-dd'
  final String birthTime; // 'HH:mm'
  final String gender;
  final bool nameEdited;
  final bool birthDateEdited;

  const ProfileModel({
    this.name = '',
    this.birthDate = '',
    this.birthTime = '',
    this.gender = 'Nam',
    this.nameEdited = false,
    this.birthDateEdited = false,
  });

  ProfileModel copyWith({
    String? name,
    String? birthDate,
    String? birthTime,
    String? gender,
    bool? nameEdited,
    bool? birthDateEdited,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      gender: gender ?? this.gender,
      nameEdited: nameEdited ?? this.nameEdited,
      birthDateEdited: birthDateEdited ?? this.birthDateEdited,
    );
  }
}
