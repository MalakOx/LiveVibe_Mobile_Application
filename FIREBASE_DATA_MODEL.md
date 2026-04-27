# Modèle de Données Firebase - LivePulse

**Date** : Avril 2026 | **Version** : 1.0

---

## Vue d'ensemble

**Firestore** est une base de données NoSQL temps réel avec synchronisation automatique.

**Concepts clés** :
- **Collection** : Ensemble de documents
- **Document** : Entité JSON avec ID unique
- **Subcollection** : Collection imbriquée sous un document
- **Streams** : Écoute automatique des changements

---

## Structure Firestore

```
/users/{uid}
  └─ email, displayName, role, createdAt

/sessions/{sessionId}
  ├─ title, hostId, code, status, currentSlideId
  ├─ timerSeconds, timerActive, createdAt
  │
  ├─ /slides/{slideId}
  │  ├─ question, type, order, options
  │  ├─ correctOptionIndices, answerMode
  │  ├─ points, timeLimit, imageUrl
  │  │
  │  └─ /responses/{responseId}
  │     ├─ participantId, participantName
  │     ├─ value, isCorrect, pointsEarned
  │     └─ responseTimeMs, submittedAt
  │
  └─ /participants/{participantId}
     ├─ name, avatar, score, rank
     ├─ streak, joinedAt, isOnline
     └─ answeredSlides (array)

---

## Modèles clés

### 1. UserModel

**Rôle** : Utilisateurs enregistrés (hôtes)

**Schéma** :
```dart
final String uid;            // Firebase Auth ID
final String email;
final String displayName;
final String role;           // "host" ou "participant"
final DateTime createdAt;
```

**Exemple JSON** :
```json
{
  "email": "prof@uni.fr",
  "displayName": "Prof Martin",
  "role": "host",
  "createdAt": {"_seconds": 1609459200}
}
```

---

### 2. SessionModel

**Rôle** : Représente une session complète

**Schéma** :
```dart
final String id;
final String title;
final String hostId;
final String code;           // 6 caractères
final String status;         // "waiting" | "live" | "ended"
final String? currentSlideId;
final int timerSeconds;
final bool timerActive;
final DateTime createdAt;
final DateTime? startedAt;
final DateTime? endedAt;
```

**Exemple JSON** :
```json
{
  "title": "Quiz Dart",
  "hostId": "user-12345",
  "code": "ABC123",
  "status": "live",
  "currentSlideId": "slide-q3",
  "timerSeconds": 15,
  "timerActive": true,
  "createdAt": {"_seconds": 1712000000}
}
```

**Opérations** :
```dart
// Créer
db.collection('sessions').add({...})

// Récupérer par code
db.collection('sessions')
  .where('code', isEqualTo: 'ABC123')
  .limit(1).get()

// Écouter temps réel
db.collection('sessions').doc(sessionId).snapshots()

// Démarrer
db.collection('sessions').doc(sessionId).update({
  'status': 'live',
  'startedAt': FieldValue.serverTimestamp()
})
```

---

### 3. SlideModel

**Rôle** : Questions/diapositives

**Emplacement** : `/sessions/{sessionId}/slides/{slideId}`

**Schéma** :
```dart
final String id;
final String type;           // "mcq" | "openText" | "wordCloud"
final int order;
final String question;
final List<String> options;
final List<int> correctOptionIndices;
final String answerMode;     // "single" | "multiple"
final int points;
final int timeLimit;
```

**Exemple JSON** :
```json
{
  "type": "mcq",
  "order": 1,
  "question": "Qu'est-ce que Dart?",
  "options": ["Langage", "Framework", "Package"],
  "correctOptionIndices": [0],
  "answerMode": "single",
  "points": 100,
  "timeLimit": 30
}
```

---

### 4. ResponseModel

**Rôle** : Réponses des participants

**Emplacement** : `/sessions/{id}/slides/{id}/responses/{responseId}`

**Schéma** :
```dart
final String participantId;
final String participantName;
final String value;          // Réponse
final bool? isCorrect;
final int pointsEarned;
final int responseTimeMs;
final DateTime submittedAt;
```

**Exemple JSON** :
```json
{
  "participantId": "p-alice",
  "participantName": "Alice",
  "value": "0",
  "isCorrect": true,
  "pointsEarned": 92,
  "responseTimeMs": 8000,
  "submittedAt": {"_seconds": 1712001050}
}
```

**Opérations** :
```dart
// Vérifier pas déjà répondu
db.collection('sessions').doc(sessionId)
  .collection('slides').doc(slideId)
  .collection('responses')
  .where('participantId', isEqualTo: pid)
  .limit(1).get()

