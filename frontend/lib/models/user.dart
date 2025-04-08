class User {
  final int? id;  // Change from String? to int?
  final String? name;
  final String? email;
  final String? token;
  
  User({
    this.id,
    this.name,
    this.email,
    this.token,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],  // This will now accept an int
      name: json['name'],
      email: json['email'],
      token: json['token'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
    };
  }
}