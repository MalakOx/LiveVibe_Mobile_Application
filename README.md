# LivePulse

> An interactive real-time presentation platform built with Flutter and Firebase.  
> Hosts create quiz sessions and control them live; participants join via code or QR scan and answer questions in real-time, competing on a live leaderboard.

**Status:** Production-ready with recent architectural improvements (ScoringService extraction, pagination, component optimization)

---

## 🎯 Quick Overview

**LivePulse** enables interactive Q&A sessions for classrooms, training, or presentations. The host (teacher/presenter) controls the session and views live analytics, while participants answer questions from their phones with speed-based scoring and instant feedback.

### Two Distinct Roles

- **Host** - Authenticated via email/password. Creates sessions, designs slides, manages participants, and views live results.
- **Participant** - Anonymous (no account needed). Joins via code or QR scan, answers questions, earns points based on correctness and speed.

---

## ✨ Features

### Host Capabilities
- ✅ Secure email/password authentication (Firebase Auth)
- ✅ Session management with auto-generated 6-character shareable code
- ✅ Powerful slide editor supporting three question types:
  - Multiple Choice (single or multiple correct answers)
  - Open Text (free-form responses)
  - Word Cloud (keyword submissions with frequency visualization)
- ✅ Real-time session control: navigate slides, start/stop countdown timers
- ✅ Live analytics dashboard: response distribution, leaderboard, participant tracking
- ✅ Session history with detailed past results
- ✅ Duplicate sessions as templates for reuse
- ✅ QR code generation for easy participant access

### Participant Features
- ✅ Frictionless joining: enter code or scan QR code (no account required)
- ✅ Personalization: choose display name and emoji avatar
- ✅ Real-time response experience with countdown timers
- ✅ Intelligent scoring: correct answers + speed bonus (0-100 points)
- ✅ Immediate feedback: see if answer is correct and points earned
- ✅ Live leaderboard with personal rank and score tracking
- ✅ Multiple question type support: MCQ, open text, word clouds

---

## 🏗️ Architecture Overview

LivePulse follows **Clean Architecture** with a feature-first structure and three layers per feature:

```
┌─────────────────────────────────────┐
│     PRESENTATION (UI)               │
│  Screens, Widgets, ConsumerWidget   │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│     DOMAIN (Business Logic)         │
│  Providers, Services, Entities      │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│     DATA (Persistence)              │
│  Datasources, Models, Firebase      │
└─────────────────────────────────────┘
```

- **Unidirectional data flow** - UI depends on Domain, Domain depends on Data
- **Reactive state management** - Riverpod providers auto-update UI on data changes
- **Real-time synchronization** - Firestore streams keep all participants in sync
- **Feature-isolated** - Each feature (auth, session, home) is independent

### Key Architectural Improvements

- **ScoringService** - Centralized scoring logic (extracted from scattered code) for consistency across UI and persistence layers
- **Pagination** - Limits applied to leaderboards (top 50) and responses (first 50) for scalability
- **Component Extraction** - LiveSessionHeaderWidget and other widgets reduce duplication
- **Error Handling** - Centralized ErrorHandler replaces 50+ scattered error patterns

---

## 🛠️ Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | Flutter 3.3+ (Dart 3.3+) | Cross-platform mobile app |
| **Backend** | Firebase Firestore | Real-time NoSQL database |
| **Auth** | Firebase Authentication | Host account security |
| **State Management** | Riverpod 2.5+ | Reactive state & provider pattern |
| **Routing** | GoRouter 14+ | Declarative navigation with guards |
| **QR** | qr_flutter + mobile_scanner | QR generation and scanning |
| **UI/UX** | Flutter Animate, Lottie | Smooth animations and transitions |
| **Typography** | Google Fonts (Outfit) | Custom fonts |
| **Charts** | Charts Flutter | Answer distribution visualization |
| **Utilities** | uuid, equatable, dartz, intl | ID gen, equality, functional programming |

---

## 📦 Project Structure

