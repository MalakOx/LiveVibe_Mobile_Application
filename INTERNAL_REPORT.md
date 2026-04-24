# LivePulse — Internal Technical Report

---

## 1. Project Overview

**LivePulse** (package name: `livevibe`) is a real-time interactive quiz/presentation platform built with Flutter. It has two distinct user roles:

- **Host** — authenticated (Firebase Auth), creates and controls sessions
- **Participant** — anonymous, joins a session via code or QR scan

All data is stored and synced in real-time via **Cloud Firestore**.

---

## 2. Architecture

The project follows a **feature-first Clean Architecture** with three layers per feature:

```
features/<feature>/
├── data/
│   ├── datasources/    ← Raw Firebase calls
│   ├── models/         ← Firestore ↔ Dart serialization
│   └── repositories/   ← (auth only) implementation
├── domain/
│   ├── entities/       ← Pure Dart business objects
│   ├── providers/      ← Riverpod providers / notifiers
│   └── repositories/   ← (auth only) abstract interface
└── presentation/
    └── screens/        ← UI, ConsumerWidget / ConsumerStatefulWidget
```

**State management:** Riverpod 2 (`flutter_riverpod`).  
All providers are declared using `Provider`, `StreamProvider`, `AsyncNotifierProvider`.

**Navigation:** `go_router` with an auth guard.  
- Unauthenticated users land on `/participant/entry`.  
- Authenticated hosts land on `/host/dashboard`.  
- All `/host/*` routes (except `/host/auth`) are protected by a redirect guard.

**Entry point flow:**
```
main() → Firebase.initializeApp() → ProviderScope → LiveVibeApp
                                                        ↓
                                              MaterialApp.router (go_router)
                                                        ↓
                                              authStateProvider (stream)
                                                        ↓
                                    isAuthenticated? → /host/dashboard : /participant/entry
```

---

## 3. App Flow

### 3.1 Host Flow

```
/host/auth         → Sign Up / Sign In (Firebase Auth)
       ↓
/host/dashboard    → Lists past sessions (SessionHistoryScreen)
       ↓
/host/create       → Create new session (title, settings)
       ↓
/host/editor/:id   → Slide editor — add MCQ / Open Text / Word Cloud slides
       ↓
/host/session/:id  → Session dashboard — shows QR code, participant list, starts session
       ↓
/host/live/:id     → Live results — navigate slides, start/stop timer, view real-time responses
       ↓
/session/final/:id → Final leaderboard (host view)
```

**Key host actions:**
- `SessionController.createSession()` — generates a 6-char alphanumeric code via `IdGenerator`
- `SessionController.startSession()` — fetches slides, sets `status = live`, sets `currentSlideId`
- `SessionController.navigateSlide()` — updates `currentSlideIndex` + `currentSlideId` in Firestore
- `SessionController.toggleTimer()` — sets `timerActive = true/false` in Firestore
- `SessionFinishNotifier.finishSession()` — sets `status = ended`, then waits for Firestore stream confirmation before navigating (ensures participants are notified before host moves)
- `SessionController.deleteSession()` — cascades deletion of slides and participants

---

### 3.2 Participant Flow

```
/participant/entry → Enter session code manually OR tap QR scan
       ↓
/participant/qr    → Camera-based QR scanner (mobile_scanner)
       ↓
/participant/name/:code → Enter display name + choose emoji avatar
       ↓
/session/waiting/:code  → Waiting room (watches session status via stream)
       ↓ (when status → live)
/session/answer/:sessionId/:participantId → Answer screen (real-time)
       ↓ (when status → ended)
/session/final/:sessionId/:participantId  → Final leaderboard (participant view)
```

**Key participant actions:**
- `ParticipantController.joinSession()` — resolves code to session ID, checks `allowLateJoin`, creates participant doc
- Duplicate-name guard: checks if name already exists in `participants` subcollection; if so, sets `isOnline = true`
- `ResponseController.submitResponse()` — checks duplicate response, calculates speed-based score, writes `ResponseModel` to Firestore
- `setParticipantOffline()` — called on disconnect

