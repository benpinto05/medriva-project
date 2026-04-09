// 24th feb main.dart

//main.dart
//flutter ui code



import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/doctor_patient_list.dart';
import 'screens/chatbot_page.dart';
import 'screens/patient_dashboard.dart';
import 'screens/profile_page.dart';


import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';




import 'package:flutter/services.dart'; // ✅ for loading asset
void main() {
  runApp(const MedrivaApp());
}
// Root widget of the application
// This sets up MaterialApp and initial screen (LoginPage)
class MedrivaApp extends StatelessWidget {
  const MedrivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}


// Login screen where users authenticate
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  // ✅ ONLY PDF PATH (no upload anymore)
  String? pdfPath;

  // ✅ Load doctor verification PDF from assets
  Future<void> loadAssetPDF() async {
    final bytes =
        await rootBundle.load('assets/docs/doctor_verification.pdf');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/doctor_verification.pdf');

    await file.writeAsBytes(bytes.buffer.asUint8List());

    setState(() {
      pdfPath = file.path;
    });
  }

  Future<void> login() async {
    setState(() => loading = true);

    final response =
        await ApiService.login(emailCtrl.text.trim(), passCtrl.text.trim());

    setState(() => loading = false);

    if (response["token"] != null) {
      final user = response["user"];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Dashboard(
            role: user["role"],
            userId: user["id"],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["error"] ?? "Login failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB0D3C2),
      body: Stack(
        children: [
          // Top Curved Green Section
          Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF295740),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            padding: const EdgeInsets.only(left: 30, top: 80),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Welcome to Medriva",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // ✅ ICON → VIEW DOCTOR VERIFICATION PDF
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.description,
                  color: Colors.white, size: 28),
              onPressed: () async {
                await loadAssetPDF();

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) {
                    return SizedBox(
                      height: 500,
                      child: pdfPath == null
                          ? const Center(child: CircularProgressIndicator())
                          : PDFView(
                              filePath: pdfPath!,
                            ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom White Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0E2815),
                    ),
                  ),
                  const SizedBox(height: 25),

                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      hintText: "Email",
                      filled: true,
                      fillColor: const Color(0xFFF2F5F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      filled: true,
                      fillColor: const Color(0xFFF2F5F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xFF537D5D),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF295740),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: loading ? null : login,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Color(0xFFE0BB46),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Signup screen for new users
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  // Controllers to read form inputs
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final ageController = TextEditingController();
  final sexController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  String selectedRole = "patient";
 // Calls backend register API
Future<void> signup() async {

  // Check password match
  if (passCtrl.text != confirmCtrl.text) return;

  final response = await ApiService.register(
    nameCtrl.text.trim(),
    emailCtrl.text.trim(),
    passCtrl.text.trim(),
    selectedRole,

    selectedRole == "patient" ? ageController.text.trim() : null,
    selectedRole == "patient" ? sexController.text.trim() : null,
    selectedRole == "patient" ? heightController.text.trim() : null,
    selectedRole == "patient" ? weightController.text.trim() : null,
  );

  if (response["message"] != null) {
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response["error"] ?? "Signup failed")),
    );
  }
}
 
   @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFB0D3C2),
    body: Stack(
      children: [
        // Top Curved Green Section
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF295740),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          padding: const EdgeInsets.only(left: 30, top: 80),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Join Medriva today",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        // Bottom White Card
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.72,
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Full Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      filled: true,
                      fillColor: const Color(0xFFF2F5F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Email
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      hintText: "Email",
                      filled: true,
                      fillColor: const Color(0xFFF2F5F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Password
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      filled: true,
                      fillColor: const Color(0xFFF2F5F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Confirm Password
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Confirm Password",
                      filled: true,
                      fillColor: const Color(0xFFF2F5F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                   const SizedBox(height: 15),
// Role Dropdown
DropdownButtonFormField(
  value: selectedRole,
  items: const [
    DropdownMenuItem(value: "doctor", child: Text("Doctor")),
    DropdownMenuItem(value: "patient", child: Text("Patient")),
    DropdownMenuItem(value: "admin", child: Text("Admin")),
  ],
  onChanged: (value) {
    setState(() {
      selectedRole = value!;
    });
  },
  decoration: InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF2F5F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  ),
),

const SizedBox(height: 15),

// PATIENT ONLY FIELDS
if (selectedRole == "patient") ...[

  // Age
  TextField(
    controller: ageController,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      hintText: "Age",
      filled: true,
      fillColor: const Color(0xFFF2F5F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  ),

  const SizedBox(height: 15),

  // Sex Dropdown
DropdownButtonFormField<String>(
  value: sexController.text.isEmpty ? null : sexController.text,
  items: const [
    DropdownMenuItem(
      value: "Male",
      child: Text("Male"),
    ),
    DropdownMenuItem(
      value: "Female",
      child: Text("Female"),
    ),
    DropdownMenuItem(
      value: "Other",
      child: Text("Other"),
    ),
  ],
  onChanged: (value) {
    setState(() {
      sexController.text = value!;
    });
  },
  decoration: InputDecoration(
    hintText: "Sex",
    filled: true,
    fillColor: const Color(0xFFF2F5F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  ),
),

  const SizedBox(height: 15),

  // Height
  TextField(
    controller: heightController,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      hintText: "Height (cm)",
      filled: true,
      fillColor: const Color(0xFFF2F5F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  ),

  const SizedBox(height: 15),

  // Weight
  TextField(
    controller: weightController,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      hintText: "Weight (kg)",
      filled: true,
      fillColor: const Color(0xFFF2F5F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  ),

  const SizedBox(height: 15),
],

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF295740),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: signup,
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Color(0xFFE0BB46),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

// This widget decides which dashboard to show based on user role
class Dashboard extends StatelessWidget {
  final String role;
  final int userId;

  const Dashboard({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {

    // If logged-in user is a patient
    if (role == "patient") {
      return PatientDashboard(userId: userId);
    }

    // If logged-in user is a doctor
   if (role == "doctor") {
  return DoctorPatientList(doctorId: userId);
}
    // If admin (or other roles)
    return Scaffold(
  appBar: AppBar(
  title: Text("$role Dashboard"),
  backgroundColor: const Color(0xFF295740),

  actions: [

    /// 💬 Chat
    IconButton(
      icon: const Icon(Icons.chat_bubble_outline),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatBotPage(
              userId: userId,
              role: role,
            ),
          ),
        );
      },
    ),

    /// 👤 Profile (ADD THIS)
    IconButton(
      icon: const Icon(Icons.person_outline),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(
              userId: userId,
              role: role, // 🔥 important (admin)
            ),
          ),
        );
      },
    ),
  ],
),
  body: Center(
    child: ElevatedButton(
      child: const Text("Open AI Assistant"),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatBotPage(
              userId: userId,
              role: role, // ✅ PASS CURRENT ROLE
            ),
          ),
        );
      },
    ),
  ),
);
  }
}

// Dashboard shown when logged-in user is a patient