// Soumettre
db.collection('sessions').doc(sessionId)
  .collection('slides').doc(slideId)
  .collection('responses')
  .add({...})

// Écouter (top 50)
db.collection('sessions').doc(sessionId)
  .collection('slides').doc(slideId)
  .collection('responses')
  .limit(50).snapshots()
```

---

### 5. ParticipantModel

**Rôle** : Score et classement

**Emplacement** : `/sessions/{sessionId}/participants/{participantId}`

**Schéma** :
```dart
final String name;
final String avatar;         // Emoji
final int score;
final int rank;
final int streak;
final DateTime joinedAt;
final bool isOnline;
final List<String> answeredSlides;
```

**Exemple JSON** :
```json
{
  "name": "Alice",
  "avatar": "😀",
  "score": 285,
  "rank": 1,
  "joinedAt": {"_seconds": 1712001000},
  "answeredSlides": ["slide-q1", "slide-q2"]
}
```

**Opérations** :
```dart
// Créer
db.collection('sessions').doc(sessionId)
  .collection('participants').doc(pid).set({...})

// Classement (top 50)
db.collection('sessions').doc(sessionId)
  .collection('participants')
  .orderBy('score', descending: true)
  .limit(50).get()

// Écouter
db.collection('sessions').doc(sessionId)
  .collection('participants')
  .orderBy('score', descending: true)
  .limit(50).snapshots()

// Mettre à jour score
db.collection('sessions').doc(sessionId)
  .collection('participants').doc(pid).update({
    'score': FieldValue.increment(points),
    'answeredSlides': FieldValue.arrayUnion([slideId])
  })
```

---

## Indices Firestore

```
participants
└─ score (Descending)

slides
└─ order (Ascending)

responses
├─ participantId (Ascending)
└─ submittedAt (Descending)
```

---

## Pagination

**Limites appliquées** :
- Participants : Top 50 par score
- Réponses : Top 50 par timestamp
- Diapositives : Toutes (< 100)

**Pourquoi 50?** : 50 docs × 500 bytes = 25 KB (mémoire stable)

---

## Flux complet : Participant répond

```
1. Rejoint session
   └─ Crée participants/{pid}

2. Répond à question
   ├─ ScoringService calcule points
   └─ Crée responses/{rid}

3. Score mis à jour
   ├─ participants/{pid}.score += pointsEarned
   └─ participants/{pid}.answeredSlides += slideId

4. Classement re-trié (index Firestore)

5. Host/Participant voient mise à jour via streams
```

---

**Fin de la documentation Firestore**

Consulter [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) pour implémentation.

  "participantName": "Alice",
  "type": "mcq",
  "value": "0",
  "selectedOptionIndex": 0,
  "isCorrect": true,
  "pointsEarned": 92,
  "responseTimeMs": 8000,
  "submittedAt": {"_seconds": 1712001050, "_nanoseconds": 0}
}
```

**Exemple JSON - MCQ réponses multiples partiellement correcte** :

```json
{
  "id": "resp-u2s2-1234567891",
  "sessionId": "session-abc123xyz",
  "slideId": "slide-q2",
  "participantId": "participant-bob",
  "participantName": "Bob",
  "type": "mcq",
  "value": "[0, 2]",
  "selectedOptionIndex": null,
  "isCorrect": false,
  "pointsEarned": 25,
  "responseTimeMs": 12000,
  "submittedAt": {"_seconds": 1712001150, "_nanoseconds": 0}
}
```

**Exemple JSON - Texte ouvert** :

```json
{
  "id": "resp-u3s3-1234567892",
  "sessionId": "session-abc123xyz",
  "slideId": "slide-q3",
  "participantId": "participant-charlie",
  "participantName": "Charlie",
  "type": "openText",
  "value": "Une closure est une fonction qui a accès aux variables de sa portée parente",
  "selectedOptionIndex": null,
  "isCorrect": null,
  "pointsEarned": 0,
  "responseTimeMs": 30000,
  "submittedAt": {"_seconds": 1712001250, "_nanoseconds": 0}
}
```

