# SatyaCall Backend API Specification

## 1. WebSocket Interface (`/ws/call-stream`)

### Client → Server Messages

#### `audio_chunk`
```json
{
  "type": "audio_chunk",
  "data": "<base64_encoded_pcm_audio>",
  "caller_number": "+919876543210",
  "language": "auto",
  "speaker": "caller"
}
```

#### `reset`
```json
{
  "type": "reset"
}
```

### Server → Client Messages

#### `transcript_partial`
```json
{
  "type": "transcript_partial",
  "speaker": "caller",
  "text": "Your Aadhaar card is linked to illegal money laundering.",
  "language": "en"
}
```

#### `risk_update`
```json
{
  "type": "risk_update",
  "risk_score": 88,
  "level": "CRITICAL",
  "category": "Digital Arrest / Law Enforcement Impersonation",
  "urgency_score": 0.95,
  "authority_impersonation": 0.92,
  "voice_clone": {
    "is_deepfake": true,
    "clone_probability": 92,
    "authenticity_score": 0.08,
    "vocoder_artifacts": "neural_vocoder_synthetic_jitter_detected"
  },
  "registry_status": {
    "is_reported": true,
    "report_count": 342,
    "crowd_verified": true
  },
  "triggers": ["cbi", "digital arrest", "money laundering", "immediately"]
}
```

#### `alert`
```json
{
  "type": "alert",
  "title": "🚨 Digital Arrest Detected",
  "risk_score": 88,
  "caller_number": "+919876543210",
  "recommendation": "IMMEDIATE ACTION: Hang up now. CBI/Police never place citizens under digital arrest or demand money via phone.",
  "can_report": true
}
```

---

## 2. REST Endpoints

### `GET /registry/check?number={phone_number}`
Returns threat intelligence for a phone number.

### `POST /registry/report`
Submits crowd-sourced scam report.
```json
{
  "phone_number": "+919876543210",
  "category": "Digital Arrest Scam",
  "risk_score": 95.0
}
```

### `GET /scenarios`
Returns pre-packaged audio transcript scenarios for live testing.