```
lib/
├── main.dart                          # Entry point, Firebase init
├── app.dart                           # MaterialApp + router setup
├── firebase_options.dart              # Auto-generated Firebase config
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart           # Color palette (light/dark)
│   │   ├── app_dimensions.dart       # Spacing, padding constants
│   │   └── app_animations.dart       # Animation timing curves
│   ├── extensions/
│   │   └── context_extensions.dart   # BuildContext helpers
│   ├── providers/
│   │   └── theme_provider.dart       # Dark/light theme toggle
│   ├── router/
│   │   └── app_router.dart           # GoRouter config + auth guards
│   ├── theme/
│   │   └── app_theme.dart            # Material3 theme definitions
│   └── utils/
│       └── id_generator.dart         # Session code, UUID generation
│
├── features/
│   ├── auth/                         # Host authentication
│   │   ├── data/
│   │   │   ├── datasources/          # Firebase Auth calls
│   │   │   └── models/               # AuthUserModel
│   │   ├── domain/
│   │   │   ├── entities/             # AuthUser, UserRole
│   │   │   └── providers/            # Auth state providers
│   │   └── presentation/
│   │       ├── host_auth_screen.dart
│   │       ├── participant_entry_screen.dart
│   │       ├── participant_name_screen.dart
│   │       ├── qr_scanner_screen.dart
│   │       └── splash_screen.dart
│   │
│   ├── home/                         # Session history
│   │   └── presentation/
│   │       ├── session_history_screen.dart
│   │       └── session_history_results_screen.dart
│   │
│   ├── session/                      # Core quiz logic (LARGEST)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── firestore_datasource.dart  # All Firestore ops
│   │   │   └── models/
│   │   │       ├── session_model.dart
│   │   │       ├── slide_model.dart
│   │   │       ├── participant_model.dart
│   │   │       └── response_model.dart
│   │   ├── domain/
│   │   │   ├── providers/
│   │   │   │   └── session_provider.dart  # StreamProviders + AsyncNotifiers
│   │   │   └── services/
│   │   │       └── scoring_service.dart   # Centralized scoring logic
│   │   └── presentation/
│   │       ├── host/
│   │       │   ├── create_session_screen.dart
│   │       │   ├── host_dashboard_screen.dart
│   │       │   ├── slide_editor_screen.dart
│   │       │   ├── live_results_screen.dart
│   │       │   └── widgets/
│   │       │       └── live_session_header_widget.dart
│   │       ├── participant/
│   │       │   ├── join_session_screen.dart
│   │       │   ├── waiting_room_screen.dart
│   │       │   ├── answer_screen.dart
│   │       │   └── participant_results_screen.dart
│   │       └── shared/
│   │           └── session_final_dashboard.dart
│   │
│   └── slides/                       # Slide visualization
│       └── presentation/widgets/
│           ├── result_bar_chart.dart
│           ├── word_cloud_widget.dart
│           └── timer_widget.dart
│
└── shared/
    └── widgets/
        ├── glass_card.dart           # Frosted glass effect
        ├── animated_gradient_bg.dart # Animated background
        ├── pulse_button.dart         # Custom button
        ├── mcq_widget.dart           # MCQ renderer
        ├── open_text_widget.dart     # Text input
        ├── timer_widget.dart         # Countdown timer
        ├── word_cloud_widget.dart    # Word frequency viz
        ├── results_card.dart         # Result display
        ├── loading_overlay.dart      # Loading indicator
        ├── error_state.dart          # Error UI
        ├── empty_state.dart          # Empty state UI
        ├── status_badge.dart         # Status indicator
        └── ... (12 more reusable widgets)
```

---

## 🚀 Setup & Run

### Prerequisites
- **Flutter SDK** ≥ 3.3.0
- **Dart** ≥ 3.3.0
- **Firebase Project** with:
  - Cloud Firestore enabled
  - Authentication (Email/Password) enabled
  - Firestore security rules deployed
- **Android Studio** or **Xcode** (for device testing)

### Installation Steps

```bash
# 1. Clone the repository
git clone <repo-url>
cd livepulse_v2

# 2. Install Flutter dependencies
flutter pub get

# 3. Verify Firebase configuration
# Firebase is pre-configured. To reconfigure:
# flutterfire configure

# 4. Deploy Firestore security rules
firebase deploy --only firestore:rules

# 5. Run on emulator or device
flutter run

# Or specify a device:
flutter run -d <device_id>
```

