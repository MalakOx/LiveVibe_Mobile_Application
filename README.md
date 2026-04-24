# LiveVibe

> An interactive live presentation platform built with Flutter and Firebase.  
> Hosts create quiz sessions; participants join in real-time and answer questions from their phones.

---

## Features

### Host
- Email/password authentication via Firebase Auth
- Create and manage sessions with a unique 6-character code
- Slide editor: add MCQ, Open Text, and Word Cloud slides
- Start/stop a countdown timer per slide
- Navigate between slides in real-time
- Watch live results, response distribution, and leaderboard
- Session history with past results
- Duplicate a session as a template

### Participant
- Join without creating an account — enter session code or scan a QR code
- Pick a name and emoji avatar
- Answer MCQ (single or multiple selection), open text, and word cloud slides
- See a real-time countdown timer
- Speed-based scoring: faster correct answers earn more points
- Final leaderboard with personal rank

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart ≥ 3.3) |
| Backend | Firebase (Firestore + Firebase Auth) |
| State management | Riverpod 2 (flutter_riverpod + riverpod_annotation) |
| Navigation | go_router 14 |
| QR | qr_flutter + mobile_scanner |
| UI | google_fonts, flutter_animate, lottie |
| Utilities | uuid, equatable, dartz, share_plus, intl |
| Font | Outfit (custom, bundled) |

---

## Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.3
- A Firebase project with **Firestore** and **Authentication** (Email/Password) enabled
- `flutterfire` CLI (optional, for re-configuring)

### Steps

```bash
# 1. Clone the repository
git clone <repo-url>
cd livepulse_v2

# 2. Install dependencies
flutter pub get

# 3. Firebase is already configured — ensure firebase_options.dart is present.
#    To reconfigure: flutterfire configure

# 4. Deploy Firestore rules
firebase deploy --only firestore:rules

# 5. Run the app
flutter run
```

> The app locks to **portrait mode** on all platforms.

---

## Project Structure

```
lib/
├── main.dart                  # Entry point, Firebase init
├── app.dart                   # MaterialApp.router + theme
├── firebase_options.dart      # Generated Firebase config
│
├── core/
│   ├── constants/             # App colors, strings
│   ├── extensions/            # BuildContext extensions
│   ├── providers/             # Theme provider
│   ├── router/                # go_router configuration
│   ├── theme/                 # Light & dark ThemeData
│   └── utils/                 # ID generator, helpers
│
├── features/
│   ├── auth/                  # Firebase Auth (host only)
│   │   ├── data/              # Datasource + models
│   │   ├── domain/            # Entities, repository interface, providers
│   │   └── presentation/      # Login, register, QR scanner screens
│   │
│   ├── home/                  # Session history (host)
│   │
│   └── session/               # Core session logic
│       ├── data/
│       │   ├── models/        # Session, Slide, Participant, Response models
│       │   └── datasources/   # FirestoreDatasource (all Firestore ops)
│       ├── domain/
│       │   └── providers/     # SessionController, ParticipantController, ResponseController
│       └── presentation/
│           ├── host/          # Create, editor, dashboard, live results screens
│           ├── participant/   # Join, waiting room, answer, results screens
│           └── shared/        # SessionFinalDashboard (host + participant)
│
└── shared/
    └── widgets/               # Reusable UI: GlassCard, PulseButton, AnimatedGradientBg
```

---

## Firestore Data Structure

```
sessions/{sessionId}
├── slides/{slideId}
├── participants/{participantId}
└── responses/{responseId}
```

---

## License

Academic project — ISI Ariana