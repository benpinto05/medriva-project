import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'chatbot_page.dart';
import 'profile_page.dart';

class PatientDashboard extends StatefulWidget {
  final int userId;// Used to fetch that patient’s vitals

  const PatientDashboard({super.key, required this.userId});
  

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}



class _PatientDashboardState extends State<PatientDashboard> {
  Map<String, dynamic>? prediction;
  bool analyzing = false;
  Map<String, dynamic>? vitals;// Stores Fitbit vitals
  bool loadingVitals = true;// Loading indicator
  String getRiskMessage(String level) {
  switch (level) {
    case "LOW":
      return "Your health indicators are within a normal range. Keep maintaining a healthy lifestyle.";
    case "MODERATE":
      return "Some health indicators need attention. Improve activity, sleep, and monitor vitals.";
    case "HIGH":
      return "Your health condition indicates higher risk. Please consult a doctor.";
    default:
      return "";
  }
}

List<String> getWarnings() {
  List<String> warnings = [];

  int? hr = int.tryParse(vitals?["heartRate"]?.toString() ?? "");
  int steps = int.tryParse(vitals?["steps"].toString() ?? "0") ?? 0;
  double sleep = double.tryParse(vitals?["sleepHours"].toString() ?? "0") ?? 0.0;

  if (hr != null && (hr < 60 || hr > 100)) {
    warnings.add("⚠️ Abnormal heart rate detected");
  }
  if (steps < 3000) {
    warnings.add("⚠️ Low physical activity");
  }
  if (sleep < 6) {
    warnings.add("⚠️ Poor sleep duration");
  }

  return warnings;
}

  @override
  void initState() {
    super.initState();
    _fetchVitals();// Fetch vitals when dashboard loads
  }
Future<void> _analyzeHealth() async {
  setState(() {
    analyzing = true;
  });

  try {
    final data = await ApiService.getHealthAnalysis(widget.userId);

    print("🔥 ANALYSE DATA: $data");

    if (!mounted) return;

    setState(() {
      prediction = data["risk"];
      analyzing = false;
    });

  } catch (e) {
    setState(() {
      analyzing = false;
    });
  }
}
  // Fetch latest Fitbit data from backend
  Future<void> _fetchVitals() async {
  final response = await http.get(
    Uri.parse("${ApiService.baseUrl}/analyse-health/${widget.userId}"),
  );

  final data = jsonDecode(response.body);

  print("🔥 VITALS FROM ANALYSE: $data");

  if (!mounted) return;

  setState(() {
    vitals = data["vitals"]; // IMPORTANT
    loadingVitals = false;
  });
}
  // Checks whether heart rate is outside normal range
  bool _isHeartAbnormal(int? hr) {
    if (hr == null) return false;
    return hr < 60 || hr > 100;
  }

@override
Widget build(BuildContext context) {
  final ai = prediction?["aiPrediction"];
  return Scaffold(
    backgroundColor: const Color(0xFFB0D3C2),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 900;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// TOP BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Medriva",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0E2815),
                          ),
                        ),

                        Row(
                          children: [

                            /// CHAT ICON
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatBotPage(
                                      userId: widget.userId,
                                      role: "patient",
                                    ),
                                  ),
                                );
                              },
                            ),

                            /// VITALS HISTORY ICON
                            IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VitalsHistoryPage(
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                            ),

//profile icon
                                                        IconButton(
                              icon: const Icon(Icons.person_outline),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePage(
  userId: widget.userId,
  role: "patient", // 👈 THIS IS MISSING
),
                                  ),
                                );
                              },
                            ), 
                            const SizedBox(width: 10),

                            /// CONNECT TO FITBIT BUTTON
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF295740),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () =>
                                  ApiService.connectToFitbit(widget.userId),
                              child: const Text(
                                "Fitbit",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Health Overview",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E2815),
                      ),
                    ),

                    const SizedBox(height: 25),

                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _heartCard(height: 200)),
                              const SizedBox(width: 20),
                              Expanded(child: _stepsCard(height: 200)),
                              const SizedBox(width: 20),
                              Expanded(child: _sleepCard(height: 200)),
                            ],
                          )
                        : Column(
                            children: [
                              _heartCard(),
                              const SizedBox(height: 15),
                              _stepsCard(),
                              const SizedBox(height: 15),
                              _sleepCard(),
                            ],
                          ),

                    const SizedBox(height: 30),
                    /// ANALYSE HEALTH BUTTON
