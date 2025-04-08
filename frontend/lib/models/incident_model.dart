class Incident {
  final String? id;
  final String? title;
  final String? description;
  final String? location;
  final String? status;
  final String? userId;
  final DateTime? createdAt;
  final double? latitude;   // Add these
  final double? longitude;  // Add these
  final String? filePath;   // Add these
  
  Incident({
    this.id,
    this.title,
    this.description,
    this.location,
    this.status,
    this.userId,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.filePath,
  });
  
  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      status: json['status'],
      userId: json['userId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      latitude: json['latitude'],
      longitude: json['longitude'],
      filePath: json['filePath'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'status': status,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'filePath': filePath,
    };
  }
}