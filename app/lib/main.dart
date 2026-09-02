import 'package:flutter/material.dart';
import 'capture/audio_streamer.dart';
import 'overlay/scam_alert_overlay.dart';
import 'registry/threat_registry_screen.dart';

void main() {
  runApp(const SatyaCallApp());
}

class SatyaCallApp extends StatelessWidget {
  const SatyaCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SatyaCall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF3366),
          surface: Color(0xFF131B24),
        ),
      ),
      home: const SatyaCallHomeScreen(),
    );
  }
}

class SatyaCallHomeScreen extends StatefulWidget {
  const SatyaCallHomeScreen({super.key});

  @override
  State<SatyaCallHomeScreen> createState() => _SatyaCallHomeScreenState();
}

class _SatyaCallHomeScreenState extends State<SatyaCallHomeScreen> {
  String _backendWsUrl = "ws://10.0.2.2:8000/ws/call-stream";
  String _backendHttpUrl = "http://10.0.2.2:8000";
  late CallAudioStreamer _streamer;
  
  bool _isMonitoring = false;
  int _riskScore = 0;
  String _riskLevel = "SAFE";
  String _scamCategory = "Normal Conversation";
  List<String> _transcripts = [];
  Map<String, dynamic>? _activeAlert;

  @override
  void initState() {
    super.initState();
    _streamer = CallAudioStreamer(backendWsUrl: _backendWsUrl);
    _streamer.onTranscriptUpdate = (speaker, text) {
      setState(() {
        _transcripts.add("[$speaker]: $text");
      });
    };
    _streamer.onRiskUpdate = (data) {
      setState(() {
        _riskScore = data["risk_score"] ?? 0;
        _riskLevel = data["level"] ?? "SAFE";
        _scamCategory = data["category"] ?? "Normal";
      });
    };
    _streamer.onAlertTriggered = (data) {
      setState(() {
        _activeAlert = data;
      });
    };
  }

  void _toggleMonitoring() async {
    if (_isMonitoring) {
      await _streamer.stopCapture();
      setState(() {
        _isMonitoring = false;
      });
    } else {
      await _streamer.startCapture(callerNumber: "+91 98765 43210");
      setState(() {
        _isMonitoring = true;
        _transcripts.clear();
        _riskScore = 0;
        _riskLevel = "SAFE";
        _activeAlert = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131B24),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF), size: 22),
            ),
            const SizedBox(width: 10),
            const Text("SatyaCall", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => ThreatRegistryScreen(backendUrl: _backendHttpUrl)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBanner(),
                const SizedBox(height: 18),
                _buildRiskGaugeCard(),
                const SizedBox(height: 18),
                _buildLiveTranscriptCard(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMonitoring ? Colors.redAccent : const Color(0xFF00E5FF),
                    foregroundColor: _isMonitoring ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _toggleMonitoring,
                  icon: Icon(_isMonitoring ? Icons.stop_circle : Icons.mic),
                  label: Text(
                    _isMonitoring ? "Stop Call Protection" : "Start Speakerphone Protection",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          if (_activeAlert != null)
            ScamAlertOverlay(
              title: _activeAlert!["title"] ?? "Scam Alert",
              riskScore: _riskScore,
              category: _scamCategory,
              recommendation: _activeAlert!["recommendation"] ?? "Hang up immediately.",
              onDismiss: () => setState(() => _activeAlert = null),
              onHangUpAndReport: () {
                setState(() => _activeAlert = null);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => ThreatRegistryScreen(backendUrl: _backendHttpUrl)),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(
            _isMonitoring ? Icons.radio_button_checked : Icons.radio_button_off,
            color: _isMonitoring ? Colors.greenAccent : Colors.white38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isMonitoring ? "SPEAKERPHONE CAPTURE ACTIVE" : "MONITORING IDLE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isMonitoring ? Colors.greenAccent : Colors.white38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isMonitoring ? "Capturing live ambient audio via AudioSource.MIC" : "Tap button below during call to start",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRiskGaugeCard() {
    Color riskColor = _riskScore >= 75 ? Colors.redAccent : (_riskScore >= 45 ? Colors.amberAccent : Colors.greenAccent);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AI Risk Score (DistilBERT + ASVspoof)", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(_riskLevel, style: TextStyle(color: riskColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("$_riskScore", style: TextStyle(color: riskColor, fontSize: 44, fontWeight: FontWeight.w900)),
              Text("/100", style: TextStyle(color: Colors.white38, fontSize: 18)),
              const Spacer(),
              Text(_scamCategory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _riskScore / 100.0,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTranscriptCard() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live Transcription (Whisper & Bhashini ASR)", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white10),
          Expanded(
            child: _transcripts.isEmpty
                ? const Center(child: Text("Listening for call speech...", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: _transcripts.length,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(_transcripts[i], style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
