import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  static const String baseUrl =
      "https://puritanical-nataly-publicly.ngrok-free.dev";

// REGISTER
static Future<Map<String, dynamic>> register(
  String name,
  String email,
  String password,
  String role,
  String? age,
  String? sex,
  String? height,
  String? weight,
) async {

  final response = await http.post(
    Uri.parse("$baseUrl/register"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "name": name,
      "email": email,
      "password": password,
      "role": role,
      "age": age,
      "sex": sex,
      "height": height,
      "weight": weight
    }),
  );

  return jsonDecode(response.body);
}

  // LOGIN
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  // ASK QUESTION (WITH TRIAGE SUPPORT)
  static Future<Map<String, dynamic>> askQuestion(
    String question,
    int userId,
    List<String> symptoms,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/ask"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": question,
          "userId": userId,
          "symptoms": symptoms,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        "error": "Backend not reachable ❌"
      };
    }
  }
 static Future<Map<String, dynamic>> saveSymptoms(
  int userId,
  List<String> symptoms,
) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/symptoms"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "symptoms": symptoms,
      }),
    );

    return jsonDecode(response.body);

  } catch (e) {
    return {
      "error": "Backend not reachable ❌"
    };
  }
}

  // PDF UPLOAD
  static Future<String> uploadPdf(int userId, String role) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null) return "No file selected";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/upload"),
      );
      request.fields['userId'] = userId.toString();
request.fields['role'] = role;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            result.files.single.bytes!,
            filename: result.files.single.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            result.files.single.path!,
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        return "PDF uploaded successfully ✅";
      } else {
        return "Upload failed ❌ (${response.statusCode})";
      }
    } catch (e) {
      return "Upload error ❌";
    }
  }

  // CONNECT TO FITBIT
  static Future<void> connectToFitbit(int userId) async {
    final Uri fitbitAuthUrl =
        Uri.parse("$baseUrl/auth/fitbit?userId=$userId");

    if (await canLaunchUrl(fitbitAuthUrl)) {
      await launchUrl(
        fitbitAuthUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw "Could not launch Fitbit auth";
    }
  }

  // 🧠 GET HEALTH ANALYSIS (DB + ML)
static Future<Map<String, dynamic>> getHealthAnalysis(int userId) async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/analyse-health/$userId"),
    );

    print("🔥 ANALYSE RESPONSE: ${response.body}");

    return jsonDecode(response.body);
  } catch (e) {
    return {
      "error": "Failed to fetch health analysis ❌"
    };
  }
}
}


