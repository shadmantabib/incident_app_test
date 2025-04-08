import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/incident_model.dart';
import 'auth_service.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  
  ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
  });
}

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // HTTP client with timeout
  final http.Client _client = http.Client();
  
  // Registration
  Future<ApiResponse<User>> registerUser(String email, String password) async {
    try {
      print("Attempting to register at: ${Constants.baseUrl}${Constants.registerEndpoint}");
      final url = Uri.parse("${Constants.baseUrl}${Constants.registerEndpoint}");
      final response = await _client.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 10));
      
      print("Registration response status: ${response.statusCode}");
      print("Registration response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData["msg"] == "User registered") {
          // Make sure we're getting an int
          final userId = responseData["user_id"] is String 
              ? int.tryParse(responseData["user_id"]) 
              : responseData["user_id"];
          
          return ApiResponse(
            success: true,
            data: User(id: userId, email: email),
          );
        } else {
          return ApiResponse(
            success: false,
            errorMessage: responseData["msg"] ?? "Unknown error",
          );
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          errorMessage: errorData["detail"] ?? "Registration failed with status ${response.statusCode}",
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        errorMessage: "No internet connection. Please check your network.",
      );
    } on http.ClientException catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: "Connection error: ${e.message}",
      );
    } on FormatException {
      return ApiResponse(
        success: false,
        errorMessage: "Invalid response format from server",
      );
    } catch (e) {
      print("Registration error: $e");
      return ApiResponse(
        success: false,
        errorMessage: "An unexpected error occurred: ${e.toString()}",
      );
    }
  }
  
  // Login
  Future<ApiResponse<User>> loginUser(String email, String password) async {
    try {
      print("Attempting login at: ${Constants.baseUrl}${Constants.loginEndpoint}");
      final url = Uri.parse("${Constants.baseUrl}${Constants.loginEndpoint}");
      final response = await _client.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 10));
      
      print("Login response status: ${response.statusCode}");
      print("Login response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData["msg"] == "Login successful") {
          // Make sure we're getting an int
          final userId = responseData["user_id"] is String 
              ? int.tryParse(responseData["user_id"]) 
              : responseData["user_id"];
          
          // Save user session
          final user = User(id: userId, email: email);
          await AuthService().saveUserSession(user);
          
          return ApiResponse(
            success: true,
            data: user,
          );
        } else {
          return ApiResponse(
            success: false,
            errorMessage: responseData["msg"] ?? "Unknown error",
          );
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          errorMessage: errorData["detail"] ?? "Login failed with status ${response.statusCode}",
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        errorMessage: "No internet connection. Please check your network.",
      );
    } on http.ClientException catch (e) {
      return ApiResponse(
        success: false,
        errorMessage: "Connection error: ${e.message}",
      );
    } on FormatException {
      return ApiResponse(
        success: false,
        errorMessage: "Invalid response format from server",
      );
    } catch (e) {
      print("Login error: $e");
      return ApiResponse(
        success: false,
        errorMessage: "An unexpected error occurred: ${e.toString()}",
      );
    }
  }
  
  // Create incident without file
  Future<ApiResponse<Incident>> createIncidentWithoutFile({
    required String title,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Get current user ID
      final userId = await AuthService().getUserId();
      if (userId == null) {
        return ApiResponse(
          success: false,
          errorMessage: "User not logged in",
        );
      }
      
      print("Creating incident at: ${Constants.baseUrl}${Constants.incidentsEndpoint}");
      final url = Uri.parse("${Constants.baseUrl}${Constants.incidentsEndpoint}");
      
      // Create request body
      Map<String, dynamic> requestBody = {
        "title": title,
        "description": description,
        "latitude": latitude ?? 0.0,
        "longitude": longitude ?? 0.0,
      };
      
      final response = await _client.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      print("Create incident response status: ${response.statusCode}");
      print("Create incident response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final incidentId = responseData["id"]?.toString() ?? responseData["incident_id"]?.toString();
        
        return ApiResponse(
          success: true,
          data: Incident(
            id: incidentId,
            title: title,
            description: description,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          errorMessage: errorData["detail"] ?? "Failed to create incident: ${response.statusCode}",
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        errorMessage: "No internet connection. Please check your network.",
      );
    } catch (e) {
      print("Create incident error: $e");
      return ApiResponse(
        success: false,
        errorMessage: "An error occurred: ${e.toString()}",
      );
    }
  }
  
  // Create incident with a single file
  Future<ApiResponse<Incident>> createIncidentWithFile({
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    required String filePath,
  }) async {
    try {
      // Get current user ID
      final userId = await AuthService().getUserId();
      if (userId == null) {
        return ApiResponse(
          success: false,
          errorMessage: "User not logged in",
        );
      }
      
      print("Uploading incident at: ${Constants.baseUrl}${Constants.incidentsEndpoint}");
      final url = Uri.parse("${Constants.baseUrl}${Constants.incidentsEndpoint}");
      var request = http.MultipartRequest('POST', url);
      
      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['latitude'] = (latitude ?? 0.0).toString();
      request.fields['longitude'] = (longitude ?? 0.0).toString();
      
      // Attach file
      final file = File(filePath);
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('media_file', filePath));
      } else {
        return ApiResponse(
          success: false,
          errorMessage: "File not found at $filePath",
        );
      }
      
      // Send request
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);
      
      print("Upload incident response status: ${response.statusCode}");
      print("Upload incident response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final incidentId = responseData["id"]?.toString() ?? responseData["incident_id"]?.toString();
        final mediaUrl = responseData["media_url"];
        
        return ApiResponse(
          success: true,
          data: Incident(
            id: incidentId,
            title: title,
            description: description,
            latitude: latitude,
            longitude: longitude,
            filePath: mediaUrl,
          ),
        );
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData["detail"] ?? "Failed to upload incident: ${response.statusCode}";
        } catch (e) {
          errorMessage = "Failed to upload incident: ${response.statusCode}";
        }
        
        return ApiResponse(
          success: false,
          errorMessage: errorMessage,
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        errorMessage: "No internet connection. Please check your network.",
      );
    } catch (e) {
      print("Upload incident error: $e");
      return ApiResponse(
        success: false,
        errorMessage: "An error occurred: ${e.toString()}",
      );
    }
  }
  
  // Create incident with video
  Future<ApiResponse<Incident>> createIncidentWithVideo({
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    required String videoPath,
  }) async {
    try {
      // Get current user ID
      final userId = await AuthService().getUserId();
      if (userId == null) {
        return ApiResponse(
          success: false,
          errorMessage: "User not logged in",
        );
      }
      
      print("Uploading video incident at: ${Constants.baseUrl}${Constants.incidentsEndpoint}");
      final url = Uri.parse("${Constants.baseUrl}${Constants.incidentsEndpoint}");
      var request = http.MultipartRequest('POST', url);
      
      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['latitude'] = (latitude ?? 0.0).toString();
      request.fields['longitude'] = (longitude ?? 0.0).toString();
      
      // Attach video file
      final file = File(videoPath);
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('video_file', videoPath));
      } else {
        return ApiResponse(
          success: false,
          errorMessage: "Video file not found at $videoPath",
        );
      }
      
      // Send request
      var streamedResponse = await request.send().timeout(const Duration(seconds: 60)); // Longer timeout for video
      var response = await http.Response.fromStream(streamedResponse);
      
      print("Upload video incident response status: ${response.statusCode}");
      print("Upload video incident response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final incidentId = responseData["id"]?.toString() ?? responseData["incident_id"]?.toString();
        final videoUrl = responseData["video_url"];
        
        return ApiResponse(
          success: true,
          data: Incident(
            id: incidentId,
            title: title,
            description: description,
            latitude: latitude,
            longitude: longitude,
            filePath: videoUrl, // Using filePath to store video URL
          ),
        );
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData["detail"] ?? "Failed to upload video incident: ${response.statusCode}";
        } catch (e) {
          errorMessage = "Failed to upload video incident: ${response.statusCode}";
        }
        
        return ApiResponse(
          success: false,
          errorMessage: errorMessage,
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        errorMessage: "No internet connection. Please check your network.",
      );
    } catch (e) {
      print("Upload video incident error: $e");
      return ApiResponse(
        success: false,
        errorMessage: "An error occurred: ${e.toString()}",
      );
    }
  }
  
  // Create incident with livestream URL
  Future<ApiResponse<Incident>> createLivestreamIncident({
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    required String livestreamUrl,
  }) async {
    try {
      // Get current user ID
      final userId = await AuthService().getUserId();
      if (userId == null) {
        return ApiResponse(
          success: false,
          errorMessage: "User not logged in",
        );
      }
      
      print("Creating livestream incident at: ${Constants.baseUrl}${Constants.livestreamEndpoint}");
      final url = Uri.parse("${Constants.baseUrl}${Constants.livestreamEndpoint}");
      
      final response = await _client.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "title": title,
          "description": description,
          "latitude": latitude ?? 0.0,
          "longitude": longitude ?? 0.0,
          "livestream_url": livestreamUrl,
        }),
      ).timeout(const Duration(seconds: 15));
      
      print("Create livestream incident response status: ${response.statusCode}");
      print("Create livestream incident response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final incidentId = responseData["id"]?.toString() ?? responseData["incident_id"]?.toString();
        
        return ApiResponse(
          success: true,
          data: Incident(
            id: incidentId,
            title: title,
            description: description,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          errorMessage: errorData["detail"] ?? "Failed to create livestream incident: ${response.statusCode}",
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        errorMessage: "No internet connection. Please check your network.",
      );
    } catch (e) {
      print("Create livestream incident error: $e");
      return ApiResponse(
        success: false,
        errorMessage: "An error occurred: ${e.toString()}",
      );
    }
  }
  
  // Create incident with multiple files
  Future<ApiResponse<Incident>> createIncidentWithMultipleFiles({
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    required List<String> filePaths,
  }) async {
    try {
      // Get current user ID
      final userId = await AuthService().getUserId();
      if (userId == null) {
        return ApiResponse(
          success: false,
          errorMessage: "User not logged in",
        );
      }
      
      if (filePaths.isEmpty) {
        return createIncidentWithoutFile(
          title: title,
          description: description,
          latitude: latitude,
          longitude: longitude,
        );
      }
      
      print("Uploading multiple files incident at: ${Constants.baseUrl}${Constants.multiUploadEndpoint}");
      final url = Uri.parse("${Constants.baseUrl}${Constants.multiUploadEndpoint}");
      var request = http.MultipartRequest('POST', url);
      
      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['latitude'] = (latitude ?? 0.0).toString();
      request.fields['longitude'] = (longitude ?? 0.0).toString();
      
      // Attach files
      for (int i = 0; i < filePaths.length; i++) {
        final file = File(filePaths[i]);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('files', filePaths[i]));
        } else {
          print("File not found at ${filePaths[i]}, skipping");
          // Continue with valid files
        }
      }
      
      if (request.files.isEmpty) {
        return ApiResponse(
          success: false,
          errorMessage: "No valid files to upload",
        );
      }
      
      // Send request
      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);
      
      print("Upload multiple files incident response status: ${response.statusCode}");
      print("Upload multiple files incident response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final incidentId = responseData["id"]?.toString() ?? responseData["incident_id"]?.toString();
        
        return ApiResponse(
          success: true,
          data: Incident(
            id: incidentId,
            title: title,
            description: description,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData["detail"] ?? "Failed to upload multiple files: ${response.statusCode}";
        } catch (e) {
          errorMessage = "Failed to upload multiple files: ${response.statusCode}";
        }
        
        return ApiResponse(
          success: false,
          errorMessage: errorMessage,
        );
      }
    } on SocketException {
      return ApiResponse(
        success: false,
        errorMessage: "No internet connection. Please check your network.",
      );
    } catch (e) {
      print("Upload multiple files incident error: $e");
      return ApiResponse(
        success: false,
        errorMessage: "An error occurred: ${e.toString()}",
      );
    }
  }
  
  void dispose() {
    _client.close();
  }
}