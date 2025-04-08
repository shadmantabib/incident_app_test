import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? currentUser;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final user = await AuthService().getCurrentUser();
      
      if (mounted) {
        setState(() {
          currentUser = user;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading user data: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _logout() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      await AuthService().logout();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error logging out: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incident Reporting"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: isLoading ? null : _logout,
          ),
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome message with user email
                    Text(
                      "Welcome, ${currentUser?.email ?? 'User'}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App logo or icon
                    const Icon(
                      Icons.report_problem_rounded,
                      size: 100,
                      color: Colors.amber,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      "Incident Reporting",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const Text(
                      "Report issues, upload evidence, and track resolution",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        label: const Text(
                          "REPORT NEW INCIDENT",
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, "/incident-form");
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Would be implemented for viewing past incidents
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.history, size: 24),
                        label: const Text(
                          "VIEW MY REPORTS",
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          // This would navigate to a history page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("This feature is coming soon!"),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
      // Add floating action button for quick reporting
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/incident-form");
        },
        tooltip: 'Report Incident',
        child: const Icon(Icons.add),
      ),
    );
  }
}