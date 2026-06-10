# Shmuki Talk — Firestore Database Design

## Collections Overview

```
/users/{userId}
/rooms/{roomId}
/rooms/{roomId}/members/{userId}
/rooms/{roomId}/queue/{queueDocId}
/rooms/{roomId}/webrtc_sessions/{sessionId}
/rooms/{roomId}/webrtc_sessions/{sessionId}/candidates/{candidateId}
/analytics/events
```

---

## /users/{userId}

Stores user profile data. Created automatically on first Google sign-in.

```json
{
  "uid": "string",
  "displayName": "string",
  "email": "string",
  "photoURL": "string | null",
  "createdAt": "Timestamp",
  "lastSeen": "Timestamp",
  "fcmTokens": ["string"],
  "status": "online | offline | busy | speaking | in_queue",
  "currentRoomId": "string | null",
  "isListenerOnly": "boolean",
  "rooms": ["roomId1", "roomId2"]
}
```

**Indexes:** uid (default), lastSeen (for offline detection)

---

## /rooms/{roomId}

Room document. roomId is auto-generated.

```json
{
  "id": "string",
  "name": "string",
  "emoji": "string",
  "imageURL": "string | null",
  "inviteCode": "string (e.g. FAMILY7)",
  "ownerId": "string",
  "isLocked": "boolean",
  "currentSpeakerId": "string | null",
  "currentSpeakerName": "string | null",
  "currentSpeakerPhotoURL": "string | null",
  "speakerStartedAt": "Timestamp | null",
  "participantCount": "number",
  "listenerCount": "number",
  "queueCount": "number",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

**Indexes:** inviteCode (for join by code lookup)

---

## /rooms/{roomId}/members/{userId}

Room membership sub-collection.

```json
{
  "userId": "string",
  "displayName": "string",
  "photoURL": "string | null",
  "role": "owner | admin | member",
  "isMuted": "boolean",
  "isListenerOnly": "boolean",
  "status": "online | offline | busy | speaking | in_queue",
  "joinedAt": "Timestamp",
  "lastSeen": "Timestamp"
}
```

---

## /rooms/{roomId}/queue/{queueDocId}

Speaking queue. Documents ordered by priority DESC, joinedAt ASC.

```json
{
  "id": "string",
  "userId": "string",
  "displayName": "string",
  "photoURL": "string | null",
  "priority": "number (0=normal, 10=admin_priority)",
  "joinedAt": "Timestamp",
  "position": "number"
}
```

**Indexes:** priority DESC, joinedAt ASC (composite)

---

## /rooms/{roomId}/webrtc_sessions/{sessionId}

WebRTC signaling data. Ephemeral — cleaned up when session ends.

```json
{
  "sessionId": "string",
  "speakerId": "string",
  "offer": {
    "type": "string",
    "sdp": "string"
  },
  "answer": {
    "type": "string",
    "sdp": "string"
  },
  "state": "pending | active | ended",
  "createdAt": "Timestamp"
}
```

Sub-collection:
```
/candidates/{candidateId}
{
  "sdpMid": "string",
  "sdpMLineIndex": "number",
  "candidate": "string",
  "isLocal": "boolean"
}
```

---

## /analytics/events (anonymous)

Anonymous usage events. No user PII.

```json
{
  "eventType": "room_session | ptt_event | participant_count",
  "roomId": "string (hashed)",
  "value": "number",
  "timestamp": "Timestamp"
}
```

---

## Firestore Security Rules

See SECURITY_RULES.md

---

## Indexes Required

```json
[
  {
    "collectionGroup": "rooms",
    "queryScope": "COLLECTION",
    "fields": [
      {"fieldPath": "inviteCode", "order": "ASCENDING"}
    ]
  },
  {
    "collectionGroup": "queue",
    "queryScope": "COLLECTION",
    "fields": [
      {"fieldPath": "priority", "order": "DESCENDING"},
      {"fieldPath": "joinedAt", "order": "ASCENDING"}
    ]
  },
  {
    "collectionGroup": "members",
    "queryScope": "COLLECTION",
    "fields": [
      {"fieldPath": "status", "order": "ASCENDING"},
      {"fieldPath": "lastSeen", "order": "DESCENDING"}
    ]
  }
]
```
