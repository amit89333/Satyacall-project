"""
SatyaCall Backend — FastAPI Application
Deployable on AWS Lambda (via Mangum) behind API Gateway.
Provides WebSocket live call audio streaming, DistilBERT scam detection,
ASVspoof voice-clone analysis, and Threat Registry.
"""
import os
import json
import asyncio
import logging
from typing import Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel

from .asr import asr_processor
from .classifier import scam_classifier
from .voice_check import voice_checker
from .registry import threat_registry

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("satyacall.main")

app = FastAPI(
    title="SatyaCall AI Fraud Detection Engine",
    description="Real-time call scam classifier, ASVspoof voice-clone detector & threat registry",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files for the live web demo & interactive mobile emulator
STATIC_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(STATIC_DIR):
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

class ReportRequest(BaseModel):
    phone_number: str
    category: Optional[str] = "Digital Arrest Scam"
    risk_score: Optional[float] = 90.0

class AnalyzeTextRequest(BaseModel):
    transcript: str
    caller_number: Optional[str] = "+919876543210"

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "SatyaCall AI Engine",
        "version": "1.0.0",
        "distilbert_scam_model": "loaded",
        "asvspoof_voice_model": "loaded",
        "threat_registry": "connected"
    }

@app.get("/")
async def serve_demo():
    index_file = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file, headers={"Cache-Control": "no-cache, no-store, must-revalidate"})
    return {"message": "SatyaCall API is active. Open /docs for Swagger UI or static frontend."}

@app.get("/demo")
async def serve_demo_alias():
    index_file = os.path.join(STATIC_DIR, "index.html")
    return FileResponse(index_file, headers={"Cache-Control": "no-cache, no-store, must-revalidate"})

@app.get("/scenarios")
async def get_preset_scenarios():
    """Returns realistic test call scenarios matching pitch deck slides 2-5"""
    return [
        {
            "id": "scenario_cbi",
            "title": "🚨 Digital Arrest (Fake CBI Officer)",
            "category": "Digital Arrest",
            "caller_number": "+91 98765 43210",
            "caller_name": "Inspector Vijay Rathore (CBI HQ)",
            "description": "High-urgency call alleging Aadhaar money laundering and demanding RTGS escrow deposit.",
            "is_clone": True,
            "turns": [
                {"speaker": "caller", "text": "This is Inspector Rathore from Central Bureau of Investigation CBI HQ New Delhi."},
                {"speaker": "victim", "text": "What? Why are you calling me?"},
                {"speaker": "caller", "text": "Your Aadhaar card has been used to open 16 illegal bank accounts for money laundering of 3.8 crore rupees."},
                {"speaker": "victim", "text": "No officer, I have never done anything like this!"},
                {"speaker": "caller", "text": "Supreme Court has issued a non-bailable arrest warrant. You are placed under digital arrest right now!"},
                {"speaker": "caller", "text": "Do not disconnect this line or police squad will raid your home in 30 minutes! Transfer 50,000 rupees clearance deposit immediately."}
            ]
        },
        {
            "id": "scenario_kyc",
            "title": "💳 Bank KYC Account Suspension",
            "category": "Bank KYC Phishing",
            "caller_number": "+91 80012 34567",
            "caller_name": "State Bank of India Security",
            "description": "Phishing caller threatening instant debit card blockage unless OTP is shared.",
            "is_clone": False,
            "turns": [
                {"speaker": "caller", "text": "Namaste, I am calling from State Bank of India KYC division."},
                {"speaker": "victim", "text": "Yes, what is the matter?"},
                {"speaker": "caller", "text": "Your debit card and netbanking are blocked right now due to pending biometric KYC update."},
                {"speaker": "caller", "text": "To unfreeze your balance immediately, please read out the 6-digit OTP sent to your phone right now."}
            ]
        },
        {
            "id": "scenario_normal",
            "title": "✅ Legitimate Family Call",
            "category": "Normal Conversation",
            "caller_number": "+91 98200 55443",
            "caller_name": "Mom",
            "description": "Everyday domestic call with zero urgency or financial coercion.",
            "is_clone": False,
            "turns": [
                {"speaker": "caller", "text": "Hi beta, are you still at work?"},
                {"speaker": "victim", "text": "Yes mom, finishing up a report. I'll head out soon."},
                {"speaker": "caller", "text": "Okay, please remember to pick up bread on your way home. Dinner will be ready at 9."},
                {"speaker": "victim", "text": "Got it, see you in 45 minutes. Love you!"}
            ]
        }
    ]

@app.get("/registry/check")
async def check_caller_threat(number: str = Query(..., description="Phone number to check")):
    return threat_registry.check_number(number)

@app.post("/registry/report")
async def report_threat(payload: ReportRequest):
    return threat_registry.report_number(
        phone_number=payload.phone_number,
        category=payload.category,
        risk_score=payload.risk_score
    )

