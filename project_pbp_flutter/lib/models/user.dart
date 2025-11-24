class User {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final double? totalHutang;
  final int? jumlahHutang;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.photoUrl,
    this.totalHutang,
    this.jumlahHutang,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      photoUrl: json['photoUrl'],
      totalHutang: json['totalHutang']?.toDouble(),
      jumlahHutang: json['jumlahHutang'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'photoUrl': photoUrl,
      'totalHutang': totalHutang,
      'jumlahHutang': jumlahHutang,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}