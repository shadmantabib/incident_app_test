import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:video_player/video_player.dart';
import '../services/api_services.dart';

class IncidentFormPage extends StatefulWidget {
  const IncidentFormPage({super.key});

  @override
  State<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends State<IncidentFormPage> with SingleTickerProviderStateMixin {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final livestreamUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Tab controller
  late TabController _tabController;
  
  // Multiple photos
  List<File> _pickedImages = [];
  
  // Video file
  File? _videoFile;
  VideoPlayerController? _videoPlayerController;
  
  // Location
  double? latitude;
  double? longitude;
  
  // State flags
  bool isSubmitting = false;
  bool isGettingLocation = false;
  bool isLiveStreaming = false;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 3 tabs
    _tabController = TabController(length: 3, vsync: this);
    
    // Add listener to update isLiveStreaming flag when tab changes
    _tabController.addListener(() {
      setState(() {
        isLiveStreaming = _tabController.index == 2;
      });
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    livestreamUrlController.dispose();
    _videoPlayerController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(pickedFiles.map((xFile) => File(xFile.path)).toList());
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking images: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Future<void> takePicture() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() {
          _pickedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error taking photo: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    }
  }
  
  Future<void> pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedVideo = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (pickedVideo != null) {
        final videoFile = File(pickedVideo.path);
        setState(() {
          _videoFile = videoFile;
        });
        
        // Initialize video player
        _initializeVideoPlayer(videoFile);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking video: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    }
  }
  
  Future<void> recordVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? recordedVideo = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (recordedVideo != null) {
        final videoFile = File(recordedVideo.path);
        setState(() {
          _videoFile = videoFile;
        });
        
        // Initialize video player
        _initializeVideoPlayer(videoFile);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error recording video: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    }
  }
  