**Exemple JSON - Nuage de mots** :

```json
{
  "id": "resp-u1s4-1234567893",
  "sessionId": "session-abc123xyz",
  "slideId": "slide-q4",
  "participantId": "participant-alice",
  "participantName": "Alice",
  "type": "wordCloud",
  "value": "Incroyable",
  "selectedOptionIndex": null,
  "isCorrect": null,
  "pointsEarned": 50,
  "responseTimeMs": 5000,
  "submittedAt": {"_seconds": 1712001300, "_nanoseconds": 0}
}
```

**Opérations principales** :

```dart
// 1. Soumettre réponse MCQ
await _db
    .collection('sessions')
    .doc(sessionId)
    .collection('slides')
    .doc(slideId)
    .collection('responses')
    .add({
      'participantId': participantId,
      'participantName': participantName,
      'type': 'mcq',
      'value': selectedOptionIndex.toString(),
      'selectedOptionIndex': selectedOptionIndex,
      'isCorrect': isCorrect,
      'pointsEarned': points,
      'responseTimeMs': responseDuration.inMilliseconds,
      'submittedAt': FieldValue.serverTimestamp()
    });

// 2. Vérifier déjà répondu
QuerySnapshot existing = await _db
    .collection('sessions')
    .doc(sessionId)
    .collection('slides')
    .doc(slideId)
    .collection('responses')
    .where('participantId', isEqualTo: participantId)
    .limit(1)
    .get();

if (existing.docs.isNotEmpty) {
  throw Exception('Déjà répondu');
}

// 3. Écouter réponses en temps réel (top 50)
Stream<List<ResponseModel>> watchResponses(
  String sessionId,
  String slideId
) {
  return _db
      .collection('sessions')
      .doc(sessionId)
      .collection('slides')
      .doc(slideId)
      .collection('responses')
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ResponseModel.fromFirestore(doc))
          .toList());
}

// 4. Compter réponses par option
QuerySnapshot mcqResponses = await _db
    .collection('sessions')
    .doc(sessionId)
    .collection('slides')
    .doc(slideId)
    .collection('responses')
    .where('type', isEqualTo: 'mcq')
    .get();

// Compter manuellement (Firestore n'a pas d'agrégation native)
Map<String, int> counts = {};
for (var doc in mcqResponses.docs) {
  final option = doc['value'];
  counts[option] = (counts[option] ?? 0) + 1;
}
```

**Calcul des points (ScoringService)** :

```dart
int calculatePoints({
  required bool isCorrect,
  required bool isPartial,
  required int responseTimeMs,
  required int timeLimitSeconds,
}) {
  const basePoints = 50;
  const bonusPoints = 50;
  
  if (!isCorrect) return 0;  // Faux = 0 points
  
  // Vitesse : 0ms = 50 points bonus, timeLimitSeconds = 0 bonus
  final speedRatio = 1.0 - (responseTimeMs / (timeLimitSeconds * 1000));
  final speedBonus = bonusPoints * speedRatio.clamp(0.0, 1.0);
  
  // Réponse partielle = 50%
  final totalPoints = basePoints + speedBonus;
  return (isPartial ? totalPoints / 2 : totalPoints).round();
}
```

**Formule détaillée** :

```
Points = Base + SpeedBonus
Base = 50 (réponse correcte) ou 0 (incorrect)
SpeedBonus = 50 × (1 - TempsEcoulé / TempsMaximum)

Exemples :
├─ Correcte en 5s (30s limit)   : 50 + 50×(1-5/30) = 50 + 41.67 ≈ 92 points
├─ Correcte en 15s (30s limit)  : 50 + 50×(1-15/30) = 50 + 25 = 75 points
├─ Correcte en 29.9s (30s limit): 50 + 50×(1-29.9/30) ≈ 50 + 0.17 ≈ 50 points
├─ Partielle correcte en 5s     : (50 + 41.67) / 2 ≈ 46 points
└─ Incorrect                    : 0 points
```

**Index Firestore requis** :
```
Collection : sessions/slides/responses
Composite index :
├─ participantId (Ascending)
└─ submittedAt (Descending)

Pour requête : WHERE participantId = 'p1' ORDER BY submittedAt DESC
```

---

### 5. ParticipantModel (Subcollection: sessions/{id}/participants/)

**Rôle** : Tracker le score et classement des participants en temps réel

