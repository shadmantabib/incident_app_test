import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';  // Import video_player package
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/incident_form_page.dart';
import 'pages/splash_screen.dart';
import 'utils/app_theme.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log error
    print('Global error caught: ${details.exception}');
    print('Stack trace: ${details.stack}');
    
    // You can report to error tracking service here
    
    // In release mode, present a user-friendly error
    if (WidgetsBinding.instance.buildOwner != null) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In debug mode, show the full error
      FlutterError.presentError(details);
    }
  };
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Incident Reporting App',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/incident-form': (context) => const IncidentFormPage(),
      },
      debugShowCheckedModeBanner: false,
      // Add error widget customization
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 60),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The app encountered an error. Please try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          );
        };
        
        // Return the widget
        return widget ?? Container();
      },
    );
  }
}