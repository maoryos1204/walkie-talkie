# Shmuki Talk — System Architecture

## 1. Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                        CLIENT (Flutter)                       │
│                                                              │
│  ┌─────────┐  ┌──────────┐  ┌────────────┐  ┌───────────┐  │
│  │  Auth   │  │  Rooms   │  │  Walkie    │  │ Presence  │  │
│  │ Feature │  │ Feature  │  │  Talkie    │  │ Feature   │  │
│  └────┬────┘  └────┬─────┘  └─────┬──────┘  └─────┬─────┘  │
│       │            │              │                │         │
│  ┌────▼────────────▼──────────────▼────────────────▼─────┐  │
│  │               Riverpod State Management                │  │
│  └────────────────────────┬───────────────────────────────┘  │
│                           │                                   │
│  ┌────────────────────────▼───────────────────────────────┐  │
│  │                  Data Layer (Repositories)              │  │
│  └──┬───────────────┬────────────────┬────────────────────┘  │
│     │               │                │                        │
└─────┼───────────────┼────────────────┼────────────────────────┘
      │               │                │
      ▼               ▼                ▼
┌──────────┐   ┌──────────────┐  ┌──────────────────┐
│ Firebase │   │   Firestore  │  │   WebRTC (P2P)   │
│   Auth   │   │  (Realtime   │  │  Signaling via   │
│          │   │   + Presence │  │   Firestore      │
└──────────┘   │   + Rooms)   │  └──────────────────┘
               └──────────────┘
                      │
               ┌──────▼───────┐
               │     FCM      │
               │ (Background  │
               │Notifications)│
               └──────────────┘
```

## 2. Clean Architecture Layers

```
Domain Layer (Pure Dart)
├── Entities (AppUser, Room, RoomMember, UserPresence)
├── Repository interfaces
└── Use Cases (business logic)

Data Layer
├── Firebase datasources (Auth, Firestore, FCM)
├── Models (JSON serialization via freezed)
└── Repository implementations

Presentation Layer
├── Riverpod providers
├── Pages (GoRouter)
└── Widgets
```

## 3. Feature Modules

### auth/
Handles Google Sign-In, session management, user profile creation

### home/
My rooms list, create room, join room, room cards

### room/
Room details, member management, settings, invite sharing

### walkie_talkie/
PTT button, WebRTC audio streaming, speaking queue, voice animation

### presence/
Real-time user status tracking via Firestore

### notifications/
FCM token management, notification display and routing

### analytics/
Anonymous event tracking via Firebase Analytics

## 4. WebRTC Architecture

For rooms up to 10 users: Full Mesh P2P via flutter_webrtc
For rooms 10-50 users: Selective Forwarding Unit (SFU) via LiveKit/mediasoup (Phase 2)

### Signaling via Firestore
```
rooms/{roomId}/webrtc_sessions/{sessionId}
├── offer: RTCSessionDescription
├── answer: RTCSessionDescription
├── candidates/{candidateId}: RTCIceCandidate
└── speakerId: String
```

### Audio Pipeline
Microphone → AGC → Echo Cancel → Noise Suppress → Opus Codec → WebRTC → Peers

## 5. Presence System

```
users/{userId}/presence
├── status: 'online' | 'offline' | 'busy' | 'speaking' | 'in_queue'
├── lastSeen: Timestamp
├── currentRoom: String?
└── isListenerOnly: bool
```

Heartbeat: every 30s via periodic timer
Offline detection: server-side Cloud Function triggers if lastSeen > 90s

## 6. Queue Management

```
rooms/{roomId}/queue/{position}
├── userId: String
├── displayName: String
├── photoURL: String
├── joinedAt: Timestamp
├── isAdmin: bool
└── priority: int (higher = earlier in queue)
```

Queue operations are Firestore transactions to prevent race conditions.
When the current speaker releases PTT, a Cloud Function moves the next queued user to `currentSpeaker`.

## 7. Data Flow — PTT Button Press

1. User presses PTT (> 300ms threshold)
2. App checks if `rooms/{roomId}.currentSpeakerId` is empty
3. If empty → Firestore transaction sets currentSpeakerId = userId
4. WebRTC: start sending audio stream to all room peers
5. Other clients receive Firestore snapshot update → start receiving audio
6. Presence: update status to 'speaking'
7. FCM: Cloud Function sends notification to background users
8. User releases PTT → clear currentSpeakerId → next in queue activated

## 8. Database Collections

See DATABASE.md for full Firestore schema.

## 9. Security Model

- All Firestore rules require authentication
- Room operations require room membership
- Admin operations require admin or owner role
- WebRTC sessions scoped to room membership

## 10. Deployment Architecture

```
GitHub → GitHub Actions CI/CD
├── Flutter Build (Android APK/AAB, iOS IPA, Web)
├── Firebase Hosting (Web)
├── Google Play (Android)
└── App Store (iOS)
```
