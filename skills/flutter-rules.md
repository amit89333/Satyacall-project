# Flutter Rules for SatyaCall

## Audio Capture (Slide 7 Feasibility)
- Target Android SDK 34+.
- Do NOT attempt to capture private in-call downlink via `AudioSource.VOICE_CALL` as OEM security policies restrict it on Android 10+.
- Capture audio via `AudioSource.MIC` while the phone call is on speakerphone. This legally, cleanly, and reliably records ambient bidirectional speech from both parties.
- Stream PCM/AAC audio chunks of 0.5s–1.0s buffer size via `web_socket_channel` to `ws://backend/ws/call-stream`.

## Foreground Service & System Alert Window
- Register `SYSTEM_ALERT_WINDOW` permission to display the floating overlay when risk score >= 75.
- Run call monitoring in a foreground service with persistent notification so Android OS never kills the WebSocket audio pipe mid-call.
- On alert trigger:
  - Display flashing amber/red heads-up overlay with detected scam category (e.g. "🚨 Digital Arrest Scam Detected").
  - Provide haptic vibration alert.
  - Show two primary actions: **"Hang Up & Report"** and **"Dismiss / Safe"**.
