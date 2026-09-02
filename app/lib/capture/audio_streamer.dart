import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';

typedef RiskCallback = void Function(Map<String, dynamic> riskData);
typedef TranscriptCallback = void Function(String speaker, String text);
typedef AlertCallback = void Function(Map<String, dynamic> alertData);

/// SatyaCall Audio Capture and WebSocket Streaming Module
/// Implements Slide 7 recommendation: speakerphone mic capture (AudioSource.mic)
class CallAudioStreamer {
  final String backendWsUrl;
  final AudioRecorder _audioRecorder = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription<List<int>>? _audioSubscription;
  bool _isStreaming = false;

  RiskCallback? onRiskUpdate;
  TranscriptCallback? onTranscriptUpdate;
  AlertCallback? onAlertTriggered;

  CallAudioStreamer({required this.backendWsUrl});

  bool get isStreaming => _isStreaming;

  Future<bool> requestPermissions() async {
    final micStatus = await Permission.microphone.request();
    final alertStatus = await Permission.systemAlertWindow.request();
    return micStatus.isGranted && alertStatus.isGranted;
  }

  Future<void> startCapture({required String callerNumber}) async {
    if (_isStreaming) return;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      throw Exception("Microphone permission not granted for call capture.");
    }

    // Connect to SatyaCall WebSocket
    _channel = WebSocketChannel.connect(Uri.parse(backendWsUrl));
    _listenToBackend();

    // Configure PCM 16kHz Mono record stream from MIC (speakerphone acoustic environment)
    final recordStream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _isStreaming = true;

    // Buffer and transmit 1-second audio chunks over WebSocket
    List<int> buffer = [];
    _audioSubscription = recordStream.listen((chunk) {
      buffer.addAll(chunk);
      if (buffer.length >= 16000 * 2) { // ~1 second of 16-bit audio
        final base64Audio = base64Encode(buffer);
        _channel?.sink.add(jsonEncode({
          "type": "audio_chunk",
          "data": base64Audio,
          "caller_number": callerNumber,
          "timestamp": DateTime.now().toIso8601String(),
        }));
        buffer.clear();
      }
    });
  }

  void _listenToBackend() {
    _channel?.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          final type = data["type"];

          if (type == "transcript_partial" && onTranscriptUpdate != null) {
            onTranscriptUpdate!(data["speaker"] ?? "caller", data["text"] ?? "");
          } else if (type == "risk_update" && onRiskUpdate != null) {
            onRiskUpdate!(data);
          } else if (type == "alert" && onAlertTriggered != null) {
            onAlertTriggered!(data);
          }
        } catch (e) {
          // ignore or log
        }
      },
      onError: (err) {
        _isStreaming = false;
      },
      onDone: () {
        _isStreaming = false;
      },
    );
  }

  Future<void> stopCapture() async {
    if (!_isStreaming) return;
    await _audioSubscription?.cancel();
    await _audioRecorder.stop();
    _channel?.sink.close();
    _isStreaming = false;
  }

  void dispose() {
    stopCapture();
    _audioRecorder.dispose();
  }
}