@app.get("/registry/threats")
async def list_threats(limit: int = Query(10, ge=1, le=50)):
    return threat_registry.list_recent_threats(limit=limit)

@app.post("/analyze/sample")
async def analyze_sample(payload: AnalyzeTextRequest):
    """Instant analysis of a text transcript for testing & playground"""
    analysis = scam_classifier.analyze_text(payload.transcript)
    registry_info = threat_registry.check_number(payload.caller_number)
    
    # Calculate composite score
    text_risk = analysis["risk_score"]
    registry_boost = 15 if registry_info["is_reported"] else 0
    composite_risk = min(99, text_risk + registry_boost)
    
    return {
        "transcript": payload.transcript,
        "caller_number": payload.caller_number,
        "scam_analysis": analysis,
        "registry_info": registry_info,
        "composite_risk_score": composite_risk,
        "alert_triggered": composite_risk >= 75
    }

@app.websocket("/ws/call-stream")
async def websocket_call_stream(websocket: WebSocket):
    """
    Main WebSocket endpoint for live audio streaming from Flutter app.
    Streams chunks, executes ASR, DistilBERT, ASVspoof, and pushes real-time risk scores.
    """
    await websocket.accept()
    logger.info("WebSocket connected for call audio streaming.")
    accumulated_transcript = []
    
    try:
        while True:
            raw_message = await websocket.receive_text()
            try:
                msg = json.loads(raw_message)
            except Exception:
                msg = {"type": "ping"}

            msg_type = msg.get("type", "audio_chunk")
            caller_number = msg.get("caller_number", "+919876543210")

            if msg_type == "audio_chunk":
                audio_payload = msg.get("data", "")
                text_snippet = msg.get("text_override")  # Used for simulated audio scenarios
                
                # Step 1: ASR Transcription (Whisper / Bhashini)
                if not text_snippet:
                    asr_result = await asr_processor.transcribe_chunk(
                        audio_bytes=audio_payload.encode() if isinstance(audio_payload, str) else audio_payload,
                        language=msg.get("language", "auto")
                    )
                    text_snippet = asr_result.get("text", "")

                if text_snippet:
                    accumulated_transcript.append(text_snippet)
                
                full_transcript = " ".join(accumulated_transcript[-6:])  # Rolling window of last 6 sentences

                # Step 2: DistilBERT Scam Classification
                scam_eval = scam_classifier.analyze_text(full_transcript)
                
                # Step 3: ASVspoof Voice Clone Analysis
                voice_eval = voice_checker.analyze_audio(
                    audio_data=audio_payload.encode() if isinstance(audio_payload, str) else b""
                )
                if msg.get("simulate_clone"):
                    voice_eval["is_deepfake"] = True
                    voice_eval["clone_probability"] = 92
                    voice_eval["authenticity_score"] = 0.08
                    voice_eval["vocoder_artifacts"] = "neural_vocoder_synthetic_jitter_detected"

                # Step 4: Registry lookup boost
                reg_info = threat_registry.check_number(caller_number)
                reg_boost = 15 if reg_info["is_reported"] else 0

                # Step 5: Composite Risk Score calculation (Matches Pitch Deck flow chart)
                base_risk = scam_eval["risk_score"]
                clone_boost = 20 if voice_eval["is_deepfake"] else 0
                composite_risk = min(99, base_risk + reg_boost + clone_boost)

                # Send partial transcript update
                await websocket.send_json({
                    "type": "transcript_partial",
                    "speaker": msg.get("speaker", "caller"),
                    "text": text_snippet,
                    "language": msg.get("language", "en")
                })

                # Send real-time risk score update
                risk_level = "CRITICAL" if composite_risk >= 75 else ("ELEVATED" if composite_risk >= 45 else "LOW")
                await websocket.send_json({
                    "type": "risk_update",
                    "risk_score": composite_risk,
                    "level": risk_level,
                    "category": scam_eval["category"],
                    "urgency_score": scam_eval["urgency_score"],
                    "authority_impersonation": scam_eval["authority_impersonation"],
                    "voice_clone": voice_eval,
                    "registry_status": reg_info,
                    "triggers": scam_eval["triggers"]
                })

                # Step 6: Trigger on-screen alert when risk >= 75
                if composite_risk >= 75:
                    await websocket.send_json({
                        "type": "alert",
                        "title": f"🚨 {scam_eval['category']} Detected",
                        "risk_score": composite_risk,
                        "caller_number": caller_number,
                        "recommendation": "IMMEDIATE ACTION: Hang up now. Legitimate CBI/Police never place citizens under digital arrest or demand funds on phone calls.",
                        "can_report": True
                    })

            elif msg_type == "reset":
                accumulated_transcript = []
                await websocket.send_json({"type": "reset_ack"})

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected.")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")

# AWS Lambda ASGI handler (Mangum)
try:
    from mangum import Mangum
    handler = Mangum(app)
except ImportError:
    handler = None
