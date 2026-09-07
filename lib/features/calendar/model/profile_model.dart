class ProfileModel {
  final String name;
  final String birthDate; // 'yyyy-MM-dd'
  final String birthTime; // 'HH:mm'
  final String gender;

  const ProfileModel({
    this.name = 'Nguyễn Minh Anh',
    this.birthDate = '1994-08-12',
    this.birthTime = '07:30',
    this.gender = 'Nữ',
  });

  ProfileModel copyWith({String? name, String? birthDate, String? birthTime, String? gender}) {
    return ProfileModel(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      gender: gender ?? this.gender,
    );
  }
}