### Configuration Notes
- App is **locked to portrait mode** on all platforms
- Firebase config already present in `lib/firebase_options.dart` (auto-generated)
- Firestore rules in `firestore.rules` must be deployed before host authentication works
- For development, you can modify Firestore rules to allow anonymous writes

---

## 📱 Data Flow Example: Participant Answering

```
1. Participant sees question on answer_screen
   ↓
2. Selects option (MCQ) or types response (open text)
   ↓
3. ScoringService calculates: Is correct? + Speed bonus
   ↓
4. ResponseController.submitResponse() validates & writes to Firestore
   ↓
5. Firestore triggers real-time updates (streams)
   ↓
6. Host's live_results_screen rebuilds with new response
   ↓
7. Participant score updated in leaderboard
   ↓
8. Participant sees feedback: ✅ +85 points
```

---

## 🔄 Real-Time Synchronization

LivePulse achieves real-time sync without polling using **Firestore Streams**:

- **Session Status Changes** (waiting → live → ended) broadcast to all participants instantly
- **Slide Navigation** - When host moves to next question, all participants' screens update automatically
- **Live Leaderboard** - Participant scores update as responses come in (top 50 only for scalability)
- **Response Feed** - Host sees new responses appear in real-time
- **Timer Synchronization** - Host starts timer, all participants receive signal and countdown locally

---

## 🗄️ Firebase Data Structure

```
collections/
├── sessions/ (host-owned documents)
│   ├── {sessionId}
│   │   ├── id, title, hostId, hostName
│   │   ├── code (6-char shareable code)
│   │   ├── status (waiting | live | ended)
│   │   ├── currentSlideId, timerActive, timerSeconds
│   │   └── settings (allowLateJoin, showCorrectAnswers, etc.)
│   │
│   ├── slides/ (questions, subcollection)
│   │   ├── {slideId}
│   │   │   ├── type (mcq | openText | wordCloud)
│   │   │   ├── question, options[], correctOptionIndices[]
│   │   │   ├── answerMode (single | multiple) [NEW]
│   │   │   ├── points, timeLimit
│   │   │   └── createdAt
│   │   │
│   │   ├── responses/ (real-time answers, subcollection)
│   │   │   ├── {responseId}
│   │   │   │   ├── participantId, participantName
│   │   │   │   ├── value, isCorrect, pointsEarned
│   │   │   │   ├── responseTimeMs, submittedAt
│   │   │   │   └── ... (immutable after creation)
│   │
│   ├── participants/ (real-time leaderboard, subcollection)
│   │   ├── {participantId}
│   │   │   ├── name, avatar, score, rank, streak
│   │   │   ├── joinedAt, isOnline, answeredSlides[]
│   │   │   └── ... (updated in real-time)
│
└── users/ (authenticated hosts only)
    ├── {uid}
    │   ├── email, displayName, role: 'host'
    │   └── createdAt
```

---

## 🎨 Key Concepts

### Scoring System
- **Full Correct:** 50 + speed bonus (0-50 points) = 50-100 points
- **Speed Bonus:** Based on time taken vs. time limit
- **Partial Correct (MCQ):** 50% of full points if not all correct answers selected
- **Open Text/Word Cloud:** Fixed 10 participation points

### Pagination & Scalability
- **Leaderboard:** Top 50 participants by score (prevents OOM for large sessions)
- **Responses:** First 50 responses per question (avoids Firestore limits)
- **Slides:** All slides loaded (typically <100 per session)

### State Management (Riverpod)
- **StreamProvider** - Real-time data from Firestore (session, participants, responses)
- **AsyncNotifierProvider** - Multi-step operations (create session, submit response)
- **Provider** - Computed values (ScoringService, theme)
- **Dependency Injection** - Providers handle all service instantiation

---

## 📊 Performance Optimizations

- ✅ **Firestore Limits** - Pagination applied to prevent expensive queries
- ✅ **Client-Side Timer** - Timer rendered locally, not synced per tick (saves writes)
- ✅ **Component Extraction** - Reduced duplication and complexity
- ✅ **Lazy Loading** - Pages only fetch data when needed
- ✅ **Error Boundaries** - Centralized error handling via ErrorHandler

---