---

## 4. Firebase Structure

### Collections

```
sessions/                          ← Root collection
  {sessionId}/
    title, hostId, hostName, code
    status: "waiting" | "live" | "ended"
    currentSlideIndex, currentSlideId
    timerSeconds, timerActive
    participantCount, slideCount
    createdAt, startedAt, endedAt
    settings: { showLeaderboard, allowLateJoin, shuffleOptions }

    slides/                        ← Subcollection
      {slideId}/
        sessionId, type, order, question
        options[], correctOptionIndex
        correctOptionIndices[], answerMode
        points, timeLimit, isActive
        imageUrl, createdAt

    participants/                  ← Subcollection
      {participantId}/
        sessionId, name, avatar
        score, rank, streak
        joinedAt, isOnline
        answeredSlides[]

    responses/                     ← Subcollection
      {responseId}/
        sessionId, slideId
        participantId, participantName
        type, value
        selectedOptionIndex, isCorrect
        pointsEarned, responseTimeMs
        submittedAt
```

---

## 5. Data Models

### `SessionModel`
Represents a quiz session. Key fields:
- `status` (enum: `waiting`, `live`, `ended`) — drives navigation for all participants via a `StreamProvider`
- `currentSlideId` — the slide all participants currently see
- `timerActive` — when `true`, participants can submit answers; the countdown is rendered client-side using `Timer.periodic`
- `settings` (`SessionSettings`) — nested object: leaderboard visibility, late join permission, shuffle options

### `SlideModel`
Represents one question slide. Key fields:
- `type` (enum: `mcq`, `openText`, `wordCloud`) — determines which UI widget is rendered on the answer screen
- `answerMode` (enum: `single`, `multiple`) — MCQ only; controls single vs. checkbox-style selection
- `correctOptionIndices` — supports multiple correct answers
- `timeLimit` — used for speed-based scoring

### `ParticipantModel`
- `answeredSlides[]` — list of slide IDs already answered; used client-side and server-side to block duplicates
- `score` — incremented atomically via `FieldValue.increment()` in Firestore
- `streak` — tracked for display in leaderboard

### `ResponseModel`
- Immutable once written — no updates allowed by Firestore rules
- `isCorrect` + `pointsEarned` are computed client-side before submission
- `responseTimeMs` — time since slide appeared; used for speed bonus calculation

---

## 6. Folder Structure

```
lib/
├── main.dart              Firebase init, orientation lock, ProviderScope
├── app.dart               MaterialApp.router, theme switching
├── firebase_options.dart  Auto-generated platform config

├── core/
│   ├── constants/         AppColors (palette, mcqColors array, dark/light tokens)
│   ├── extensions/        BuildContext shortcuts (textPrimary, bgCard, showErrorSnackBar…)
│   ├── providers/         themeNotifierProvider (dark/light toggle)
│   ├── router/            app_router.dart — all GoRoute definitions + auth guard
│   ├── theme/             AppTheme.lightTheme / darkTheme (Material 3)
│   └── utils/             IdGenerator.generateSessionCode()

├── features/
│   ├── auth/
│   │   ├── data/datasources/  firebase_auth_datasource.dart — signUp, signIn, signOut
│   │   ├── data/models/       (user model)
│   │   ├── domain/entities/   AuthUser, UserRole
│   │   ├── domain/providers/  auth_provider.dart — authStateProvider, AuthNotifier
│   │   └── presentation/
│   │       ├── host_auth_screen.dart         Sign in / sign up form
│   │       ├── host_dashboard_screen.dart    Post-login host home
│   │       ├── participant_entry_screen.dart  Code entry + QR option
│   │       ├── participant_name_screen.dart   Name + avatar picker
│   │       └── qr_scanner_screen.dart         Camera QR scanner

│   ├── home/
│   │   └── presentation/
│   │       ├── session_history_screen.dart        List of past sessions
│   │       └── session_history_view_screen.dart   Results of a past session

│   └── session/
│       ├── data/datasources/  firestore_datasource.dart — all Firestore CRUD + streams
│       ├── data/models/       session_model, slide_model, participant_model, response_model
│       ├── domain/providers/  session_provider.dart
│       │                         sessionStreamProvider (family)
│       │                         slidesStreamProvider (family)
│       │                         participantsStreamProvider (family)
│       │                         responsesStreamProvider (family)
│       │                         SessionController (AsyncNotifier)
│       │                         ParticipantController (AsyncNotifier)
│       │                         ResponseController (AsyncNotifier)
│       │                         SessionFinishNotifier (atomic end + confirmation)
│       └── presentation/
│           ├── host/
│           │   ├── create_session_screen.dart
│           │   ├── host_dashboard_screen.dart   (session control panel)
│           │   ├── live_results_screen.dart      real-time charts + response feed
│           │   └── slide_editor_screen.dart      full slide editor
│           ├── participant/
│           │   ├── join_session_screen.dart
│           │   ├── waiting_room_screen.dart
│           │   ├── answer_screen.dart            MCQ, text, word cloud UI + timer
│           │   └── participant_results_screen.dart
│           └── shared/
│               └── session_final_dashboard.dart  unified leaderboard (host + participant)

└── shared/widgets/
    ├── animated_gradient_bg.dart
    ├── glass_card.dart
    └── pulse_button.dart
```

