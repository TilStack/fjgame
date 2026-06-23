# Phase 6 — Multijoueur en ligne Firebase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implémenter le multijoueur en ligne via Firebase Firestore sans Cloud Functions, avec validation client-side via GameEngine existant.

**Architecture:** Firestore comme backend temps réel; l'hôte résout les moves car il a accès local à l'état complet; les streams Riverpod propagent l'état aux autres joueurs. Mode hors ligne local reste intact.

**Tech Stack:** Flutter 3.22+, Dart 3.4+, Riverpod, Firebase Firestore ^5.2.0, GoRouter, flutter_animate

## Global Constraints

1. `flutter analyze` doit retourner zéro issue après chaque tâche
2. Zéro string hardcodée — tout via AppLocalizations
3. Toutes les StreamSubscription doivent être cancel dans dispose
4. Ne jamais modifier GameEngine ni les modèles existants: Famille, Personnage, Descripteur, GameState
5. Chaque nouveau fichier commence par un commentaire d'en-tête en français
6. Documenter avec TODO Phase 3 Cloud Functions partout où validation serveur sera ajoutée
7. Le mode local doit continuer à fonctionner sans régression
8. cloud_firestore: ^5.2.0 ajouté dans pubspec.yaml

---

### Task 1 (Part A): Modèles de domaine en ligne + pubspec

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/domain/models/online_room.dart`

**Interfaces:**
- Consumes: `cloud_firestore` (Timestamp, DocumentSnapshot)
- Produces:
  - `enum RoomStatus { waiting, playing, finished }`
  - `class OnlinePlayer { uid, pseudo, avatarColor, isReady, isHost; factory fromMap(Map); Map toMap(); }`
  - `class OnlineRoom { roomId, roomCode, status, hostId, playerIds, players, maxPlayers, createdAt, updatedAt; factory fromFirestore(DocumentSnapshot); Map toMap(); }`
  - `class OnlineGameState { currentPlayerIndex, etape, completedFamilies, lastAction, scores, updatedAt; factory fromFirestore(DocumentSnapshot); Map toMap(); }`

- [ ] Ajouter `cloud_firestore: ^5.2.0` dans pubspec.yaml sous dependencies
- [ ] Créer `lib/domain/models/online_room.dart` avec les 3 classes + enum
- [ ] `flutter pub get`
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 2 (Part B): OnlineGameRepository

**Files:**
- Create: `lib/data/remote/online_game_repository.dart`

**Interfaces:**
- Consumes: `OnlinePlayer`, `OnlineRoom`, `OnlineGameState` de Task 1; `GameEngine` existant; `Famille`, `Personnage` existants
- Produces: `class OnlineGameRepository` avec méthodes:
  - `Future<String> createRoom(int maxPlayers)`
  - `Future<String> joinRoom(String roomCode)`
  - `Future<void> leaveRoom(String roomId)`
  - `Future<void> setReady(String roomId, bool isReady)`
  - `Future<void> startGame(String roomId, List<Famille> familles)`
  - `Future<void> submitMove(String roomId, String targetId, String familyId, String descripteurId)`
  - `Stream<OnlineRoom?> roomStream(String roomId)`
  - `Stream<OnlineGameState?> gameStateStream(String roomId)`
  - `Stream<List<String>> myHandStream(String roomId)`

**Contexte submitMove:** Le joueur courant ne peut pas lire les mains des autres. submitMove écrit `lastAction` avec `success: null` (move en attente). L'hôte détecte via stream et exécute la résolution complète. Documenter TODO Phase 3 Cloud Functions.

- [ ] Créer `lib/data/remote/online_game_repository.dart`
- [ ] Générer code de room: 6 chars alphanumériques majuscules aléatoires, vérifier unicité Firestore
- [ ] createRoom: créer document avec tous les champs requis + FieldValue.serverTimestamp()
- [ ] joinRoom: chercher par roomCode, vérifier status=waiting et !plein, arrayUnion
- [ ] leaveRoom: retirer joueur, transférer hostId si hôte, supprimer si vide
- [ ] setReady: mettre à jour isReady dans tableau players
- [ ] startGame: hôte seulement, GameEngine.initGame, écrire game/state et hands/uid, status=playing
- [ ] submitMove: écrire lastAction avec success=null (TODO Phase 3)
- [ ] Streams: snapshots Firestore → modèles null-safe
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 3 (Part C): Providers Riverpod en ligne

**Files:**
- Create: `lib/application/providers/online_game_provider.dart`

**Interfaces:**
- Consumes: `OnlineGameRepository` (Task 2), `OnlineRoom`, `OnlineGameState` (Task 1), `FamilleRepositoryImpl` existant
- Produces:
  - `enum OnlineEtape { idle, creating, joining, waiting, myTurn, watchingOtherTurn, showingResult, gameOver }`
  - `class OnlineGameNotifierState { room, gameState, myHand, familles, etape, isLoading, erreur, lastActionResult, roomId }`
  - `@riverpod class OnlineGameNotifier extends _$OnlineGameNotifier` avec toutes les méthodes

**Logique streams:** 
- `etape terminee` → `gameOver`
- `currentPlayerIndex` correspond à index dans `playerIds` → `myTurn`; sinon `watchingOtherTurn`
- `lastAction.success != null` → `showingResult` pendant 2500ms puis retour
- Cancel toutes StreamSubscriptions dans dispose

- [ ] Créer le fichier avec enum et classe d'état
- [ ] build(): charger familles via FamilleRepositoryImpl, retourner état initial idle
- [ ] createRoom, joinRoom: s'abonner aux streams, passer en waiting
- [ ] setReady, startGame, submitMove, leaveRoom
- [ ] Logique de mise à jour d'état depuis streams
- [ ] Cancel StreamSubscriptions proprement
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 4 (Part D): OnlineLobbyScreen

**Files:**
- Create: `lib/presentation/screens/game/online_lobby_screen.dart`
- Route: `/lobby-online`

**Interfaces:**
- Consumes: `OnlineGameNotifier` (Task 3), `AppLocalizations` (clés Task 11), `PrimaryButton` existant, `AppTextField` existant
- Produces: `class OnlineLobbyScreen extends ConsumerStatefulWidget`

**Layout:**
- AppBar titre "Jouer en ligne" + bouton retour
- Corps: icône Icons.wifi 48px + fadeIn, titre Cinzel 22px, sous-titre Inter 12px
- Section gauche Créer: SegmentedButton 3-6 joueurs init 4, PrimaryButton filled "Créer" → createRoom → navigate /room/:roomId
- Section droite Rejoindre: AppTextField 6 chars MAJUSCULES, PrimaryButton outlined "Rejoindre" → joinRoom → navigate /room/:roomId
- CircularProgressIndicator si isLoading
- SnackBar error si erreur != null

- [ ] Créer l'écran avec layout deux colonnes
- [ ] SegmentedButton (ou Slider) 3 à 6 joueurs
- [ ] AppTextField avec textCapitalization: characters, maxLength: 6
- [ ] Gestion isLoading et erreur
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 5 (Part E): WaitingRoomScreen

**Files:**
- Create: `lib/presentation/screens/game/waiting_room_screen.dart`
- Route: `/room/:roomId`

**Interfaces:**
- Consumes: `OnlineGameNotifier` (Task 3), `AppLocalizations`
- Produces: `class WaitingRoomScreen extends ConsumerStatefulWidget` recevant roomId

**Layout:**
- PopScope canPop: false
- AppBar "Salle d'attente" + icône quitter (leaveRoom → /home)
- Section haute: CODE DE LA PARTIE + roomCode Cinzel Bold 32px letterSpacing 8 + bouton copier
- Liste joueurs: ListTile avec avatar circulaire coloré, pseudo, badge Hôte, icône isReady
- Stagger fadeIn+slideX 80ms par index
- Chip "nouveau joueur" 500ms quand players.length augmente
- Bas: bouton Je suis prêt (non-hôte) + bouton Démarrer (hôte, désactivé si <3 joueurs ou pas tous prêts)
- Texte "Minimum 3 joueurs" ou "X joueurs prêts sur Y"

- [ ] Créer l'écran avec toutes les sections
- [ ] Détecter augmentation players.length pour chip animation
- [ ] Logique boutons hôte/non-hôte
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 6 (Part F): OnlineTransitionScreen

**Files:**
- Create: `lib/presentation/screens/game/online_transition_screen.dart`
- Route: `/game-online/transition`

**Interfaces:**
- Consumes: `OnlineGameNotifier` (Task 3)
- Produces: `class OnlineTransitionScreen extends ConsumerStatefulWidget`

**Layout:**
- PopScope canPop: false
- Si joueur actif === moi: "C'est ton tour" + PrimaryButton "Je suis prêt" → /game-online/play
- Sinon: "C'est le tour de {pseudo}" + CircularProgressIndicator
- Écoute stream: navigate automatiquement vers /game-online/play quand etape devient en_cours

- [ ] Créer l'écran avec logique myTurn/watchingOtherTurn
- [ ] Navigation automatique sur changement etape
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 7 (Part G): OnlineGameScreen

**Files:**
- Create: `lib/presentation/screens/game/online_game_screen.dart`
- Route: `/game-online/play`

**Interfaces:**
- Consumes: `OnlineGameNotifier` (Task 3), `PlayerHandGridWidget` existant, `AppLocalizations`
- Produces: `class OnlineGameScreen extends ConsumerStatefulWidget`

**Layout:**
- myTurn: interface complète identique GameScreen local (PlayerHandGridWidget, famille, descripteur, cible) + bouton "Demander" → submitMove
- watchingOtherTurn: mode spectateur — nom joueur actif + avatar, dernière action texte, scores liste
- showingResult: overlay non-bloquant 2500ms puis disparaît
- gameOver: navigate /game-online/fin
- BottomSheet scores: scores de tous via gameState.scores
- PopScope canPop: false

- [ ] Créer l'écran avec les 3 modes
- [ ] Overlay showingResult avec auto-dismiss 2500ms
- [ ] Navigation gameOver
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 8 (Part H): FinPartieOnlineScreen

**Files:**
- Create: `lib/presentation/screens/game/fin_partie_online_screen.dart`
- Route: `/game-online/fin`

**Interfaces:**
- Consumes: `OnlineGameNotifier` (Task 3), `AppLocalizations`
- Produces: `class FinPartieOnlineScreen extends ConsumerStatefulWidget`

**Layout:** Identique à FinPartieScreen local mais données depuis gameState.scores et room.players
- Classement avec stagger 150ms * rank
- Bouton Rejouer: leaveRoom → reinitialiser → /lobby-online
- Bouton Accueil: leaveRoom → /home

- [ ] Créer l'écran
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 9 (Part I+J): HomeScreen update + Router

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart`
- Modify: `lib/core/router/app_router.dart`

