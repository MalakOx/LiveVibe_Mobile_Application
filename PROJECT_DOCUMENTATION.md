# Documentation Technique - LivePulse

**Date** : Avril 2026 | **Version** : 1.0

---

## Vue d'ensemble

**LivePulse** est une plateforme de présentation interactive permettant la participation en temps réel.

**Cas d'usage** : Salles de classe, conférences, formations, quiz compétitifs avec classement en direct.

### Fonctionnalités principales

**Hôte (Animateur)** :
- Créer sessions et diapositives
- Lancer des questions en direct avec minuteur
- Voir statistiques et classement en temps réel
- Types de questions : QCM (unique/multiple), texte ouvert, nuage de mots

**Participant** :
- Rejoindre par code ou QR
- Répondre en temps réel
- Retour instantané (✓/✗ + points)
- Voir classement en direct

### Système de notation
- Réponse correcte : 50 points
- Bonus vitesse : +0-50 points (selon rapidité)
- Réponse partielle : 50% des points
- Formule : Points = 50 + 50 × (1 - TempsÉcoulé/TempsMax)

---

## Stack technologique

| Composant | Technologie | Utilité |
|-----------|-------------|---------|
| **Frontend** | Flutter 3.3.0+ | Multi-plateforme (iOS, Android, Web) |
| **Langage** | Dart 3.3.0+ | Programmation application |
| **Gestion d'état** | Riverpod 2.5.1 | Reactive, déclaratif, sans code gen |
| **Base de données** | Firestore 5.4.4 | NoSQL temps réel, synchronisation live |
| **Auth** | Firebase Auth 5.3.1 | Email/password, anonyme |
| **Navigation** | GoRouter 14.2.7 | Déclarative, deep linking |
| **UI** | Material Design 3 | Composants modernes |

**Types de providers Riverpod** :
- `Provider<T>` : Valeurs calculées simples
- `StreamProvider<T>` : Données temps réel (Firestore streams)
- `AsyncNotifierProvider` : Opérations async (create, update)

---

## Architecture du projet

```
lib/
├── core/                    # Utilitaires globaux
│   ├── constants/          # Couleurs, dimensions, constantes
│   ├── error/              # Gestion centralisée erreurs
│   ├── extensions/         # Helpers BuildContext
│   ├── providers/          # Providers globaux
│   ├── router/             # GoRouter config
│   ├── theme/              # Material Design 3
│   └── utils/              # ID generators, avatars
│
├── features/               # Fonctionnalités métier
│   ├── auth/              # Authentification
│   ├── home/              # Tableau de bord
│   ├── session/           # Cœur : sessions + questions
│   └── slides/            # Résultats et visualisations
│
└── shared/                # Widgets réutilisables
    └── widgets/           # Cartes, boutons, conteneurs
```

---

## Flux de données

### Participant répond à une question

```
1. Sélection réponse (answer_screen.dart)
   ↓
2. Calcul points (ScoringService)
   ↓
3. Envoi à Firestore (ResponseController)
   ↓
4. Mise à jour score participant
   ↓
5. Notification via Streams
   ↓
6. UI se met à jour (live_results_screen)
```

### Host voit résultats en temps réel

**live_results_screen écoute** :
- `participantsStreamProvider` → Classement top 50
- `responsesStreamProvider` → Réponses question actuelle
- Mise à jour automatique à chaque nouvelle réponse

---

## Guide de démarrage

### Prérequis
```bash
- Flutter SDK 3.3.0+
- Dart SDK 3.3.0+
- Compte Firebase
- Android Studio / Xcode / VS Code
```

### Installation

**1. Cloner et dépendances**
```bash
git clone <repository-url>
cd livepulse_v2
flutter pub get
flutter pub run build_runner build
```

**2. Configuration Firebase**
```bash
npm install -g firebase-tools
firebase login
flutterfire configure
# Sélectionner votre projet Firebase
```

**3. Activer authentification anonyme**
```
Firebase Console → Authentication
→ Sign-in method → Activer "Anonymous"
```

### Lancer l'application
```bash
# Mode développement
flutter run

# Spécifier une plateforme
flutter run -d chrome           # Web
flutter run -d emulator-5554    # Android
flutter run -d iPhone           # iOS

# Mode production
flutter run --release
```

### Commandes essentielles
```bash
flutter analyze              # Lint
dart format lib/             # Format
flutter test                 # Tests
flutter clean && pub get     # Nettoyer
```

---

## Modèles clés

### SessionModel
```dart
final String id;
final String title;
final String hostId;
final String code;           // Code 6 caractères
final String status;         // waiting | live | ended
final String? currentSlideId;
final int timerSeconds;
final bool timerActive;
```

### SlideModel
```dart
final String id;
final String question;
final List<String> options;
final List<int> correctOptionIndices;
final String answerMode;     // single | multiple
final int timeLimit;
```

### ResponseModel
```dart
final String participantId;
final String value;          // Réponse
final bool? isCorrect;
final int pointsEarned;
final int responseTimeMs;
```

### ParticipantModel
```dart
final String name;
final String avatar;         // Emoji
final int score;
final int rank;
final DateTime joinedAt;
```

---

## Concepts importants

✅ **Architecture** : Clean architecture avec 3 couches  
✅ **État** : Riverpod avec Streams pour synchronisation temps réel  
✅ **BD** : Firestore avec subcollections et pagination (50 items max)  
✅ **Notation** : Service dédié testable et centralisé  
✅ **Performance** : Streams Firestore pour mises à jour instantanées  

---

**Fin de la documentation**

