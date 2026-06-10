const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const webpush = require('web-push');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// VAPID keys for Web Push
const VAPID_PUBLIC  = process.env.VAPID_PUBLIC_KEY  || 'BN51k9-u8YLJyrTTyts6jp4RR1AX249hgAe3sZCGxH7_JG0k1Cg3gTSop7GudJR4r6krirWS5UizZpUBK-CrleM';
const VAPID_PRIVATE = process.env.VAPID_PRIVATE_KEY || 'dLGOHL34nP6vrXd34dPifBJq88vt3x61qcVv-qCSqVo';
webpush.setVapidDetails('mailto:admin@walkie-talkie.app', VAPID_PUBLIC, VAPID_PRIVATE);

// roomId -> Map<endpoint, subscription>
const roomPushSubs = new Map();
// socketId -> push endpoint (so we know which sockets are "online")
const socketEndpoints = new Map();

// roomId -> [socketId, socketId]
const rooms = new Map();

// ── Push API endpoints ──────────────────────────────────────────────────────

app.get('/vapid-key', (req, res) => res.json({ key: VAPID_PUBLIC }));

app.post('/push-subscribe', (req, res) => {
  const { roomId, subscription } = req.body;
  if (!roomId || !subscription) return res.status(400).json({ error: 'missing fields' });
  if (!roomPushSubs.has(roomId)) roomPushSubs.set(roomId, new Map());
  roomPushSubs.get(roomId).set(subscription.endpoint, subscription);
  res.json({ ok: true });
});

app.post('/push-register-socket', (req, res) => {
  const { socketId, endpoint } = req.body;
  if (socketId && endpoint) socketEndpoints.set(socketId, endpoint);
  res.json({ ok: true });
});

// ── Socket.io ───────────────────────────────────────────────────────────────

io.on('connection', (socket) => {
  socket.on('join-room', (roomId) => {
    const room = rooms.get(roomId) || [];
    if (room.length >= 2) { socket.emit('room-full'); return; }

    room.push(socket.id);
    rooms.set(roomId, room);
    socket.join(roomId);
    socket.data.roomId = roomId;

    socket.emit('joined', { roomId, isInitiator: room.length === 1 });
    if (room.length === 2) io.to(roomId).emit('ready');
  });

  socket.on('offer',         ({ offer, roomId })     => socket.to(roomId).emit('offer', offer));
  socket.on('answer',        ({ answer, roomId })    => socket.to(roomId).emit('answer', answer));
  socket.on('ice-candidate', ({ candidate, roomId }) => socket.to(roomId).emit('ice-candidate', candidate));

  socket.on('talking', async (roomId) => {
    socket.to(roomId).emit('peer-talking', true);
    await sendPushToOfflineUsers(roomId, socket.id);
  });

  socket.on('stop-talking', (roomId) => socket.to(roomId).emit('peer-talking', false));

  socket.on('disconnect', () => {
    const roomId = socket.data.roomId;
    socketEndpoints.delete(socket.id);
    if (!roomId) return;
    const room = (rooms.get(roomId) || []).filter(id => id !== socket.id);
    if (room.length === 0) rooms.delete(roomId);
    else { rooms.set(roomId, room); io.to(roomId).emit('peer-disconnected'); }
  });
});

async function sendPushToOfflineUsers(roomId, senderSocketId) {
  const subs = roomPushSubs.get(roomId);
  if (!subs || subs.size === 0) return;

  // Collect endpoints of currently connected sockets in this room
  const onlineEndpoints = new Set();
  for (const [sid, ep] of socketEndpoints) {
    if (sid !== senderSocketId) onlineEndpoints.add(ep);
  }

  const payload = JSON.stringify({ title: 'Walkie Talkie 📻', body: 'מישהו מדבר בחדר שלך!' });

  for (const [endpoint, subscription] of subs) {
    if (onlineEndpoints.has(endpoint)) continue; // already online, no need for push
    try {
      await webpush.sendNotification(subscription, payload);
    } catch (err) {
      if (err.statusCode === 404 || err.statusCode === 410) {
        subs.delete(endpoint); // subscription expired
      }
    }
  }
}

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Walkie-Talkie server running on http://localhost:${PORT}`));
