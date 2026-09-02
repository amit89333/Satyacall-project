# Deploy Rules for SatyaCall

## AWS Serverless Architecture
- Deploy via AWS SAM (`backend/template.yaml`).
- API Gateway WebSocket API routing `$connect`, `$default`, `$disconnect` to the Lambda function.
- Mangum ASGI handler connects FastAPI endpoints to API Gateway HTTP/REST.

## Threat Registry Persistence
- Primary OLTP: PostgreSQL database holding table `reported_numbers(number, report_count, category, first_reported, last_reported)`.
- Real-time event sink: Firebase Firestore collection `threat_feed` triggering instant client sync.
- Verification: Every deployment requires a live health check endpoint `GET /health` returning `200 OK`.
