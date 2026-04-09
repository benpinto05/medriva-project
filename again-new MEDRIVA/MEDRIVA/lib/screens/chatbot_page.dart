import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatBotPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final int userId;
  final String role;

  const ChatBotPage({
    Key? key,
    this.initialData,
    required this.userId,
    required this.role,
  }) : super(key: key);

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {

  final TextEditingController textCtrl = TextEditingController();
  List<Map<String, String>> messages = [];
  bool loading = false;

  /// 🎤 Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  /// 🔊 Text to Speech
  late FlutterTts flutterTts;

  /// 🤖 Voice conversation mode
  bool voiceMode = false;

  /// Selected symptoms
  List<String> selectedSymptoms = [];

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();

    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5);
    flutterTts.setPitch(1.0);

    if (widget.initialData != null) {
      final vitals = widget.initialData!["vitals"];
      final risk = widget.initialData!["risk"];

      if (vitals != null && risk != null) {
        messages.add({
          "role": "bot",
          "text": "Your Fitbit data has been synced successfully ✅"
        });

        messages.add({
          "role": "bot",
          "text":
              "❤️ Heart Rate: ${vitals["heartRate"] ?? "N/A"}\n"
              "🚶 Steps: ${vitals["steps"] ?? "N/A"}\n"
              "😴 Sleep: ${vitals["sleepHours"] ?? "N/A"} hrs\n\n"
              "Risk Level: ${risk["riskLevel"] ?? "Unknown"}"
        });

        if (widget.initialData!["aiSummary"] != null) {
          messages.add({
            "role": "bot",
            "text": widget.initialData!["aiSummary"]
          });
        }
      }
    }
  }

  /// 🔊 Speak only when user presses speaker
  Future speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  /// 🎤 Start / Stop listening
  void _listen() async {

    if (!_isListening) {

      bool available = await _speech.initialize();

      if (available) {

        setState(() {
          _isListening = true;
        });

        _speech.listen(
          listenMode: stt.ListenMode.confirmation,
          onResult: (result) {

            if (result.finalResult) {

              String spoken = result.recognizedWords;

              setState(() {
                textCtrl.text = spoken;
              });

              if (voiceMode) {
                sendMessage();
              }
            }
          },
        );
      }

    } else {

      setState(() {
        _isListening = false;
      });

      _speech.stop();
    }
  }

  /// Symptom checkbox
  Widget symptomCheckbox(String label) {
    return CheckboxListTile(
      title: Text(label),
      value: selectedSymptoms.contains(label),
      onChanged: (value) async {

        setState(() {
          if (value == true) {
            selectedSymptoms.add(label);
          } else {
            selectedSymptoms.remove(label);
          }
        });

        final response = await ApiService.saveSymptoms(
          widget.userId,
          selectedSymptoms,
        );

        if (response["triage"] == "EMERGENCY") {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🚨 Emergency Alert"),
              content: Text(
                response["message"] ??
                "Possible cardiac emergency detected.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
      },
    );
  }

  /// Send chat message
  Future<void> sendMessage() async {

    final question = textCtrl.text.trim();
    if (question.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": question});
      loading = true;
    });

    textCtrl.clear();

    final response = await ApiService.askQuestion(
      question,
      widget.userId,
      widget.role == "patient" ? selectedSymptoms : [],
    );

    setState(() {
      loading = false;
    });

    if (response["triage"] == "EMERGENCY") {

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("🚨 Emergency Alert"),
          content: Text(response["message"] ?? "Seek immediate care."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );

      return;
    }

    String answer = response["answer"] ?? "No response";

    setState(() {
      messages.add({
        "role": "bot",
        "text": answer
      });
    });

    /// Restart listening if voice mode enabled
    if (voiceMode) {
      _listen();
    }
  }

  /// Upload PDF
  void uploadFile() async {
  setState(() {
    loading = true;
  });

  final result = await ApiService.uploadPdf(
    widget.userId,
    widget.role,   // 👈 ADD THIS
  );

  setState(() {
    messages.add({"role": "bot", "text": result});
    loading = false;
  });
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("AI Assistant"),
        actions: [

          /// 🎙 Voice Mode Toggle
          IconButton(
            icon: Icon(
              voiceMode ? Icons.record_voice_over : Icons.mic,
            ),
            onPressed: () {

              setState(() {
                voiceMode = !voiceMode;
              });

              if (voiceMode) {
                _listen();
              } else {
                _speech.stop();
              }
            },
          )
        ],
      ),

      body: Column(
        children: [

          if (_isListening)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Listening...",
                style: TextStyle(color: Colors.red),
              ),
            ),

        

          /// Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {

                final msg = messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color:
                          isUser ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          msg["text"] ?? "",
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),

                        /// 🔊 Speak only if user taps
                        if (!isUser)
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () => speak(msg["text"]!),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (loading) const CircularProgressIndicator(),

          /// Input row
          Padding(
            padding: const EdgeInsets.all(8),

            child: Row(
              children: [

                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: uploadFile,
                ),

                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      hintText: "Ask something...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                /// 🎤 Mic
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: _listen,
                ),

                /// Send
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}