**Emplacement Firestore** :
```
/sessions/{sessionId}/participants/{participantId}
```

**Schéma complet** :

```dart
class ParticipantModel {
  final String id;                      // Firestore doc ID
  final String sessionId;               // Session parent
  final String name;                    // Nom affichage
  final String avatar;                  // Emoji unique
  final int score;                      // Points totaux
  final int rank;                       // Classement (1, 2, 3...)
  final int streak;                     // Réponses correctes consécutives
  final DateTime joinedAt;              // Timestamp inscription
  final bool isOnline;                  // Connecté?
  final List<String> answeredSlides;    // IDs slides répondues
}
```

**Exemple JSON** :

```json
{
  "id": "participant-alice",
  "sessionId": "session-abc123xyz",
  "name": "Alice",
  "avatar": "😀",
  "score": 285,
  "rank": 1,
  "streak": 3,
  "joinedAt": {"_seconds": 1712001000, "_nanoseconds": 0},
  "isOnline": true,
  "answeredSlides": ["slide-q1", "slide-q2", "slide-q3"]
}
```

**Opérations principales** :

```dart
// 1. Créer participant
await _db
    .collection('sessions')
    .doc(sessionId)
    .collection('participants')
    .doc(participantId)
    .set({
      'name': participantName,
      'avatar': generateAvatar(),
      'score': 0,
      'rank': 0,
      'streak': 0,
      'joinedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'answeredSlides': []
    });

// 2. Récupérer classement (top 50)
QuerySnapshot leaderboard = await _db
    .collection('sessions')
    .doc(sessionId)
    .collection('participants')
    .orderBy('score', descending: true)
    .limit(50)
    .get();

// 3. Écouter classement en temps réel
Stream<List<ParticipantModel>> watchParticipants(String sessionId) {
  return _db
      .collection('sessions')
      .doc(sessionId)
      .collection('participants')
      .orderBy('score', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ParticipantModel.fromFirestore(doc))
          .toList());
}

// 4. Mettre à jour score (après réponse)
await _db
    .collection('sessions')
    .doc(sessionId)
    .collection('participants')
    .doc(participantId)
    .update({
      'score': FieldValue.increment(pointsEarned),
      'answeredSlides': FieldValue.arrayUnion([slideId]),
      'streak': isCorrect ? FieldValue.increment(1) : 0
    });

// 5. Marquer participant déconnecté
await _db
    .collection('sessions')
    .doc(sessionId)
    .collection('participants')
    .doc(participantId)
    .update({
      'isOnline': false
    });
```

**Index Firestore requis** :
```
Collection : sessions/participants
Simple index :
└─ score (Descending)

Pour requête : ORDER BY score DESC LIMIT 50
```

---

## Relations entre entités

### Diagramme de relations

```
┌─────────────┐
│   users     │
└──────┬──────┘
       │ hostId
       │
       ▼
┌─────────────────────────────────────┐
│        sessions                     │
├─────────────────────────────────────┤
│ • code (recherche participants)     │
│ • status (waiting → live → ended)   │
│ • currentSlideId (question actuelle)│
└─┬────────────────────────────────┬──┘
  │                                 │
  │ sessionId                       │ sessionId
  │                                 │
  ▼                                 ▼
┌──────────────────┐      ┌──────────────────────┐
│  slides/         │      │  participants/       │
│  (questions)     │      │  (classement)        │
└─┬────────────────┘      └──────────────────────┘
  │ slideId
  │
  ▼
┌──────────────────┐
│  responses/      │
│  (answers)       │──────────┐
└──────────────────┘          │
                               │
                        participantId
                               │
                        (dénormalisation)
```

### Flux de données entre collections

#### Scénario: Participant répond à question

```
1. Participant rejoint session
   └─ Crée document sessions/{sessionId}/participants/{participantId}

2. Participant sélectionne une option
   └─ Calcul ScoringService

3. Participant soumet réponse
   └─ Crée sessions/{sessionId}/slides/{slideId}/responses/{responseId}
      ├─ value: "0"
      ├─ isCorrect: true
      ├─ pointsEarned: 92
      └─ participantId: "participant-alice" (référence à participants)

4. Participant score mis à jour
   └─ Met à jour sessions/{sessionId}/participants/{participantId}
      ├─ score: +92
      ├─ answeredSlides: + slideId
      └─ streak: +1

5. Classement mis à jour
   └─ Firestore re-trie automatiquement par score
      (grâce à index sur 'score' descending)

6. Host voit mise à jour
   └─ watchParticipants() émet nouvelle liste
   └─ watchResponses() émet nouvelle réponse
```

