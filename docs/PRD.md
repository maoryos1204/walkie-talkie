# Shmuki Talk — Product Requirements Document

## 1. Product Overview

**Name:** Shmuki Talk  
**Version:** 1.0.0  
**Type:** Real-time private walkie-talkie platform  
**Target Audience:** Families and friend groups  
**Primary Language:** Hebrew (RTL)

### Vision
A modern digital walkie-talkie experience that feels instant and natural. Not a chat app — a voice communication platform where pressing a button lets you speak to your people in real time.

---

## 2. Goals & Non-Goals

### Goals
- Sub-500ms audio delivery latency
- Support 50 simultaneous participants per room
- Private rooms only (no discovery)
- Zero voice storage (real-time only)
- Battery-efficient background operation
- Cross-platform: iOS, Android, Web, Tablet

### Non-Goals
- Text messaging
- Video calls
- Public/discoverable rooms
- Voice recording or playback
- File sharing

---

## 3. User Stories

### Authentication
- As a user, I can sign in with my Google account in one tap
- As a user, my profile (name, photo) is populated automatically
- As a user, I stay signed in across app restarts

### Rooms
- As a user, I can create a private room with a custom name and emoji
- As a user, I can join a room using a short invite code (e.g., FAMILY7)
- As a user, I can share a room invite via WhatsApp or copy link
- As a user, I can belong to multiple rooms simultaneously
- As a user, I can quickly switch between my rooms
- As a room owner, I can add/remove members, mute users, and lock the room
- As a room owner, I can transfer ownership before leaving
- As a room admin, I can get priority queue position for speaking

### Walkie-Talkie
- As a user, I press and hold the PTT button to speak
- As a user, I hear other speakers immediately when they start talking
- As a user, if the channel is busy, I see "CHANNEL BUSY" and can join the queue
- As a user, I feel a vibration and see a visual indicator when someone starts speaking
- As a user, I can join as "Listener Only" to save battery
- As a user, accidental presses under 300ms are ignored

### Presence
- As a user, I see who is Online, Offline, Busy, In Queue, or Speaking
- As a user, I see the current speaker with animated audio waves
- As a user, I see the total listener count and participant count

### Notifications
- As a user, I receive a notification when someone starts speaking (if app is in background)
- As a user, I receive a notification when I'm next in queue
- As a user, I receive a notification when the room is locked/unlocked
- As a user, I'm asked once for microphone and notification permissions

---

## 4. Functional Requirements

### FR-AUTH-001: Google Sign-In
- Single Google OAuth sign-in flow
- Auto-create Firestore user profile on first login
- Profile includes: uid, displayName, email, photoURL, createdAt, lastSeen

### FR-ROOM-001: Room Creation
- Room name (2-20 chars)
- Room emoji/icon selector
- Optional room image (upload to Firebase Storage)
- Auto-generated invite code (6-8 chars, e.g., FAMILY7)
- Creator becomes owner automatically

### FR-ROOM-002: Room Joining
- Join by invite code
- Join by deep link (shmukitalk://room/FAMILY7)
- Join by WhatsApp-shared link

### FR-ROOM-003: Room Management
- Owner: remove user, mute user, promote to admin, lock room, transfer ownership
- Admin: mute user, priority queue
- Member: leave room, toggle listener-only mode

### FR-PTT-001: Push-To-Talk
- Minimum press duration: 300ms (anti-accidental)
- Only 1 active speaker at a time
- Queue for waiting speakers
- Admin priority queue bump
- Visual: animated waveform around speaking avatar
- Haptic: vibration on transmission start
- Audio: speakerphone, echo cancellation, noise suppression, AGC

### FR-PRESENCE-001: User Presence
- Statuses: ONLINE, OFFLINE, BUSY, IN_QUEUE, SPEAKING
- Heartbeat every 30 seconds
- Offline after 90 seconds without heartbeat
- Real-time Firestore subscription

### FR-NOTIF-001: Push Notifications
- FCM for Android and iOS
- Web Push for browser
- Events: transmission started, queue position, room locked, new member joined

---

## 5. Non-Functional Requirements

### Performance
- App cold start: < 2 seconds
- PTT activation: < 100ms local
- Audio delivery: < 500ms end-to-end
- Presence update: < 2 seconds

### Reliability
- Graceful degradation on poor network
- Automatic WebRTC reconnection
- Queue state persisted in Firestore (survives disconnects)

### Security
- All Firestore data protected by Security Rules
- Room membership required for all room operations
- No server-side voice processing or storage
- Firebase App Check for API abuse prevention

### Scalability
- Room: up to 50 concurrent users (mesh WebRTC up to 10, SFU beyond)
- Firestore: designed for horizontal scaling
- No stateful backend required

### Battery
- Listener mode: audio receive only (no microphone activation)
- Presence heartbeat: debounced, 30s interval
- Background: FCM wakeup only (no persistent socket)

---

## 6. UI/UX Requirements

### Design System
- Modern, clean, family-friendly
- Primary: Deep Blue (#1A237E) with warm accents
- RTL layout by default (Hebrew)
- Dark mode support

### Screen Flow
1. Splash → Login (if unauthenticated)
2. Login → Home
3. Home → Room (tap room card)
4. Room → Settings (tap gear icon)
5. Any screen → deep link room join

### Accessibility
- Minimum touch target: 48x48dp
- High contrast text
- Screen reader labels on all interactive elements

---

## 7. Analytics (Privacy-Compliant)

Collect only:
- Daily active rooms (count)
- Session duration (per room visit)
- PTT event count (per session)
- Participant count snapshots

Never collect:
- Voice content
- User identity linked to events
- Location data
