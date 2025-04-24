import 'package:created_by_618_abdo/model/setting.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../attendance_dashboard/attendance_dashboard.dart';
import '../db/supabase_db_helper.dart';
import '../model/account.dart';
import '/Login/LoginService.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  TextEditingController inputController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  String? countryCode = '+60';
  bool isEmailSelected = true;
  LoginService loginService = LoginService();
  Account? loggedInAccount;
  late List<Setting> systemSettings;
  final dbHelper = SupabaseDbHelper();

  @override
  void dispose() {
    inputController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> requestOtp() async {
    String input = isEmailSelected
        ? inputController.text.trim()
        : phoneController.text.trim();

    if (input.isEmpty) {
      _showDialog("Empty", "Please enter a valid email or phone number.");
      return;
    }

    // Optionally, add more validation for email or phone number here

    String fullInput = isEmailSelected ? input : "$countryCode$input";

    final account = await loginService.getData(fullInput);

    if (account != null) {
      loggedInAccount = account;
      _showOtpDialog();
    } else {
      _showDialog("Error", "Account doesn't exist.");
    }
  }

  Future<List<Setting>> getSystemSetting() async {
    try {
      systemSettings = await dbHelper.getAllRows<Setting>(
          'system_settings', Setting.fromMap);
    } catch (e) {
      debugPrint("Something went wrong when trying to get system settings");
    }
    return systemSettings;
  }

  Future<void> signIn(String otp) async {
    if (otp.length != 6) {
      _showDialog("Invalid OTP", "OTP must have 6 numbers.");
      return;
    }

    systemSettings = await getSystemSetting();
    if (loggedInAccount != null) {
      final account = loggedInAccount!;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => AttendanceDashboard(
                account: account, systemSettings: systemSettings)),
      );
      loginService.updateOTP(account.id!, "");
    } else {
      _showDialog("Error", "Please request OTP first.");
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showOtpDialog() {
    TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent closing the dialog by tapping outside
      builder: (context) => AlertDialog(
        title: const Text("Enter OTP"),
        content: TextField(
          controller: otpController,
          decoration: const InputDecoration(
            labelText: "OTP",
            hintText: "Enter the 6-digit OTP",
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String otp = otpController.text.trim();
              Navigator.pop(context); // Close the dialog
              signIn(otp);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth < 600
        ? screenWidth * 0.9
        : 400; // Responsive container width

    return Scaffold(
      backgroundColor: Colors.lightBlueAccent, // Bright blue background
      body: Stack(
        children: [
          // Optional: Remove or adjust the starry background
          // _buildStarryBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Attendance with Face Recognition",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize:
                            screenWidth < 600 ? 32 : 40, // Responsive font size
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      width: containerWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          _buildEmailPhoneToggle(),
                          const SizedBox(height: 20),
                          isEmailSelected
                              ? _buildEmailField()
                              : _buildPhoneField(),
                          const SizedBox(height: 30),
                          _buildRequestOtpButton(), // Updated button
                        ],
                      ),
                    ),
                    const SizedBox(
                        height: 10), // Add some space before the copyright text
                    Text(
                      "Copyright (v3)",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize:
                            screenWidth < 400 ? 20 : 10, // Responsive font size
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPhoneToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isEmailSelected = true;
              phoneController.clear();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isEmailSelected ? Colors.blueAccent : Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.email, color: Colors.white),
                SizedBox(width: 8),
                Text("Email", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            setState(() {
              isEmailSelected = false;
              inputController.clear();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: !isEmailSelected ? Colors.blueAccent : Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.phone, color: Colors.white),
                SizedBox(width: 8),
                Text("Phone", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: inputController,
      decoration: const InputDecoration(
        labelText: "Email",
        hintText: "Enter email",
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: phoneController,
      disableLengthCheck: true, // Disable length validation
      decoration: const InputDecoration(
        labelText: "Phone",
        hintText: "Enter phone number",
        prefixIcon: Icon(Icons.phone),
        border: OutlineInputBorder(),
      ),
      initialCountryCode: 'MY',
      onChanged: (phone) {
        setState(() {
          countryCode = phone.countryCode;
        });
      },
    );
  }

  Widget _buildRequestOtpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: requestOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent, // Adjust if needed
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "Request OTP",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white, // White text color
          ),
        ),
      ),
    );
  }
}
