# SatyaCall Team

## Flutter Agent
Owns `/app`. Flutter/Dart, Android-first (minSdk that supports foreground services
and overlay windows for the on-screen alert). Never assumes `VOICE_CALL` audio
source works — builds against speakerphone `MIC` capture per the pitch deck plan.

## Backend Agent
Owns `/backend`. Python 3.11+, FastAPI, deployable via AWS SAM to Lambda +
API Gateway WebSocket. Every model call (ASR, classifier, voice-check) is wrapped
in a timeout + fallback so a slow API never hangs the pipeline.

## ML Agent
Owns `/ml`. Generates the synthetic labeled dataset, fine-tunes DistilBERT,
evaluates precision/recall/false-positive rate (false positives matter more than false negatives
for a fraud-alert product), exports a model the Backend Agent can load.

## Deploy Agent
Owns `template.yaml`, Postgres/Firebase provisioning, and the landing page +
APK distribution. Verifies every deployment with a live health check and a
screenshot before marking a task done.
