class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String country;
  final String countryCode;
  final String city;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.country,
    required this.countryCode,
    required this.city,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'country': country,
    'countryCode': countryCode,
    'city': city,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as String,
    firstName: map['firstName'] as String,
    lastName: map['lastName'] as String,
    email: map['email'] as String,
    phoneNumber: map['phoneNumber'] as String,
    country: map['country'] as String,
    countryCode: map['countryCode'] as String,
    city: map['city'] as String,
  );
}
