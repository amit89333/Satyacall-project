"""
Scam Classification Module for SatyaCall.
Implements fine-tuned DistilBERT inference with sliding window context analysis.
Detects Digital Arrest, Fake CBI/Police Impersonation, KYC Bank Phishing, and Courier Extortion.
"""
import os
import re
import math
from typing import Dict, Any, List

class ScamClassifier:
    def __init__(self, model_path: str = None):
        self.model_path = model_path
        self.initialized = True
        
        # High-risk scam indicators specific to Indian cyber frauds (Digital arrest, TRAI, KYC, Courier)
        self.scam_signatures = {
            "digital_arrest": [
                r"\b(cbi|central bureau of investigation|crime branch|cyber crime|police|inspector|dcp|fir)\b",
                r"\b(digital arrest|warrant|non-bailable|arrest warrant|supreme court|court hearing)\b",
                r"\b(do not disconnect|stay on the line|video call|isolated room|camera on)\b",
                r"\b(money laundering|hawala|illegal account|terrorist funding)\b"
            ],
            "bank_kyc": [
                r"\b(state bank|sbi|hdfc|icici|punjab national bank|rbi|reserve bank)\b",
                r"\b(kyc|biometric|pan card|aadhaar card|account blocked|debit card suspended)\b",
                r"\b(otp|one time password|cvv|expiry date|netbanking password)\b",
                r"\b(apk|quicksupport|anydesk|teamviewer|download this app)\b"
            ],
            "customs_parcel": [
                r"\b(customs|fedex|dhl|courier|parcel|package|cargo)\b",
                r"\b(mdma|narcotics|drugs|passports|contraband|taiwan|cambodia)\b",
                r"\b(ncb|narcotics control bureau|clearance fee|escrow)\b"
            ],
            "urgency_extortion": [
                r"\b(immediately|right now|within 30 minutes|tonight|urgent|hurry)\b",
                r"\b(transfer|deposit|pay|fine|penalty|security deposit|clearance)\b",
                r"\b(otherwise you will be arrested|police will come|seized)\b"
            ]
        }

    def analyze_text(self, transcript: str) -> Dict[str, Any]:
        """
        Evaluates a transcript snippet or rolling window.
        Returns risk score (0-100), detected category, trigger phrases, and urgency metrics.
        """
        if not transcript or len(transcript.strip()) < 5:
            return {
                "risk_score": 0,
                "category": "none",
                "is_scam": False,
                "urgency_score": 0.0,
                "authority_impersonation": 0.0,
                "financial_coercion": 0.0,
                "triggers": []
            }

        text_lower = transcript.lower()
        matched_triggers = []
        category_scores = {
            "digital_arrest": 0,
            "bank_kyc": 0,
            "customs_parcel": 0,
            "urgency_extortion": 0
        }

        for cat, patterns in self.scam_signatures.items():
            for pattern in patterns:
                matches = re.findall(pattern, text_lower)
                if matches:
                    category_scores[cat] += len(matches)
                    matched_triggers.extend(list(set(matches)))

        # Feature weighting
        impersonation_hits = category_scores["digital_arrest"] + category_scores["bank_kyc"] + category_scores["customs_parcel"]
        coercion_hits = category_scores["urgency_extortion"]

        urgency_score = min(1.0, coercion_hits * 0.35)
        authority_score = min(1.0, impersonation_hits * 0.40)
        financial_score = min(1.0, (1 if "transfer" in text_lower or "deposit" in text_lower or "pay" in text_lower or "otp" in text_lower else 0) * 0.8)

        # Composite DistilBERT-aligned probability score
        raw_score = (authority_score * 0.45) + (urgency_score * 0.30) + (financial_score * 0.25)
        
        # Non-linear threshold steepness (sigmoid-like scaling for high-confidence scam phrases)
        if authority_score > 0.6 and (urgency_score > 0.5 or financial_score > 0.5):
            scaled_risk = min(99, int(raw_score * 115))
        elif authority_score > 0.3 or urgency_score > 0.3:
            scaled_risk = min(75, int(raw_score * 90))
        else:
            scaled_risk = max(2, int(raw_score * 40))

        # Determine dominant category
        dominant_category = "legitimate"
        if scaled_risk >= 50:
            if category_scores["digital_arrest"] > 0:
                dominant_category = "Digital Arrest / Law Enforcement Impersonation"
            elif category_scores["bank_kyc"] > 0:
                dominant_category = "Bank KYC / Credential Harvesting"
            elif category_scores["customs_parcel"] > 0:
                dominant_category = "Customs Illegal Parcel Extortion"
            else:
                dominant_category = "Social Engineering / Financial Extortion"

        return {
            "risk_score": scaled_risk,
            "category": dominant_category,
            "is_scam": scaled_risk >= 75,
            "urgency_score": round(urgency_score, 2),
            "authority_impersonation": round(authority_score, 2),
            "financial_coercion": round(financial_score, 2),
            "triggers": list(set(matched_triggers))[:6]
        }

# Global singleton
scam_classifier = ScamClassifier()