**Interfaces:**
- Consumes: tous les nouveaux écrans (Tasks 4-8), `OnlineGameNotifier` (Task 3)

**HomeScreen:** Activer bouton "Jouer en ligne" → /lobby-online, retirer badge BIENTÔT et opacity 0.6

**Router:** Ajouter routes avec gardes auth:
- `/lobby-online` → `OnlineLobbyScreen` (auth requise sinon /login)
- `/room/:roomId` → `WaitingRoomScreen` (auth + room non null sinon /lobby-online)
- `/game-online/transition` → `OnlineTransitionScreen` (auth + gameState non null sinon /lobby-online)
- `/game-online/play` → `OnlineGameScreen` (auth + gameState + etape myTurn ou watchingOtherTurn sinon /game-online/transition)
- `/game-online/fin` → `FinPartieOnlineScreen` (auth + etape gameOver sinon /lobby-online)

- [ ] Modifier HomeScreen
- [ ] Ajouter les 5 routes dans app_router.dart
- [ ] `flutter analyze` — zéro issue
- [ ] Commit

---

### Task 10 (Part K): Clés i18n

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`

**Clés à ajouter (fr/en):**
- `onlineSubtitle`: "Jouez avec vos amis où que vous soyez" / "Play with your friends wherever you are"
- `createRoomHint`: "Créez une salle et partagez le code" / "Create a room and share the code"
- `joinRoomHint`: "Entrez le code reçu par un ami" / "Enter the code received from a friend"
- `roomCode`: "Code de la partie" / "Room code"
- `copyCode`: "Copier le code" / "Copy code"
- `codeCopied`: "Code copié" / "Code copied"
- `waitingForPlayers`: "En attente de joueurs" / "Waiting for players"
- `allReady`: "Tous prêts" / "All ready"
- `startGame`: "Démarrer la partie" / "Start game"
- `waitingForHost`: "En attente de l'hôte" / "Waiting for host"
- `otherPlayerTurn`: "C'est le tour de {name}" / "It's {name}'s turn" (avec @otherPlayerTurn placeholders name: String)
- `yourTurnOnline`: "C'est ton tour" / "It's your turn"
- `spectatorMode`: "Mode spectateur" / "Spectator mode"
- `lastAction`: "Dernière action" / "Last action"
- `submitMove`: "Demander" / "Ask"
- `roomFull`: "Cette salle est complète" / "This room is full"
- `roomNotFound`: "Code invalide ou salle introuvable" / "Invalid code or room not found"
- `gameAlreadyStarted`: "Cette partie a déjà commencé" / "This game has already started"
- `leaveRoom`: "Quitter la salle" / "Leave room"
- `leaveConfirm`: "Voulez-vous vraiment quitter la partie ?" / "Do you really want to leave the game?"

- [ ] Ajouter toutes les clés dans app_fr.arb
- [ ] Ajouter toutes les clés dans app_en.arb (avec @otherPlayerTurn placeholder)
- [ ] `flutter gen-l10n` ou vérifier que le build génère les fichiers
- [ ] `flutter analyze` — zéro issue
- [ ] Commit
