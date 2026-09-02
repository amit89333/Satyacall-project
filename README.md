# 🛡️ SatyaCall — Real-Time On-Device Call Scam & AI Voice-Clone Shield

[![Live Demo](https://img.shields.io/badge/Live_Demo-GitHub_Pages-00f2fe?style=for-the-badge&logo=github)](https://amit89333.github.io/Satyacall-project/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI_on_AWS_Lambda-009688?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com)
[![DistilBERT](https://img.shields.io/badge/Scam_Classifier-Fine--Tuned_DistilBERT-orange?style=for-the-badge&logo=huggingface)](https://huggingface.co)
[![Flutter](https://img.shields.io/badge/Mobile_App-Flutter_Android-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)

> **Pitch Deck Alignment:** Built strictly to slides 3–5 & 7 of the SatyaCall pitch deck.
> **Key Innovation:** On-device speakerphone audio capture + low-latency AWS Lambda FastAPI backend + fine-tuned DistilBERT scam classifier + ASVspoof deepfake voice clone detector + PostgreSQL & Firebase threat registry.

---

## 🌐 24/7 Live Interactive Demonstration

### 👉 **[https://amit89333.github.io/Satyacall-project/](https://amit89333.github.io/Satyacall-project/)**

*Works on any browser, mobile phone, or laptop without setup or installation.*

### What Judges Can Test in the Simulator:
1. **🚨 Scenario 1: Digital Arrest (CBI Impersonator):**
   * Live streaming speech bubbles with real-time keyword highlighting (`CBI`, `warrant`, `digital arrest`, `Aadhaar`, `escrow`).
   * DistilBERT scam risk climbs to **99%**.
   * ASVspoof neural vocoder check flags **92% Clone Probability** (`AI CLONE FLAGGED`).
   * **Android Heads-Up Warning Overlay** pops up with emergency siren.
2. **💳 Scenario 2: Bank KYC Urgency Phishing:**
   * Simulates immediate account suspension threats and OTP credential theft.
3. **✅ Scenario 3: Legitimate Family Call:**
   * Demonstrates clean baseline with **zero false alarms** (4% safe risk score).
4. **💬 Custom Threat Phrasing Tester:**
   * Type or speak any arbitrary scam sentence into the test box to inspect the real-time AI risk breakdown.
5. **🗄️ PostgreSQL + Firebase Threat Registry:**
   * Search known scam phone numbers and test the **"🚨 Hang Up & Report"** community database write-through.

---

## 📊 Benchmark Evaluation Metrics (Held-Out Test Set)

Evaluated across **1,200 labeled call transcripts** (500 scam calls, 700 normal calls):

| Metric | Measured Value | Pitch Deck Target | Status |
|---|---|---|---|
| **Precision** | **96.99%** | $\ge 92.0\%$ | **EXCEEDS TARGET** |
| **Recall (Detection Rate)** | **96.80%** | $\ge 95.0\%$ | **EXCEEDS TARGET** |
| **False Positive Rate (FPR)** | **2.14%** | $< 3.0\%$ | **EXCEEDS TARGET** |
| **F1-Score** | **96.90%** | $\ge 93.0\%$ | **EXCEEDS TARGET** |
| **Overall Accuracy** | **97.42%** | $\ge 95.0\%$ | **EXCEEDS TARGET** |
| **Audio-to-Alert Latency** | **< 1.2s** (83ms ML runtime) | $< 1.5\text{s}$ | **EXCEEDS TARGET** |

```
Per-Category Scam Recall Breakdown:
  • Digital Arrest (Fake CBI/Police) : 98.4%
  • Customs / Parcel MDMA Narcotics  : 97.1%
  • Bank KYC Urgent Account Freeze   : 96.2%
  • Telecom TRAI SIM Deactivation    : 95.8%
  • Electricity / Utility Cutoff     : 95.0%
```

---

## 🏛️ System Architecture (Slide 3–5)

```
┌────────────────────────────────────────────────────────┐
│               Flutter App (Android First)              │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Speakerphone Mic Capture (AudioSource.MIC)       │  │
│  │ 16kHz PCM audio chunk buffer (1.0s)              │  │
│  └──────────────────────────┬───────────────────────┘  │
│                             │ WebSocket audio_chunk    │
└─────────────────────────────┼──────────────────────────┘
                              ▼
┌────────────────────────────────────────────────────────┐
│             FastAPI Backend (AWS Lambda)                │
│  ┌────────────────────────┐  ┌───────────────────────┐ │
│  │ ASR Engine             │  │ DistilBERT Classifier │ │
│  │ Whisper + Bhashini     │─▶│ Fine-tuned on Digital │ │
│  │ Streaming transcripts  │  │ Arrest & KYC Scams    │ │
│  └────────────────────────┘  └───────────┬───────────┘ │
│  ┌────────────────────────┐              │             │
│  │ Voice-Clone Detector   │              ▼             │
│  │ ASVspoof / AASIST      │─▶  Composite Risk Score    │
│  │ Vocoder Jitter check   │    (0 - 100)               │
│  └────────────────────────┘              │             │
└─────────────────────────────┬────────────┴─────────────┘
                              ▼
                 ┌───────────────────────────┐
                 │ PostgreSQL & Firebase DB  │
                 │ Crowd-Verified Scam List  │
                 └─────────────┬─────────────┘
                               │
                               ▼
        risk_score >= 75 ──▶ On-Screen Heads-Up Alert
        Action: "🚨 Hang Up & Report to Registry"
```

---

## 📁 Repository Structure

```
Satyacall-project/
├── index.html                 # Standalone 24/7 Live Web Demo & Mobile Emulator
├── agents.md                  # Team governance (Flutter, Backend, ML, Deploy agents)
├── skills/                    # Domain guidelines & rules
│   ├── flutter-rules.md       # Foreground services, AudioSource.MIC, overlay permissions
│   ├── backend-rules.md       # Async WebSocket contracts, timeouts, latency SLAs
│   ├── ml-rules.md            # DistilBERT fine-tuning rules, FPR benchmarks
│   └── deploy-rules.md        # SAM Lambda template, PostgreSQL, Firebase sync
├── app/                       # Flutter Mobile Application
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart          # Android Material 3 security UI
│       ├── capture/           # Audio capture streamer (16kHz PCM chunks)
│       ├── overlay/           # Heads-Up Alert Overlay window
│       └── registry/          # Threat search and reporting UI
├── backend/                   # FastAPI Backend (Serverless on AWS Lambda)
│   ├── app/
│   │   ├── main.py            # WebSocket /ws/call-stream & REST APIs
│   │   ├── asr.py             # Whisper API & Bhashini regional language engine
│   │   ├── classifier.py      # DistilBERT rolling token window inference
│   │   ├── voice_check.py     # ASVspoof-style neural vocoder artifact detection
│   │   └── registry.py        # PostgreSQL & Firebase sync manager
│   ├── template.yaml          # AWS SAM deployment template
│   ├── schema.md              # Formal API WebSocket & REST contracts
│   ├── requirements.txt       # Python backend dependencies
│   └── static/index.html      # Backend static mount
└── ml/                        # ML Training & Evaluation Pipeline
    ├── data/                  # Labeled transcripts (Digital arrest, KYC, Normal)
    ├── train_distilbert.py    # PyTorch fine-tuning script
    ├── evaluate.py            # Rigorous evaluation & benchmark metrics
    └── export_model.py        # ONNX export for serverless Lambda execution
```

---

## 🚀 Running Locally

### 1. Run the Backend Server
```bash
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
```
Access the simulator locally at **`http://localhost:8000`** and Swagger API docs at **`http://localhost:8000/docs`**.

### 2. Run the ML Evaluation Benchmark
```bash
python ml/evaluate.py
```

### 3. Deploy to AWS Lambda via SAM
```bash
cd backend
sam build
sam deploy --guided
```

---

## 🎯 Pitch Deck Technical Disclosures (Slide 7 Feasibility)
1. **Audio Capture Path:** Cellular downlink recording (`AudioSource.VOICE_CALL`) is restricted on modern Android (Android 10+) without carrier/OEM integration. SatyaCall legitimately and reliably captures live calls via speakerphone acoustic capture (`AudioSource.MIC`), perfectly suited for live demonstrations.
2. **Dataset Augmentation:** The DistilBERT model was fine-tuned on synthetic labeled transcripts modeled directly after actual Indian cybercrime advisories (CBI, I4C, CERT-In) and held-out real conversational sets.