### Dénormalisation intentionnelle

**Pourquoi?** Firestore n'a pas de JOINs. Il faut dénormaliser.

```
Response document contient :
├─ participantId (référence)
└─ participantName: "Alice" (dénormalisée)

Avantage :
├─ Pas besoin de lire séparé participants doc
├─ Affichage plus rapide
└─ Réponse autonome

Inconvénient :
└─ Si participant change nom, responses pas mis à jour
   Mais : c'est acceptable car c'est historique
```

### Requêtes multi-collections

**Exemple: Statistiques globales d'une session**

```dart
// Firestore N'a PAS de JOIN natif, donc faire en Dart
Future<SessionStats> getSessionStats(String sessionId) async {
  // 1. Récupérer session
  final sessionDoc = await _db
      .collection('sessions')
      .doc(sessionId)
      .get();
  final session = SessionModel.fromFirestore(sessionDoc);

  // 2. Récupérer participants
  final participantsSnap = await _db
      .collection('sessions')
      .doc(sessionId)
      .collection('participants')
      .get();
  final participants = participantsSnap.docs
      .map(ParticipantModel.fromFirestore)
      .toList();

  // 3. Récupérer toutes réponses
  final slidesSnap = await _db
      .collection('sessions')
      .doc(sessionId)
      .collection('slides')
      .get();
  
  int totalResponses = 0;
  for (final slideDoc in slidesSnap.docs) {
    final responsesSnap = await slideDoc.reference
        .collection('responses')
        .get();
    totalResponses += responsesSnap.size;
  }

  // 4. Calculer statistiques
  return SessionStats(
    totalParticipants: participants.length,
    totalResponses: totalResponses,
    averageScore: participants.isEmpty 
        ? 0 
        : participants.map((p) => p.score).reduce((a, b) => a + b) ~/ 
            participants.length,
    winner: participants.isNotEmpty ? participants.first : null,
  );
}
```

---

## Comportement temps réel

### Streams Firestore

#### Pattern 1: Écouter document unique

```dart
// Écouter changements session
Stream<SessionModel> watchSession(String sessionId) {
  return _db
      .collection('sessions')
      .doc(sessionId)
      .snapshots()  // ← Retourne stream
      .map((snapshot) {
        if (!snapshot.exists) {
          throw Exception('Session supprimée');
        }
        return SessionModel.fromFirestore(snapshot);
      });
}

// Utilisation (UI)
final sessionAsync = ref.watch(sessionStreamProvider('session-123'));
sessionAsync.when(
  data: (session) {
    // Rebuilds automatiquement quand session change
    return Text('Status: ${session.status}');
  },
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Erreur: $e'),
);
```

**Flux en temps réel** :

```
Moment 1: Hôte crée session
    ├─ Firestore doc créé
    └─ Stream émet SessionModel(status: waiting)
    └─ UI affiche "En attente"

Moment 2: Hôte démarre session (30 secondes plus tard)
    ├─ Firestore doc mis à jour (status: live)
    └─ Stream émet SessionModel(status: live) ← NOTIFICATION AUTOMATIQUE
    └─ UI affiche "En direct"

Moment 3: Hôte termine session (10 minutes plus tard)
    ├─ Firestore doc mis à jour (status: ended)
    └─ Stream émet SessionModel(status: ended) ← NOTIFICATION AUTOMATIQUE
    └─ UI affiche "Terminée"
```

#### Pattern 2: Écouter collection avec limite

```dart
// Écouter réponses (les 50 premières)
Stream<List<ResponseModel>> watchResponses(
  String sessionId,
  String slideId
) {
  return _db
      .collection('sessions')
      .doc(sessionId)
      .collection('slides')
      .doc(slideId)
      .collection('responses')
      .limit(50)  // ← Pagination
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map(ResponseModel.fromFirestore)
          .toList());
}

// Utilisation
final responsesAsync = ref.watch(
  responsesStreamProvider((sessionId: 'abc', slideId: 'q1'))
);

responsesAsync.when(
  data: (responses) {
    // Rebuilds à chaque nouvelle réponse soumise
    return BarChart(data: responses);
  },
  loading: () => CircularProgressIndicator(),
);
```