Center(
  child: SizedBox(
    width: 250,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF295740),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: _analyzeHealth,
      child: const Text(
        "Analyse My Health",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  ),
),
const SizedBox(height: 20),

                      if (analyzing)
                        const Center(child: CircularProgressIndicator()),

                      /// 🔥 PREDICTION UI
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: prediction != null
                            ? Container(
                                key: const ValueKey("prediction_card"),
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  gradient: LinearGradient(
                                    colors: prediction?["riskLevel"] == "HIGH"
                                        ? [Colors.red.shade100, Colors.white]
                                        : prediction?["riskLevel"] == "MODERATE"
                                            ? [Colors.orange.shade100, Colors.white]
                                            : [Colors.green.shade100, Colors.white],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    const Text(
                                      "AI Health Analysis",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    Text(
                                      "Risk: ${prediction?["riskLevel"]}",
                                      style: const TextStyle(fontSize: 18),
                                    ),

                                    const SizedBox(height: 20),
if (ai != null)
  Builder(
    builder: (context) {
      final prob = double.tryParse(ai["risk_probability"].toString()) ?? 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Probability: ${(prob * 100).toStringAsFixed(1)}%",
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: prob,
          ),
          const SizedBox(height: 15),

          Text(
            getRiskMessage(prediction?["riskLevel"] ?? ""),
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: getWarnings()
                .map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(w),
                    ))
                .toList(),
          ),
        ],
      );
    },
  ),

                                    const SizedBox(height: 20),

                                  ],
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Reusable card UI used for heart, steps, sleep
Widget _baseCard({
  required Widget child,
  Color? borderColor,
  double? height,
  double? width,
}) {
  return Container(
    height: height,
    width: width ?? double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: borderColor != null
          ? Border.all(color: borderColor, width: 2)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: child,
  );
}
// Displays heart rate and abnormal status
  Widget _heartCard({double? height}) {
    int? hr = vitals?["heartRate"];
    bool abnormal = _isHeartAbnormal(hr);

    return _baseCard(
      height: height,
      borderColor: abnormal ? Colors.red : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Heart Rate",
              style: TextStyle(color: Color(0xFF537D5D))),
          const SizedBox(height: 10),
          Text(
            loadingVitals
                ? "Loading..."
                : "${hr ?? "--"} bpm",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: abnormal ? Colors.red : const Color(0xFF0E2815),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            abnormal ? "Abnormal" : "Normal",
            style: TextStyle(
              color: abnormal ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 12),

          /// Simple Graph Simulation
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: abnormal
                  ? Colors.red.withOpacity(0.1)
                  : const Color(0xFF295740).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
// Displays steps and progress towards 10,000 goal
  Widget _stepsCard({double? height}) {
    int steps = vitals?["steps"] ?? 0;
    double progress = (steps / 10000).clamp(0.0, 1.0);

    return _baseCard(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Steps",
              style: TextStyle(color: Color(0xFF537D5D))),
          const SizedBox(height: 10),
          Text(
            loadingVitals
                ? "Loading..."
                : "$steps steps",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0E2815),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFB0D3C2),
            color: const Color(0xFF295740),
          ),
          const SizedBox(height: 6),
          const Text("Goal: 10,000"),
        ],
      ),
    );
  }
// Displays sleep duration
  Widget _sleepCard({double? height}) {
  return _baseCard(
    height: height,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sleep",
            style: TextStyle(color: Color(0xFF537D5D))),
        const SizedBox(height: 10),
        Text(
          loadingVitals
              ? "Loading..."
              : "${vitals?["sleepHours"] ?? "--"} hrs",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0E2815),
          ),
        ),
        const SizedBox(height: 8),
        const Text("Deep 2h | Light 4h | REM 1h20m"),
      ],
    ),
  );
}

}
class VitalsHistoryPage extends StatefulWidget {
  final int userId;

  const VitalsHistoryPage({super.key, required this.userId});

  @override
  State<VitalsHistoryPage> createState() => _VitalsHistoryPageState();
}



/////////////////vital history fetching////////



class _VitalsHistoryPageState extends State<VitalsHistoryPage> {

  List vitals = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchVitals();
  }

  Future<void> fetchVitals() async {

    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/patient-vitals/${widget.userId}")
    );

    if (response.statusCode == 200) {
      setState(() {
        vitals = jsonDecode(response.body);
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vitals History"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vitals.length,
              itemBuilder: (context, index) {

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: Text(
                      "BPM: ${vitals[index]['heart_rate']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      "Time: ${vitals[index]['recorded_at']}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}

