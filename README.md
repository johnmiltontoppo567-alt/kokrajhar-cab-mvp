# Kokrajhar Cab MVP

## Overview
Kokrajhar Cab is a minimal cab-booking MVP built to validate a local ride-booking flow.
The app focuses on correct state handling, real backend interaction, and clean UI discipline —
not scale or monetization.

## Features
- Book the nearest available driver
- Live driver availability (Available / Busy)
- Prevent duplicate bookings
- Lock inputs during active trip
- Complete trip with confirmation
- Backend-driven state (no mock data)

## Tech Stack
### Frontend
- Flutter (Web / Android / iOS)

### Backend
- Node.js
- Express
- JSON file storage (MVP persistence)

## Architecture
Flutter frontend communicating with a Node.js backend via REST APIs.

Frontend structure:
```text
lib/
├── core/        # constants & app-wide config
├── models/      # Driver, Ride
├── screens/     # UI screens
├── services/    # API layer
└── main.dart
```

## How to Run

### Backend
```bash
cd cab-backend
npm install
node server.js
```
### Frontend
```bash
cd cab_client
flutter run
```
Backend runs at:
http://localhost:3000

Android Emulator uses:
http://10.0.2.2:3000


