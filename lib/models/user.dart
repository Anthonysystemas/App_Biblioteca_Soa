class User {
  final String id;
  final String name;
  final String email;
  final String? profileImage; // Ruta local o URL de la foto de perfil
  final String? phone;
  final String? address;
  final DateTime? birthDate;
  final String? carnetNumber; // Número de carnet/identificación
  final String userType; // 'estudiante', 'profesor', 'publico'
  final DateTime registrationDate;
  final String membershipLevel; // 'basico', 'premium', 'vip'
  final bool isActive;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.phone,
    this.address,
    this.birthDate,
    this.carnetNumber,
    this.userType = 'publico',
    DateTime? registrationDate,
    this.membershipLevel = 'basico',
    this.isActive = true,
  }) : registrationDate = registrationDate ?? DateTime.now();
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      phone: json['phone'],
      address: json['address'],
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate']) 
          : null,
      carnetNumber: json['carnetNumber'],
      userType: json['userType'] ?? 'publico',
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'])
          : DateTime.now(),
      membershipLevel: json['membershipLevel'] ?? 'basico',
      isActive: json['isActive'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'phone': phone,
      'address': address,
      'birthDate': birthDate?.toIso8601String(),
      'carnetNumber': carnetNumber,
      'userType': userType,
      'registrationDate': registrationDate.toIso8601String(),
      'membershipLevel': membershipLevel,
      'isActive': isActive,
    };
  }
  
  // Método para crear copia con cambios
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? carnetNumber,
    String? userType,
    DateTime? registrationDate,
    String? membershipLevel,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      carnetNumber: carnetNumber ?? this.carnetNumber,
      userType: userType ?? this.userType,
      registrationDate: registrationDate ?? this.registrationDate,
      membershipLevel: membershipLevel ?? this.membershipLevel,
      isActive: isActive ?? this.isActive,
    );
  }
  
  // Calcular edad
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
  
  // Tiempo como miembro
  String get membershipDuration {
    final duration = DateTime.now().difference(registrationDate);
    if (duration.inDays < 30) {
      return '${duration.inDays} días';
    } else if (duration.inDays < 365) {
      return '${(duration.inDays / 30).floor()} meses';
    } else {
      return '${(duration.inDays / 365).floor()} años';
    }
  }
}