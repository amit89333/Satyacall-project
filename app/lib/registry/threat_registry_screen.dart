import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ThreatRegistryScreen extends StatefulWidget {
  final String backendUrl;

  const ThreatRegistryScreen({Key? key, required this.backendUrl}) : super(key: key);

  @override
  State<ThreatRegistryScreen> createState() => _ThreatRegistryScreenState();
}

class _ThreatRegistryScreenState extends State<ThreatRegistryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _searchResult;
  List<dynamic> _recentThreats = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecentThreats();
  }

  Future<void> _fetchRecentThreats() async {
    try {
      final res = await http.get(Uri.parse("${widget.backendUrl}/registry/threats"));
      if (res.statusCode == 200) {
        setState(() {
          _recentThreats = jsonDecode(res.body);
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _checkNumber(String number) async {
    if (number.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse("${widget.backendUrl}/registry/check?number=$number"));
      if (res.statusCode == 200) {
        setState(() {
          _searchResult = jsonDecode(res.body);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error checking number: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reportNumber(String number) async {
    try {
      final res = await http.post(
        Uri.parse("${widget.backendUrl}/registry/report"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": number,
          "category": "Reported via App",
          "risk_score": 95.0,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Number successfully reported to SatyaCall Registry!")),
        );
        _checkNumber(number);
        _fetchRecentThreats();
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("SatyaCall Threat Registry", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter phone number (+91...)",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.blueAccent),
                  onPressed: () => _checkNumber(_searchController.text),
                ),
              ),
              onSubmitted: _checkNumber,
            ),
            const SizedBox(height: 20),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_searchResult != null) _buildSearchResultCard(),
            const SizedBox(height: 24),
            const Text(
              "Recent Verified Scam Numbers",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._recentThreats.map((threat) => _buildThreatTile(threat)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard() {
    final isReported = _searchResult!["is_reported"] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReported ? const Color(0xFF2E1014) : const Color(0xFF10281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isReported ? Colors.redAccent : Colors.greenAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isReported ? Icons.report_problem : Icons.verified_user, color: isReported ? Colors.redAccent : Colors.greenAccent),
              const SizedBox(width: 8),
              Text(
                isReported ? "CONFIRMED FRAUDULENT CALLER" : "CLEAN / NO REPORTS",
                style: TextStyle(color: isReported ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("Number: ${_searchResult!['phone_number']}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          if (isReported) ...[
            const SizedBox(height: 4),
            Text("Category: ${_searchResult!['category']}", style: const TextStyle(color: Colors.white70)),
            Text("Reports: ${_searchResult!['report_count']} crowd victims", style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 14),
          if (!isReported)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => _reportNumber(_searchResult!['phone_number']),
              icon: const Icon(Icons.flag),
              label: const Text("Report this Number"),
            )
        ],
      ),
    );
  }

  Widget _buildThreatTile(dynamic threat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(threat["phone_number"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(threat["category"], style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: Text("🚩 ${threat['report_count']} reports", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
