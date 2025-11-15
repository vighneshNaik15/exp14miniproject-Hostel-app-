import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Services
import 'package:miniproject/services/auth_service.dart';

// Auth Screens
import 'package:miniproject/screens/auth/login_screen.dart';

// Dashboard + Features
import 'package:miniproject/screens/dashboard/dashboard_screen.dart';
import 'package:miniproject/screens/complaints/add_complaint.dart';
import 'package:miniproject/screens/complaints/complaint_list.dart';
import 'package:miniproject/screens/notices/notices_screen.dart';

// API Screens
import 'package:miniproject/screens/news/news_screen.dart';
import 'package:miniproject/screens/weather/weather_screen.dart';
import 'package:miniproject/screens/holidays/holidays_screen.dart';

// Profile
import 'package:miniproject/screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hostel App',

        // 🌙 Light + Dark Theme
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,

        initialRoute: '/',

        routes: {
          '/': (context) => LoginScreen(),
          '/dashboard': (context) => DashboardScreen(),

          // Complaints
          '/addComplaint': (context) => AddComplaintScreen(),
          '/complaintList': (context) => ComplaintListScreen(),
          '/notices': (context) => NoticesScreen(),

          // API screens (NO CONST)
          '/news': (context) => NewsScreen(),
          '/weather': (context) => WeatherScreen(),
          '/holidays': (context) => HolidaysScreen(),

          // Profile
          '/profile': (context) => ProfileScreen(),
        },
      ),
    );
  }
}