**Exemple timeline** :

```
T=0s  : Hôte lance question
        └─ Stream émet []  (0 réponses)
        └─ Graphique vide

T=2s  : 1er participant répond
        └─ Firestore ajoute ResponseModel
        └─ Stream émet [Response1]
        └─ Graphique se met à jour

T=5s  : 10 participants ont répondu
        └─ Stream émet [Response1...Response10]
        └─ Graphique montre distribution

T=10s : Hôte passe question suivante
        └─ Participants ne voient plus cette question
        └─ Stream peut être annulé
```

### Limite de 50 documents

**Pourquoi 50?**

```
Memoire : 1 ResponseModel ≈ 500 bytes
          50 documents × 500 bytes = 25 KB ✓ (acceptable)
          
          1000 documents × 500 bytes = 500 KB ✗ (trop)
          5000 documents × 500 bytes = 2.5 MB ✗ (beaucoup)

Rendering: 50 widgets ✓ (rapide)
           1000 widgets ✗ (laggy)
```

**Future: Load more pattern**

```dart
// Pour sessions massives (500+ participants)
class ResponsesPaginationNotifier extends AsyncNotifier<List<ResponseModel>> {
  int _pageSize = 50;

  Future<void> loadMore() async {
    _pageSize += 50;
    await build();
  }

  @override
  Future<List<ResponseModel>> build() async {
    final snap = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('slides')
        .doc(slideId)
        .collection('responses')
        .limit(_pageSize)  // Grandit dynamiquement
        .get();
    
    return snap.docs.map(ResponseModel.fromFirestore).toList();
  }
}
```

---

## Scénarios d'utilisation

### Scénario 1: Créer une session complète

**Actions**:
1. Hôte se connecte → Document users créé
2. Hôte crée session → Document sessions créé
3. Hôte ajoute 3 questions → 3 documents slides créés
4. Hôte lance session → sessions.doc mis à jour (status='live')

**État Firestore après** :

```
/users/{uid}
  ├─ email, role, createdAt, ...

/sessions/{sessionId}
  ├─ title: "Quiz Dart"
  ├─ status: "live"
  ├─ currentSlideId: "slide-q1"
  │
  ├─ slides/
  │  ├─ slide-q1
  │  │  ├─ question: "Qu'est-ce que Dart?"
  │  │  ├─ options: [...]
  │  │  └─ responses/  (vide pour l'instant)
  │  │
  │  ├─ slide-q2
  │  │  └─ ...
  │  │
  │  └─ slide-q3
  │     └─ ...
  │
  └─ participants/  (vide)
```

**Requêtes Firestore utilisées** :

```dart
// 1. Créer session
await db.collection('sessions').add({
  'title': 'Quiz Dart',
  'hostId': uid,
  'status': 'waiting',
  ...
});  // Retourne DocumentReference avec ID auto-généré

// 2. Ajouter slides
for (final slideData in slidesData) {
  await db
      .collection('sessions')
      .doc(sessionId)
      .collection('slides')
      .add(slideData);
}

// 3. Démarrer session
await db
    .collection('sessions')
    .doc(sessionId)
    .update({
      'status': 'live',
      'currentSlideId': 'slide-q1',
      'startedAt': Timestamp.now()
    });
```

### Scénario 2: Participant rejoint et répond

**Actions**:
1. Participant entre code → Firestore cherche session par code
2. Participant rentre nom → Crée document participant
3. Participant attend → Écoute sessionStreamProvider pour status='live'
4. Participant voit question → Affiche question actuelle
5. Participant répond → Crée document response + met à jour participant score

**État Firestore après réponse** :