  void _initializeVideoPlayer(File videoFile) {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  Future<void> getLocation() async {
    setState(() {
      isGettingLocation = true;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        if (!mounted) return;
        
        setState(() {
          isGettingLocation = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location services are disabled. Please enable them in settings."),
            backgroundColor: Colors.red,
          )
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          
          setState(() {
            isGettingLocation = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Location permissions are denied. Please allow location access."),
              backgroundColor: Colors.red,
            )
          );
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      if (!mounted) return;
      
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        isGettingLocation = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location obtained successfully"),
          backgroundColor: Colors.green,
        )
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isGettingLocation = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error getting location: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Future<void> submitIncident() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      isSubmitting = true;
    });
    
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    
    try {
      final apiService = ApiService();
      ApiResponse response;
      
      // Handle different submission types based on the active tab
      if (isLiveStreaming) {
        // Submit with livestream URL
        final livestreamUrl = livestreamUrlController.text.trim();
        response = await apiService.createLivestreamIncident(
          title: title,
          description: description,
          latitude: latitude ?? 0.0,
          longitude: longitude ?? 0.0,
          livestreamUrl: livestreamUrl,
        );
        
        handleSubmissionResponse(response, "Livestream incident reported successfully!");
      } else if (_tabController.index == 1 && _videoFile != null) {
        // Submit with video
        response = await apiService.createIncidentWithVideo(
          title: title,
          description: description,
          latitude: latitude ?? 0.0,
          longitude: longitude ?? 0.0,
          videoPath: _videoFile!.path,
        );
        
        handleSubmissionResponse(response, "Incident with video reported successfully!");
      } else if (_tabController.index == 0 && _pickedImages.isNotEmpty) {
        // Submit with multiple images
        if (_pickedImages.length > 1) {
          response = await apiService.createIncidentWithMultipleFiles(
            title: title,
            description: description,
            latitude: latitude ?? 0.0,
            longitude: longitude ?? 0.0,
            filePaths: _pickedImages.map((file) => file.path).toList(),
          );
          
          handleSubmissionResponse(response, "Incident with images reported successfully!");
        } else {
          // Submit with a single image
          response = await apiService.createIncidentWithFile(
            title: title,
            description: description,
            latitude: latitude ?? 0.0,
            longitude: longitude ?? 0.0,
            filePath: _pickedImages[0].path,
          );
          
          handleSubmissionResponse(response, "Incident with image reported successfully!");
        }
      } else {
        // Submit without files
        response = await apiService.createIncidentWithoutFile(
          title: title,
          description: description,
          latitude: latitude ?? 0.0,
          longitude: longitude ?? 0.0,
        );
        
        handleSubmissionResponse(response, "Incident reported successfully!");
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error reporting incident: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    }
  }
  
  void handleSubmissionResponse(ApiResponse response, String successMessage) {
    if (!mounted) return;
    
    setState(() {
      isSubmitting = false;
    });
    
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
        )
      );
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to report incident: ${response.errorMessage}"),
          backgroundColor: Colors.red,
        )
      );
    }
  }
  
  void removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Incident"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.photo_library),
              text: "Photos",
            ),
            Tab(
              icon: Icon(Icons.videocam),
              text: "Video",
            ),
            Tab(
              icon: Icon(Icons.live_tv),
              text: "Livestream",
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Photos Tab
            _buildPhotoTabContent(),
            // Video Tab
            _buildVideoTabContent(),
            // Livestream Tab
            _buildLivestreamTabContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhotoTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBasicInfoFields(),
          
          const SizedBox(height: 24),
          
          _buildLocationSection(),
          
          const SizedBox(height: 24),
          
          _buildPhotosSection(),
          
          const SizedBox(height: 32),
          
          _buildSubmitButton(),
        ],
      ),
    );
  }
  
  Widget _buildVideoTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBasicInfoFields(),
          
          const SizedBox(height: 24),
          
          _buildLocationSection(),
          
          const SizedBox(height: 24),
          
          _buildVideoSection(),
          
          const SizedBox(height: 32),
          
          _buildSubmitButton(),
        ],
      ),
    );
  }
  
  Widget _buildLivestreamTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBasicInfoFields(),
          
          const SizedBox(height: 24),
          
          _buildLocationSection(),
          
          const SizedBox(height: 24),
          
          _buildLivestreamSection(),
          
          const SizedBox(height: 32),
          
          _buildSubmitButton(),
        ],
      ),
    );
  }
  
  Widget _buildBasicInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title field
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: "Title",
            hintText: "Brief description of the incident",
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Description field
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: "Description",
            hintText: "Provide details about the incident",
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Location (Optional)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Location status and button
            Row(
              children: [
                Expanded(
                  child: latitude != null && longitude != null
                      ? Text("Lat: ${latitude!.toStringAsFixed(6)}, Lng: ${longitude!.toStringAsFixed(6)}")
                      : const Text("No location data", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: isGettingLocation ? null : getLocation,
                  icon: isGettingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.location_on),
                  label: const Text("Get Location"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhotosSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Photos (Optional)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Photo preview grid
            if (_pickedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _pickedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _pickedImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () => removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    "No photos selected",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Photo buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Video (Optional)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Video preview
            if (_videoFile != null && _videoPlayerController != null && _videoPlayerController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoPlayerController!),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _videoPlayerController!.value.isPlaying
                              ? _videoPlayerController!.pause()
                              : _videoPlayerController!.play();
                        });
                      },
                      icon: Icon(
                        _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _videoFile = null;
                            _videoPlayerController!.dispose();
                            _videoPlayerController = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    "No video selected",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Video buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickVideo,
                    icon: const Icon(Icons.video_library),
                    label: const Text("Choose Video"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: recordVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text("Record Video"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLivestreamSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Livestream",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              "Provide a URL to your livestream (e.g., YouTube, Twitch, etc.)",
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: livestreamUrlController,
              decoration: const InputDecoration(
                labelText: "Livestream URL",
                hintText: "https://...",
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (isLiveStreaming) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a livestream URL';
                  }
                  if (!Uri.parse(value).isAbsolute) {
                    return 'Please enter a valid URL';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Guidance text
            const Text(
              "Note: Submit the incident along with this livestream URL. The authorities will be able to access your live feed.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : submitIncident,
        child: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SUBMIT REPORT",
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}