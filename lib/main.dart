import 'package:attendance_system_fr_v3/attendance_dashboard/attendance_dashboard.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'db/supabase_db_helper.dart';
import 'login/login_page.dart';
import 'model/account.dart';
import 'model/setting.dart';
import 'persistence_storage/secure_storage_service.dart';

late List<CameraDescription> cameras;
SupabaseDbHelper dbHelper = SupabaseDbHelper();

Future<Account?> getAccountById(int id) async {
  final response =
      await dbHelper.getRowByField('accounts', 'id', id, Account.fromMap);

  if (response != null) {
    return response;
  }
  return null;
}

Future<List<Setting>> getSystemSettings() async {
  List<Setting> systemSettings = [];

  try {
    final response = await dbHelper.getAllRows(
        'system_settings', (row) => Setting.fromMap(row));
    systemSettings = response;
  } catch (e) {
    debugPrint("Failed to fetch system settings: $e");
  }
  return systemSettings;
}

Future<Widget> getInitialScreen() async {
  final secureStorage = SecureStorageService();
  final accountId = await secureStorage.getLoggedInAccountId();

  if (accountId != null) {
    final int actualAccountId = int.parse(accountId);
    final account = await getAccountById(actualAccountId);
    if (account != null) {
      final settings = await getSystemSettings();
      return AttendanceDashboard(account: account, systemSettings: settings);
    }
  }

  return const LoginPage();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint(".env is initialized");
  } catch (e) {
    throw ".env is not initialized: $e";
  }

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY']!,
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_ID']!,
        appId: dotenv.env['FIREBASE_APP_ID']!,
      ),
    );
    debugPrint("Firebase is initialized");
  } catch (e) {
    throw "Firebase is not initialized: $e";
  }

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint("Connected to Supabase");
  } catch (e) {
    throw "Connection failed: $e";
  }

  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Created by 629 (Izzul)');
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        title: 'Attendance with Face Recognition',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FutureBuilder<Widget>(
          future: getInitialScreen(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return snapshot.data!;
            } else {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }
}