---

## 7. Key Logic

### Session Lifecycle

```
[waiting] ──startSession()──→ [live] ──endSession()──→ [ended]
```

- State changes are written to Firestore and propagated via `watchSession()` stream to all connected clients simultaneously.
- The `SessionFinishNotifier` introduces a confirmation step: after writing `ended`, it awaits the stream to confirm the update before navigating the host, ensuring all participants receive the change first.

### Quiz Flow (per slide)

1. Host navigates to slide → Firestore updates `currentSlideId`
2. All participant `AnswerScreen`s receive the update via `slidesStreamProvider`
3. `_onSlideChanged()` resets answer state for each participant
4. Host starts timer → `timerActive = true` in Firestore
5. Participants see countdown (client-side `Timer.periodic`, sync'd to `timerSeconds`)
6. Participant submits answer → `ResponseController.submitResponse()`
   - Firestore transaction prevents duplicate submissions
   - Points calculated: `50 + 50 * speedRatio` (for correct MCQ), `10` (for open text / word cloud)
   - Partial MCQ credit: `(50 + 50 * speedRatio) / 2`
7. Host sees real-time response feed via `responsesStreamProvider`
8. Host navigates to next slide → cycle repeats

### Scoring Formula (MCQ)
```
speedRatio = 1 - (responseTimeMs / (timeLimit * 1000))
pointsEarned = round(50 + 50 * clamp(speedRatio, 0, 1))   // 50–100 points
```
For partial multiple-choice: `pointsEarned / 2`  
For open text / word cloud: flat `10` participation points

### Firestore Security Rules Summary

| Collection | Read | Write |
|---|---|---|
| `sessions` | Auth required | Create: auth + hostId = uid; Update/Delete: hostId = uid |
| `sessions/*/slides` | Auth required | Auth + hostId = uid only |
| `sessions/*/participants` | Auth required | Create/Update/Delete: **unauthenticated** (participants are anonymous) |
| `sessions/*/responses` | Host only (hostId = uid) | **Unauthenticated** (participants submit anonymously) |

---

## 8. Notable Design Decisions

- **Participants are anonymous** — no Firebase Auth required. They write directly to Firestore using unauthenticated rules.
- **Timer is host-controlled, client-rendered** — `timerActive` is a boolean flag in Firestore. Participants start a `Timer.periodic` locally when they receive `timerActive = true`. This avoids Firestore write costs per tick.
- **Duplicate response guard** — both a client-side pre-check (`hasParticipantResponded`) and a Firestore transaction inside `submitResponse()` prevent double submissions.
- **Session code** — 6-character alphanumeric, generated with `uuid`-seeded randomness. Looked up via `where('code', isEqualTo: ...)`.
- **Template sessions** — a session can be duplicated (slides copied) to create a new session from an existing one.
