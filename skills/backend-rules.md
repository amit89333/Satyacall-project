# Backend Rules for SatyaCall

## Architecture & Latency
- Runtime: Python 3.11+, FastAPI with ASGI adapter (Mangum) for AWS Lambda and WebSocket API Gateway support.
- Total pipeline latency budget from audio chunk receipt to risk update broadcast must be < 1.5s.
- Wrap model inferences (ASR, DistilBERT, ASVspoof) in `asyncio.wait_for` with timeout defaults (1.2s max) to prevent blocking the WebSocket connection.

## Endpoints Contract
- `WebSocket /ws/call-stream`:
  - Receives: Binary audio chunks or JSON `{"type": "audio_chunk", "data": "base64...", "caller_number": "+91..."}`.
  - Broadcasts:
    - `transcript_partial`: `{ "speaker": "caller", "text": "...", "lang": "hi|en" }`
    - `risk_update`: `{ "risk_score": 88, "reasons": [...], "level": "HIGH" }`
    - `alert`: Triggered if `risk_score >= 75`
- `GET /registry/check?number=+91...`: Read-through threat query with report counts and community verification.
- `POST /registry/report`: Write-through threat submission (updates PostgreSQL and pushes to Firebase Firestore).
