// profile_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String role;

  const ProfilePage({super.key, required this.userId, required this.role,});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  Map<String, dynamic>? userData;
  bool loading = true;

  List pdfs = [];
bool loadingPdfs = true;
bool showPdfs = false;
  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchPdfs();
  }

  Future<void> fetchProfile() async {

    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/patient/${widget.userId}")
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body);
        loading = false;
      });
    }
  }
  Future<void> fetchPdfs() async {
  try {
    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/pdfs/${widget.userId}/${widget.role}")
    );

    if (response.statusCode == 200) {
      setState(() {
        pdfs = jsonDecode(response.body);
        loadingPdfs = false;
      });
    }
  } catch (e) {
    print("PDF fetch error: $e");
  }
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFB0D3C2),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                /// TOP GREEN HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 30),
                  decoration: const BoxDecoration(
                    color: Color(0xFF295740),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),

                  child: Column(
                    children: [

                      /// PROFILE IMAGE
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF295740),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// USER NAME
                      Text(
                        userData?["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// EDIT PROFILE BUTTON
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF295740),
                        ),
                        child: const Text("Edit Profile"),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// PROFILE DETAILS CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [

                          if (widget.role == "patient") ...[
  _profileRow(
    Icons.cake,
    "Age",
    userData?["age"]?.toString() ?? "",
  ),
  const Divider(),

  _profileRow(
    Icons.person,
    "Sex",
    userData?["sex"] ?? "",
  ),
  const Divider(),

  _profileRow(
    Icons.height,
    "Height",
    "${userData?["height"] ?? ""} cm",
  ),
  const Divider(),

  _profileRow(
    Icons.monitor_weight,
    "Weight",
    "${userData?["weight"] ?? ""} kg",
  ),
  const Divider(),
],
                          _pdfHeaderRow(),
                          
                          if (showPdfs)
  loadingPdfs
      ? const Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(),
        )
      : pdfs.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: Text("No PDFs uploaded"),
            )
          : Column(
              children: pdfs.map((pdf) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
  children: [
    const Icon(Icons.picture_as_pdf, color: Color(0xFF295740)),
    const SizedBox(width: 12),

    Expanded(
      child: Text(
        pdf["file_name"],
        overflow: TextOverflow.ellipsis,
      ),
    ),

    /// 🔥 DELETE BUTTON
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () => confirmDelete(pdf["id"]),
    ),
  ],
),
                );
              }).toList(),
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
void confirmDelete(int pdfId) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete PDF"),
      content: const Text("Are you sure you want to delete this PDF?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            deletePdf(pdfId);
          },
          child: const Text(
            "Delete",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}
Future<void> deletePdf(int pdfId) async {
  try {
    final response = await http.delete(
      Uri.parse("${ApiService.baseUrl}/pdf/$pdfId"),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF deleted successfully")),
      );

      fetchPdfs(); // 🔥 refresh list
    } else {
      throw Exception("Delete failed");
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error deleting PDF")),
    );
  }
}
  /// REUSABLE ROW WIDGET
  Widget _profileRow(IconData icon, String title, String value) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(
        children: [

          Icon(icon, color: const Color(0xFF295740)),

          const SizedBox(width: 12),

          Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(width: 10),

          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  Widget _pdfHeaderRow() {
  return InkWell(
    onTap: () {
      setState(() {
        showPdfs = !showPdfs;
      });
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Color(0xFF295740)),
          SizedBox(width: 12),
          Text(
            "PDF History:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Spacer(),
          Icon(
            showPdfs ? Icons.expand_less : Icons.expand_more,
            color: Color(0xFF295740),
          ),
        ],
      ),
    ),
  );
}
}