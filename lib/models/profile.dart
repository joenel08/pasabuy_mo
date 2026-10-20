class Profile {
  final String lastname, firstname, middlename, extname;
  final String streetPurok, barangay, cityMunicipality, province, country, zipCode;
  final String? avatarUrl;

  Profile({
    required this.lastname, required this.firstname,
    required this.middlename, required this.extname,
    required this.streetPurok, required this.barangay,
    required this.cityMunicipality, required this.province,
    required this.country, required this.zipCode,
    this.avatarUrl,
  });

  String get fullName {
    final parts = [firstname, middlename, lastname, extname]
        .where((p) => p.trim().isNotEmpty).toList();
    return parts.join(' ');
  }

  String get initials {
    final f = firstname.isNotEmpty ? firstname[0] : '';
    final l = lastname.isNotEmpty ? lastname[0] : '';
    return ('$f$l').toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        lastname: j['lastname'] ?? '',
        firstname: j['firstname'] ?? '',
        middlename: j['middlename'] ?? '',
        extname: j['extname'] ?? '',
        streetPurok: j['street_purok'] ?? '',
        barangay: j['barangay'] ?? '',
        cityMunicipality: j['city_municipality'] ?? '',
        province: j['province'] ?? '',
        country: j['country'] ?? '',
        zipCode: j['zip_code'] ?? '',
        avatarUrl: j['avatar_url'],
      );
}