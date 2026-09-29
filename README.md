<h1 align="center">DigiVote - Smart Electronic Voting System</h1>

<p align="center">
  <strong>A secure, anonymous, and intelligent voting system combining facial recognition, token-based authentication, and a modern mobile interface.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Python-3.x-3776AB?logo=python" alt="Python"/>
  <img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Raspberry%20Pi-Face%20Recognition-C51A4A?logo=raspberrypi" alt="Raspberry Pi"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
</p>

---

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Voting Flow](#voting-flow)
- [Security Model](#security-model)
- [Tech Stack](#tech-stack)
- [Firebase Collections](#firebase-collections)
- [Cloud Functions](#cloud-functions)
- [Screenshots](#screenshots)
- [Installation & Setup](#installation--setup)
- [Team](#team)
- [License](#license)

---

## Overview

**DigiVote** is a graduation project developed at the **Arab American University**, Faculty of Engineering and Information Technology, Department of Computer Systems Engineering. It is a complete smart electronic voting system designed to ensure voter authentication via facial recognition while maintaining full vote anonymity through a token-based architecture.

The system consists of three integrated components:

| Component | Technology | Role |
|-----------|-----------|------|
| **Voting Booth Controller** | Python + Raspberry Pi | Facial recognition, door control, token generation |
| **Voting & Admin App** | Flutter + Firebase | Voter interface, admin dashboard, results analytics |
| **Backend** | Firebase Firestore + Cloud Functions | Data storage, real-time sync, automated notifications |

---

## Problem Statement

Traditional voting systems face challenges including voter fraud, long queues, lack of transparency, and the risk of linking a voter's identity to their vote. DigiVote addresses these issues by combining biometric authentication with a cryptographically anonymous voting mechanism, ensuring that **no entity — not even the system administrator — can determine how a specific voter voted**.

---

## Key Features

### Voter Authentication
- **Facial Recognition** — Real-time face detection and matching using `face_recognition` library on Raspberry Pi
- **Anti-Duplicate Voting** — Voter is marked as voted immediately upon recognition, before the booth door opens
- **Device Authorization** — Kiosk tablets are authorized via unique `device_id` stored in Firestore

### Anonymous Voting
- **Token-Based Architecture** — A random UUID4 token is generated per voter with zero linkage to their identity
- **Identity-Vote Separation** — Python handles identity; Flutter handles voting. Neither side has both pieces of information
- **Dual Random Delays** — Flutter (3–10s before saving) + Python (10–60s before exit) prevent vote-timing correlation

### Admin Dashboard
- **Real-Time Results** — Live vote counts and percentages per candidate
- **City-Based Analytics** — Vote distribution filtered by voting center city
- **Push Notifications** — Admin can send manual notifications to all registered voters
- **Voter Management** — View registered voters and their voting status

### Automated Notifications (Cloud Functions)
- **Election Reminders** — Automatic reminders at 3 days, 2 days, 1 day, and election day
- **New Candidate Alerts** — Auto-notify all voters when a new candidate is added
- **New Center Alerts** — Auto-notify all voters when a new voting center is added
- **FCM Integration** — Notifications appear in the phone's notification bar (like Instagram/WhatsApp)

### Additional Features
- **Countdown Timer** — Live countdown to election day on the home screen
- **Voting Tips** — Educational tips and information cards on the home screen
- **SHA-256 Password Hashing** — Voter passwords are hashed before storage
- **Arabic TTS** — Text-to-speech reads candidate names aloud on the kiosk tablet
- **Responsive Kiosk UI** — Voting screen adapts to both portrait and landscape orientations

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        FIREBASE CLOUD                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────┐   │
│  │  voters   │  │  tokens  │  │  votes   │  │ booth_status  │   │
│  │          │  │          │  │          │  │               │   │
│  │ face_img │  │ token    │  │ cand_id  │  │ status        │   │
│  │ has_voted│  │ used     │  │ token    │  │ current_token │   │
│  └──────────┘  └──────────┘  └──────────┘  └───────────────┘   │
│                                                                 │
│  ┌──────────────────────┐  ┌─────────────────────────────────┐  │
│  │   Cloud Functions    │  │      FCM (Push Notifications)   │  │
│  │ • electionReminder   │  │  • Manual admin notifications   │  │
│  │ • onNewCandidate     │  │  • Automated event triggers     │  │
│  │ • onNewVotingCenter  │  │  • Election day reminders       │  │
│  │ • sendNotification   │  └─────────────────────────────────┘  │
│  └──────────────────────┘                                       │
└──────────────────────┬──────────────────────┬───────────────────┘
                       │                      │
          ┌────────────▼────────┐   ┌─────────▼──────────┐
          │   RASPBERRY PI      │   │   FLUTTER APP       │
          │                     │   │                     │
          │ • Face Recognition  │   │ VOTER:              │
          │ • Token Generation  │   │ • Login / Profile   │
          │ • has_voted = true  │   │ • View Candidates   │
          │ • Servo Door Control│   │ • Countdown Timer   │
          │ • Security Delays   │   │ • Tips & Info       │
          │                     │   │                     │
          │ Knows: voter_id     │   │ KIOSK (Tablet):     │
          │ Sends: token only   │   │ • Read token only   │
          │                     │   │ • Cast vote         │
          └─────────────────────┘   │ • Random delay      │
                                    │ • TTS candidates    │
                                    │                     │
                                    │ ADMIN:              │
                                    │ • Results & Charts  │
                                    │ • City Analytics    │
                                    │ • Send Notifications│
                                    │ • Manage Voters     │
                                    └─────────────────────┘
```

---

## Voting Flow

```
1. VOTER APPROACHES BOOTH
   │
   ▼
2. RASPBERRY PI — Face Recognition
   │  Compare face against registered voters in Firebase
   │  If match found and has_voted == false:
   │
   ▼
3. PYTHON — Mark has_voted = true IMMEDIATELY
   │  (Prevents double voting even if system crashes)
   │
   ▼
4. PYTHON — Generate Random UUID4 Token
   │  Token saved to 'tokens' collection (used: false)
   │  Token is NOT linked to voter_id anywhere
   │
   ▼
5. PYTHON — Set booth_status = "occupied"
   │  booth_status contains ONLY the token (no voter_id)
   │
   ▼
6. SERVO — Open door → Voter enters → Door closes
   │
   ▼
7. FLUTTER KIOSK — Reads token from booth_status
   │  Displays candidates with TTS
   │  Voter selects a candidate
   │
   ▼
8. FLUTTER — Random Delay (3-10 seconds)
   │  Prevents vote-timestamp correlation
   │
   ▼
9. FLUTTER — Save vote to 'votes' collection
   │  Vote contains ONLY: candidate_id + token
   │  Mark token as used, set booth_status = "available"
   │
   ▼
10. PYTHON — Detects booth is available
    │  Random Delay (10-60 seconds)
    │  Prevents exit-timing correlation
    │
    ▼
11. SERVO — Open door → Voter exits → Door closes
    │
    ▼
12. SYSTEM READY for next voter
```

---

## Security Model

### Core Principle: Identity-Vote Separation

The system is designed so that **no single component** holds both the voter's identity and their vote choice.

| Component | Knows Voter Identity | Knows Vote Choice |
|-----------|:-------------------:|:-----------------:|
| Python (Raspberry Pi) | ✅ | ❌ |
| Flutter Kiosk | ❌ | ✅ |
| Firebase booth_status | ❌ (token only) | ❌ |
| Firebase votes collection | ❌ (token only) | ✅ |
| Admin Dashboard | ❌ | Aggregate only |

### Security Measures

- **Immediate `has_voted` Flag** — Set before the door opens, preventing any race condition
- **Anonymous Tokens** — UUID4 tokens with no cryptographic link to voter identity
- **Dual Random Delays** — Break timing correlation between entry, vote, and exit
- **No Voter ID in Transit** — `voter_id` exists only in Python's RAM during the session
- **Device Authorization** — Only pre-authorized tablets can access the kiosk voting screen
- **SHA-256 Password Hashing** — Passwords are hashed using the `crypto` package before storage
- **Firestore Security Rules** — Votes and tokens cannot be deleted via client SDK

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile App** | Flutter (Dart) |
| **Backend** | Firebase Firestore, Firebase Auth |
| **Cloud Functions** | Node.js (Firebase Functions v2) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) + flutter_local_notifications |
| **Booth Controller** | Python 3 on Raspberry Pi |
| **Face Recognition** | `face_recognition` + `OpenCV` |
| **Camera** | Picamera2 (Raspberry Pi Camera Module) |
| **Door Mechanism** | Servo Motor via RPi.GPIO |
| **Password Security** | SHA-256 (crypto package) |

---

## Firebase Collections

| Collection | Key Fields | Purpose |
|-----------|-----------|---------|
| `voters` | `full_name`, `national_id`, `face_image_base64`, `has_voted`, `password`, `fcm_token`, `city` | Registered voter data |
| `candidates` | `name`, `age`, `party`, `image_base64`, `bio`, `qualifications` | Election candidates |
| `votes` | `candidate_id`, `token` | Anonymous vote records |
| `tokens` | `token`, `used` | Generated voting tokens |
| `booth_status` | `status`, `current_token` | Real-time booth state |
| `voting_centers` | `name`, `city`, `address`, `booth_count` | Polling locations |
| `authorized_devices` | `device_id`, `center_name` | Authorized kiosk tablets |
| `notifications` | `title`, `body`, `timestamp` | Admin-sent notifications |
| `election_settings` | `election_date`, `election_name` | Election configuration |

---

## Cloud Functions

Four Cloud Functions (v2) are deployed for automated operations:

| Function | Trigger | Description |
|----------|---------|-------------|
| `sendNotification` | Firestore `onCreate` on `notifications` | Sends FCM push to all voters when admin adds a notification |
| `electionReminder` | Scheduled (daily at 9:00 AM) | Sends reminders at 3, 2, 1, and 0 days before election |
| `onNewCandidate` | Firestore `onCreate` on `candidates` | Auto-notifies all voters when a new candidate is registered |
| `onNewVotingCenter` | Firestore `onCreate` on `voting_centers` | Auto-notifies all voters when a new voting center is added |

---


## Installation & Setup

### Prerequisites

- Flutter SDK 3.x+
- Python 3.9+
- Raspberry Pi 4 with Camera Module
- Firebase project (Blaze plan for Cloud Functions)
- Node.js 18+ (for Cloud Functions)

### Flutter App

```bash
# Clone the repository
git clone https://github.com/your-username/digivote.git
cd digivote

# Install dependencies
flutter pub get

# Run on device
flutter run

# Build APK for distribution
flutter build apk --release
```

### Raspberry Pi (Booth Controller)

```bash
# Install dependencies
pip install opencv-python face_recognition firebase-admin picamera2 numpy RPi.GPIO

# Place your Firebase service account key as firebase_key.json
# Run the booth controller
python voting_booth_final.py
```

### Cloud Functions

```bash
cd functions

# Install dependencies
npm install

# Deploy to Firebase
firebase deploy --only functions
```

### Firebase Setup

1. Create a Firebase project and enable Firestore
2. Upgrade to Blaze plan (required for Cloud Functions)
3. Add the collections listed in [Firebase Collections](#firebase-collections)
4. Generate a service account key (`firebase_key.json`) for the Raspberry Pi
5. Enable Firebase Cloud Messaging for push notifications
6. Deploy Firestore security rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /votes/{voteId} {
      allow read, create: if true;
      allow delete, update: if false;
    }
    match /tokens/{tokenId} {
      allow read, create, update: if true;
      allow delete: if false;
    }
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## Team

**Arab American University**
Faculty of Engineering and Information Technology
Department of Computer Systems Engineering

| Role | Name |
|------|------|
| **Supervisor** | Prof. Mohammad Awad |
| **Developer — Flutter & Firebase** | Riham Ararawi |
| **Developer — Flutter & Firebase** | Areen Hantoli |
| **Developer — AI & Hardware** | Hamsa Qasim Suliman |

---

## License

This project is developed as a graduation project at the Arab American University. All rights reserved.

---

<p align="center">
  <strong>DigiVote</strong> — Secure. Anonymous. Smart.
</p>
