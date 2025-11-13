import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/logger.dart';
import 'providers/dashboard_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  AppLogger.init(enableInProduction: false);
  AppLogger.i('App starting...');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notifications
  try {
    await NotificationService().initialize();
    AppLogger.i('Notifications initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.e('Failed to initialize notifications', e, stackTrace);
    // Don't crash the app if notifications fail to initialize
  }
  
  runApp(const SnapBudgetApp());
}

class SnapBudgetApp extends StatelessWidget {
  const SnapBudgetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'SnapBudget',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          brightness: Brightness.light,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}