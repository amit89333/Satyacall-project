# ML Rules for SatyaCall

## DistilBERT Fine-Tuning & Evaluation
- False Positive Rate (FPR) must be explicitly benchmarked and kept <= 3.0% — false alarms cause users to disable fraud protection.
- Target Precision: >= 93%, Recall: >= 95%.
- Dataset: Maintain synthetic transcripts in `/ml/data/synthetic_transcripts.json` covering:
  - Digital arrest / fake police / fake CBI officers
  - Telecom SIM deactivation threats
  - Customs/Courier illegal parcel extortion (Aadhaar linkage)
  - Bank KYC expiry / OTP theft
  - Legitimate casual, business, and family calls.
- Rolling Window: Evaluate sliding context windows of 30-50 tokens to ensure early scam detection before financial harm occurs.

## ASVspoof Voice Clone Verification
- Run feature extraction on spectral flatness, pitch contour jitter, and high-frequency vocoder artifacts.
- Return an authenticity probability (0.0 = completely synthetic AI voice, 1.0 = organic human speech).