```
/sessions/{sessionId}
  ├─ slides/
  │  ├─ slide-q1
  │  │  └─ responses/
  │  │     ├─ {responseId1}
  │  │     │  ├─ participantId: "p-alice"
  │  │     │  ├─ value: "0"
  │  │     │  ├─ isCorrect: true
  │  │     │  ├─ pointsEarned: 92
  │  │     │  └─ submittedAt: Timestamp
  │  │     │
  │  │     ├─ {responseId2}
  │  │     │  └─ (réponse Bob)
  │  │     │
  │  │     └─ {responseId3}
  │  │        └─ (réponse Charlie)
  │  │
  │  └─ slide-q2
  │     └─ responses/  (vide)
  │
  └─ participants/
     ├─ {p-alice}
     │  ├─ name: "Alice"
     │  ├─ score: 92
     │  ├─ rank: 1  (sera recalculé)
     │  └─ answeredSlides: ["slide-q1"]
     │
     ├─ {p-bob}
     │  ├─ name: "Bob"
     │  ├─ score: 75
     │  ├─ rank: 2
     │  └─ answeredSlides: ["slide-q1"]
     │
     └─ {p-charlie}
        ├─ name: "Charlie"
        ├─ score: 0  (réponse fausse)
        ├─ rank: 3
        └─ answeredSlides: ["slide-q1"]
```

**Requêtes utilisées** :

```dart
// 1. Chercher session par code
final sessionSnap = await db
    .collection('sessions')
    .where('code', isEqualTo: 'ABC123')
    .limit(1)
    .get();

// 2. Créer participant
await db
    .collection('sessions')
    .doc(sessionId)
    .collection('participants')
    .doc(participantId)
    .set({
      'name': 'Alice',
      'avatar': '😀',
      'score': 0,
      ...
    });

// 3. Vérifier pas déjà répondu
final existing = await db
    .collection('sessions')
    .doc(sessionId)
    .collection('slides')
    .doc(slideId)
    .collection('responses')
    .where('participantId', isEqualTo: participantId)
    .limit(1)
    .get();

if (existing.docs.isNotEmpty) {
  throw Exception('Déjà répondu');
}

// 4. Soumettre réponse
await db
    .collection('sessions')
    .doc(sessionId)
    .collection('slides')
    .doc(slideId)
    .collection('responses')
    .add({
      'participantId': participantId,
      'value': '0',
      'isCorrect': true,
      'pointsEarned': 92,
      'submittedAt': Timestamp.now()
    });

// 5. Mettre à jour score participant
await db
    .collection('sessions')
    .doc(sessionId)
    .collection('participants')
    .doc(participantId)
    .update({
      'score': FieldValue.increment(92),
      'answeredSlides': FieldValue.arrayUnion(['slide-q1'])
    });
```

### Scénario 3: Hôte voit résultats en temps réel

**Actions**:
1. Hôte ouvre live_results_screen
2. Écoute participantsStreamProvider → Voir classement top 50
3. Écoute responsesStreamProvider → Voir réponses à question actuelle
4. Graphique se met à jour automatiquement

**Streams observés** :

```dart
// 1. Classement en temps réel
final participants = ref.watch(
  participantsStreamProvider('session-abc')
);

// 2. Réponses actuelles
final responses = ref.watch(
  responsesStreamProvider((
    sessionId: 'session-abc',
    slideId: 'slide-q1'
  ))
);

// Timeline d'événements
T=0s  : Hôte affiche results screen
        ├─ participantsStreamProvider émet []
        ├─ responsesStreamProvider émet []
        └─ Écrans vides

T=5s  : 15 participants ont rejoint
        └─ participantsStreamProvider émet [15 participants]
        └─ Classement affiche 15 lignes

T=20s : Participants commencent à répondre
        └─ responsesStreamProvider émet [5 réponses]
        └─ Graphique commence à apparaître

T=25s : Tous 15 participants ont répondu
        └─ responsesStreamProvider émet [15 réponses]
        └─ Graphique montre distribution complète
        └─ Classement mis à jour avec scores
```

---

## Optimisations Firestore

### Bonnes pratiques implémentées

#### 1. Indexation

**Index simple (sur 1 champ)** - Créés automatiquement :
```
Collection participants
Index sur 'score' (descending)
Raison : ORDER BY score DESC
```

**Index composé (sur 2+ champs)** - À créer manuellement :
```
Collection responses
Index composé :
├─ participantId (ascending)
└─ submittedAt (descending)
Raison : WHERE participantId = ? ORDER BY submittedAt DESC
```

#### 2. Pagination

```dart
// ❌ Incorrect (OOM crash)
.snapshots()  // Charge tous documents

// ✅ Correct
.limit(50)
.snapshots()  // Charge max 50
```

**Estimations** :
```
Participants : limit(50)
    50 participants × 300 bytes = 15 KB ✓

Responses : limit(50)
    50 responses × 400 bytes = 20 KB ✓

Sans limits :
    1000 participants = 300 KB ✗
    5000 responses = 2 MB ✗
```

