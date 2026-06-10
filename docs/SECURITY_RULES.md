# Shmuki Talk — Firestore Security Rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helper Functions ──────────────────────────────────────────────────────

    function isAuthenticated() {
      return request.auth != null;
    }

    function isCurrentUser(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isRoomMember(roomId) {
      return isAuthenticated() &&
        exists(/databases/$(database)/documents/rooms/$(roomId)/members/$(request.auth.uid));
    }

    function getRoomMember(roomId) {
      return get(/databases/$(database)/documents/rooms/$(roomId)/members/$(request.auth.uid));
    }

    function isRoomAdmin(roomId) {
      return isRoomMember(roomId) &&
        getRoomMember(roomId).data.role in ['admin', 'owner'];
    }

    function isRoomOwner(roomId) {
      return isRoomMember(roomId) &&
        getRoomMember(roomId).data.role == 'owner';
    }

    function isRoomLocked(roomId) {
      return get(/databases/$(database)/documents/rooms/$(roomId)).data.isLocked == true;
    }

    function validUserFields() {
      return request.resource.data.keys().hasAll(['uid', 'displayName', 'email', 'createdAt'])
        && request.resource.data.uid == request.auth.uid;
    }

    // ── Users ─────────────────────────────────────────────────────────────────

    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isCurrentUser(userId) && validUserFields();
      allow update: if isCurrentUser(userId);
      allow delete: if false; // Soft delete only
    }

    // ── Rooms ─────────────────────────────────────────────────────────────────

    match /rooms/{roomId} {
      allow read: if isRoomMember(roomId);

      allow create: if isAuthenticated()
        && request.resource.data.ownerId == request.auth.uid
        && request.resource.data.name.size() >= 2
        && request.resource.data.name.size() <= 20
        && request.resource.data.inviteCode.size() >= 6
        && request.resource.data.inviteCode.size() <= 8;

      allow update: if isRoomAdmin(roomId)
        && !('ownerId' in request.resource.data.diff(resource.data).affectedKeys());

      allow update: if isRoomOwner(roomId); // Owner can change anything

      allow delete: if isRoomOwner(roomId);

      // ── Room Members ───────────────────────────────────────────────────────

      match /members/{memberId} {
        allow read: if isRoomMember(roomId);

        // Join room (if not locked)
        allow create: if isAuthenticated()
          && memberId == request.auth.uid
          && !isRoomLocked(roomId);

        // Update own presence/status
        allow update: if isCurrentUser(memberId)
          && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'lastSeen', 'isListenerOnly']);

        // Admin can mute/update role
        allow update: if isRoomAdmin(roomId)
          && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['isMuted', 'role', 'status']);

        // Owner can do anything to member doc
        allow update: if isRoomOwner(roomId);

        // Leave room (own doc only) or admin remove
        allow delete: if isCurrentUser(memberId) || isRoomAdmin(roomId);
      }

      // ── Speaking Queue ─────────────────────────────────────────────────────

      match /queue/{queueDocId} {
        allow read: if isRoomMember(roomId);

        // Join queue (your own entry)
        allow create: if isRoomMember(roomId)
          && request.resource.data.userId == request.auth.uid
          && !getRoomMember(roomId).data.isMuted
          && !getRoomMember(roomId).data.isListenerOnly;

        // Admin can set priority
        allow update: if isRoomAdmin(roomId)
          && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['priority', 'position']);

        // Leave queue (own entry) or admin removes
        allow delete: if isAuthenticated()
          && (resource.data.userId == request.auth.uid || isRoomAdmin(roomId));
      }

      // ── WebRTC Signaling ───────────────────────────────────────────────────

      match /webrtc_sessions/{sessionId} {
        allow read, write: if isRoomMember(roomId);

        match /candidates/{candidateId} {
          allow read, write: if isRoomMember(roomId);
        }
      }
    }

    // ── Analytics ─────────────────────────────────────────────────────────────

    match /analytics/{document=**} {
      allow read: if false; // Read via Admin SDK only
      allow write: if isAuthenticated(); // Authenticated writes only (anonymous events)
    }
  }
}
```

## Firestore Index Configuration (firestore.indexes.json)

```json
{
  "indexes": [
    {
      "collectionGroup": "rooms",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "inviteCode", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "members",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "lastSeen", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "queue",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "priority", "order": "DESCENDING" },
        { "fieldPath": "joinedAt", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```
