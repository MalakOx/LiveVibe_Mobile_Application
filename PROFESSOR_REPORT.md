# LivePulse — Academic Project Report

**Module:** Mobile Application Development  
**Level:** 2nd Year Engineering — Semester 2  
**Institution:** ISI Ariana  
**Technology:** Flutter + Firebase

---

## 1. Project Overview

**LivePulse** is a mobile application that enables real-time interactive presentations. A host (e.g., a teacher or presenter) creates a quiz session and controls its content live. Participants join from their smartphones, answer questions in real-time, and compete on a live leaderboard.

The application targets two distinct user roles: a **Host** who manages the session, and **Participants** who join and interact without needing an account.

---

## 2. Objectives

- Design and implement a real-time mobile application using Flutter
- Apply a clean, scalable software architecture
- Integrate cloud-based backend services (Firebase)
- Handle two separate user flows within the same application
- Implement real-time synchronization across multiple connected devices

---

## 3. Technologies Used

| Technology | Role |
|---|---|
| **Flutter** (Dart ≥ 3.3) | Cross-platform mobile UI framework |
| **Firebase Authentication** | Secure host login (email/password) |
| **Cloud Firestore** | Real-time NoSQL database |
| **Riverpod 2** | Reactive state management |
| **go_router** | Declarative navigation and route guarding |
| **qr_flutter / mobile_scanner** | QR code generation and scanning |
| **flutter_animate / lottie** | Animations and transitions |
| **google_fonts** | Typography (Outfit font family) |

---

## 4. Architecture

The application follows a **feature-first Clean Architecture**:

```
Presentation Layer   ←→   Domain Layer (Providers)   ←→   Data Layer (Firebase)
    (UI Screens)              (Business Logic)              (Firestore, Auth)
```

Each feature (`auth`, `session`, `home`) is organized into three independent layers:

- **Data layer** — handles all Firebase calls and model serialization
- **Domain layer** — contains business logic through Riverpod `AsyncNotifier` controllers
- **Presentation layer** — Flutter screens that react to state changes

This separation ensures testability, maintainability, and clear responsibility boundaries.

---

## 5. Main Features

### Host Features
- Secure registration and login via Firebase Authentication
- Create a quiz session with a unique 6-character join code
- Slide editor supporting three question types:
  - **MCQ** (Multiple Choice — single or multiple correct answers)
  - **Open Text** (free-form written responses)
  - **Word Cloud** (keyword-style responses)
- Generate a QR code for easy participant joining
- Control session in real-time: navigate between slides, start/stop a countdown timer
- View live results and response statistics per slide
- Access session history and replay past results
- Reuse a past session as a template for a new one

### Participant Features
- Join a session by entering a code or scanning a QR code — **no account required**
- Choose a display name and an emoji avatar
- Wait in a lobby until the host starts the session
- Answer questions in real-time with a visible countdown timer
- Receive immediate feedback on correctness after submission
- Speed-based scoring: faster correct answers earn more points
- View a ranked leaderboard at the end of the session

---

## 6. Firebase Data Model

Data is organized in Firestore as a hierarchical structure:

```
sessions/
  └── {sessionId}
        ├── slides/        (question content)
        ├── participants/  (joined users and scores)
        └── responses/     (submitted answers)
```

**Security** is enforced at the database level through Firestore Rules:
- Only authenticated hosts can create or modify sessions and slides
- Participants (unauthenticated) can only write their own responses
- Responses can only be read by the session's host

---

## 7. Real-Time Synchronization

The core technical challenge of the project is ensuring all devices stay synchronized during a live session. This is achieved through **Firestore real-time streams**:

- Session status (`waiting → live → ended`) is streamed to all participants simultaneously
- When the host navigates to the next slide, all participant screens update instantly
- When the host starts the timer, all participants receive the signal and display a synchronized local countdown
- The leaderboard updates in real-time as responses are submitted

---

## 8. Conclusion

LivePulse demonstrates the practical application of modern mobile development principles: reactive architecture, cloud integration, real-time communication, and role-based access control. The project successfully implements a complete, functional interactive quiz platform with a clean codebase and a polished user interface, supporting both anonymous participants and authenticated hosts on a shared, live data layer.
