const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(express.static(path.join(__dirname, 'public')));

// roomId -> [socketId, socketId]
const rooms = new Map();

io.on('connection', (socket) => {
  socket.on('join-room', (roomId) => {
    const room = rooms.get(roomId) || [];

    if (room.length >= 2) {
      socket.emit('room-full');
      return;
    }

    room.push(socket.id);
    rooms.set(roomId, room);
    socket.join(roomId);
    socket.data.roomId = roomId;

    const isInitiator = room.length === 1;
    socket.emit('joined', { roomId, isInitiator });

    if (room.length === 2) {
      io.to(roomId).emit('ready');
    }
  });

  socket.on('offer', ({ offer, roomId }) => socket.to(roomId).emit('offer', offer));
  socket.on('answer', ({ answer, roomId }) => socket.to(roomId).emit('answer', answer));
  socket.on('ice-candidate', ({ candidate, roomId }) => socket.to(roomId).emit('ice-candidate', candidate));
  socket.on('talking', (roomId) => socket.to(roomId).emit('peer-talking', true));
  socket.on('stop-talking', (roomId) => socket.to(roomId).emit('peer-talking', false));

  socket.on('disconnect', () => {
    const roomId = socket.data.roomId;
    if (!roomId) return;
    const room = (rooms.get(roomId) || []).filter(id => id !== socket.id);
    if (room.length === 0) {
      rooms.delete(roomId);
    } else {
      rooms.set(roomId, room);
      io.to(roomId).emit('peer-disconnected');
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Walkie-Talkie server running on http://localhost:${PORT}`));
