import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class DoctorPatientReport extends StatefulWidget {
  final int patientId;

  const DoctorPatientReport({super.key, required this.patientId});

  @override
  State<DoctorPatientReport> createState() =>
      _DoctorPatientReportState();
}

class _DoctorPatientReportState
    extends State<DoctorPatientReport> {
  Map<String, dynamic>? vitals;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVitals();
  }

  Future<void> _fetchVitals() async {
    try {
      final response = await http.get(
        Uri.parse(
            "${ApiService.baseUrl}/fitbit/data?userId=${widget.patientId}"),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        vitals = data["vitals"];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  bool _isHeartAbnormal(int? hr) {
    if (hr == null) return false;
    return hr < 60 || hr > 100;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    int? hr = vitals?["heartRate"];
    int steps = vitals?["steps"] ?? 0;
    int sleep = vitals?["sleepHours"] ?? 0;

    bool heartAbnormal = _isHeartAbnormal(hr);
    bool sleepLow = sleep < 6;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Patient Clinical Report"),
        backgroundColor: const Color(0xFF295740),
      ),
      body: Center(
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(32),
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// HEADER
                const Text(
                  "MEDRIVA CLINICAL REPORT",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 30),

                Text("Patient ID: ${widget.patientId}"),
                Text("Report Date: ${DateTime.now().toLocal()}"),

                const SizedBox(height: 30),

                /// VITAL SECTION
                const Text(
                  "VITAL SIGNS",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const Divider(),

                _reportRow(
                  "Heart Rate",
                  "${hr ?? "--"} bpm",
                  heartAbnormal,
                ),
              
                _reportRow(
                  "Steps",
                  "$steps",
                  false,
                ),
                _reportRow(
                  "Sleep Duration",
                  "$sleep hrs",
                  sleepLow,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportRow(
      String label, String value, bool abnormal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: abnormal ? Colors.red : Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              abnormal ? "ABNORMAL" : "Normal",
              style: TextStyle(
                color: abnormal ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

}