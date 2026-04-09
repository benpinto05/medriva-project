import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'doctor_patient_report.dart';
import 'chatbot_page.dart';
import 'profile_page.dart';

class DoctorPatientList extends StatefulWidget {
  final int doctorId;

  const DoctorPatientList({super.key, required this.doctorId});

  @override
  State<DoctorPatientList> createState() => _DoctorPatientListState();
}

class _DoctorPatientListState extends State<DoctorPatientList> {
  List<dynamic> patients = [];
  bool loading = true;

  @override
void initState() {
  super.initState();
  print("Doctor ID passed: ${widget.doctorId}");  // 👈 ADD HERE
  _fetchPatients();
}

  Future<void> _fetchPatients() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/doctor/patients?doctorId=${widget.doctorId}",
        ),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        patients = data["patients"];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
  title: const Text("My Patients"),
  backgroundColor: const Color(0xFF295740),
 actions: [
  /// 💬 Chat
  IconButton(
    icon: const Icon(Icons.chat_bubble_outline),
    tooltip: "AI RAG Assistant",
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatBotPage(
            userId: widget.doctorId,
            role: "doctor",
          ),
        ),
      );
    },
  ),

  /// 👤 Profile (ADD THIS)
  IconButton(
    icon: const Icon(Icons.person_outline),
    tooltip: "Profile",
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            userId: widget.doctorId,
            role: "doctor", // 🔥 important
          ),
        ),
      );
    },
  ),
],
),
      body: patients.isEmpty
          ? const Center(
              child: Text("No patients assigned."),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 15),
                  child: ListTile(
                    title: Text(
                      patient["name"],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        Text("Patient ID: ${patient["id"]}"),
                    trailing: const Icon(
                        Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorPatientReport(
                            patientId: patient["id"],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}