#### 3. Dénormalisation stratégique

```json
// ✗ Incorrect: Référence seulement
{
  "participantId": "p-1",
  // Doit lire séparé: participants/{p-1}
}

// ✓ Correct: Dénormalisée
{
  "participantId": "p-1",
  "participantName": "Alice",  // Dénormalisée
  // Pas besoin de lire séparé
}
```

#### 4. Timestamps côté serveur

```dart
// ❌ Incorrect: Timestamp client
'createdAt': DateTime.now()  // Peut être manipulé

// ✅ Correct: Timestamp serveur
'createdAt': FieldValue.serverTimestamp()  // Immuable côté serveur
```

#### 5. Opérations atomiques

```dart
// ✗ Non-atomique: 2 écritures séparées
await db.collection('responses').doc(id).set(response);
await db.collection('participants').doc(pid).update({'score': ...});
// Risk: Crash entre les deux

// ✓ Atomique: WriteBatch
final batch = db.batch();
batch.set(db.collection('responses').doc(id), response);
batch.update(db.collection('participants').doc(pid), {'score': ...});
await batch.commit();
// Tout ou rien
```

### Limites Firestore connues

| Limite | Valeur | Impact |
|--------|--------|--------|
| Taille doc max | 1 MB | Grande liste de réponses |
| Écrits/sec par doc | 1/sec | Participation massive |
| Lecture doc max | 1 million/jour | Free tier dépassé |
| Résultats query | 25 MB | Batch imports |

**Mitigation pour LivePulse** :
```
Taille docs : OK, max 5KB par response
Écrits/sec : OK, limité à 50 participants
Lectures/jour : OK avec limit(50)
```

### Règles de sécurité (Security Rules)

**Template** :

```
match /databases/{database}/documents {
  // Users: Chacun peut lire sa propre doc
  match /users/{userId} {
    allow read: if request.auth.uid == userId;
    allow write: if request.auth.uid == userId;
  }
  
  // Sessions: Hôte peut modifier, tous peuvent lire active
  match /sessions/{sessionId} {
    allow read: if resource.data.status in ['waiting', 'live'];
    allow create: if request.auth.uid != null;
    allow update, delete: if resource.data.hostId == request.auth.uid;
    
    // Slides: Lecture simple
    match /slides/{slideId} {
      allow read: if parent.status in ['waiting', 'live'];
      allow write: if parent.hostId == request.auth.uid;
    }
    
    // Responses: Créer si participant, lire si hôte
    match /slides/{slideId}/responses/{responseId} {
      allow create: if request.auth != null;
      allow read: if parent.parent.hostId == request.auth.uid;
    }
    
    // Participants: Créer et lire
    match /participants/{participantId} {
      allow create, read: if request.auth != null;
    }
  }
}
```

---

## Résumé

### Collections principales

| Collection | Documents | Subcollections | Usage |
|-----------|-----------|-----------------|-------|
| `users/` | Utilisateurs enregistrés | Aucune | Profils hôtes |
| `sessions/` | Sessions complètes | slides, participants | Core entities |
| `slides/` | Questions | responses | Définitions Q |
| `responses/` | Réponses participants | Aucune | Historique réponses |
| `participants/` | Classement live | Aucune | Leaderboard |

### Flux de données

```
1. Authentification
   └─ Firebase Auth + users/ collection

2. Session
   └─ Hôte crée sessions/{id}

3. Questions
   └─ Hôte ajoute sessions/{id}/slides/{id}

4. Participants
   └─ Rejoignent et crée sessions/{id}/participants/{id}

5. Réponses
   └─ Soumettent sessions/{id}/slides/{id}/responses/{id}

6. Score
   └─ Met à jour sessions/{id}/participants/{id}

7. Synchronisation
   └─ Streams notifient tous les listeners
```

### Points clés

✅ **Pagination** : limit(50) évite OOM  
✅ **Dénormalisation** : participantName dans responses  
✅ **Timestamps serveur** : serverTimestamp() immuable  
✅ **Streams** : Real-time sync sans polling  
✅ **Indexes** : Créés pour requêtes fréquentes  
✅ **Atomicité** : WriteBatch pour multi-docs  

---

**Fin de la documentation Firebase**

Pour flux d'architecture complet, consulter PROJECT_DOCUMENTATION.md
