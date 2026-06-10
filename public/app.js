'use strict';

const socket = io();

const ICE_SERVERS = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' }
  ]
};

// State
let pc = null;
let localStream = null;
let roomId = null;
let isInitiator = false;
let isTalking = false;
let mediaReadyResolve;
const mediaReadyPromise = new Promise(r => { mediaReadyResolve = r; });
const iceCandidateQueue = [];

// DOM refs
const setupScreen   = document.getElementById('setup-screen');
const waitingScreen = document.getElementById('waiting-screen');
const walkieScreen  = document.getElementById('walkie-screen');
const pttBtn        = document.getElementById('ptt-btn');

function showScreen(el) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  el.classList.add('active');
}

// ── Setup actions ──────────────────────────────────────────────────────────

document.getElementById('create-room-btn').addEventListener('click', () => {
  const id = Math.random().toString(36).substring(2, 8).toUpperCase();
  doJoin(id);
});

document.getElementById('join-room-btn').addEventListener('click', () => {
  const id = document.getElementById('room-input').value.trim().toUpperCase();
  if (id.length < 4) { alert('הכנס קוד חדר תקין (לפחות 4 תווים)'); return; }
  doJoin(id);
});

document.getElementById('room-input').addEventListener('keydown', e => {
  if (e.key === 'Enter') document.getElementById('join-room-btn').click();
});

function doJoin(id) {
  socket.emit('join-room', id);
}

// ── Socket events ──────────────────────────────────────────────────────────

socket.on('joined', ({ roomId: id, isInitiator: init }) => {
  roomId = id;
  isInitiator = init;
  document.getElementById('room-code-display').textContent = id;
  document.getElementById('room-label').textContent = `חדר: ${id}`;

  if (isInitiator) showScreen(waitingScreen);

  initMedia(); // kick off mic request right away (don't await – runs in background)
});

socket.on('room-full', () => alert('החדר מלא! נסה קוד אחר.'));

socket.on('ready', async () => {
  showScreen(walkieScreen);
  await mediaReadyPromise; // wait for mic permission
  createPC();
  if (isInitiator) await sendOffer();
});

socket.on('offer', async (offer) => {
  await mediaReadyPromise;
  if (!pc) createPC();
  await pc.setRemoteDescription(offer);
  const answer = await pc.createAnswer();
  await pc.setLocalDescription(answer);
  socket.emit('answer', { answer, roomId });
  await flushIceCandidates();
});

socket.on('answer', async (answer) => {
  await pc.setRemoteDescription(answer);
  await flushIceCandidates();
});

socket.on('ice-candidate', async (candidate) => {
  if (pc && pc.remoteDescription) {
    await pc.addIceCandidate(candidate);
  } else {
    iceCandidateQueue.push(candidate);
  }
});

socket.on('peer-talking', (talking) => {
  const el = document.getElementById('peer-talking');
  if (talking) el.classList.remove('hidden');
  else el.classList.add('hidden');
});

socket.on('peer-disconnected', () => {
  setStatus(false);
  alert('החבר שלך התנתק מהחדר');
});

// ── Media ─────────────────────────────────────────────────────────────────

async function initMedia() {
  try {
    localStream = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: true, noiseSuppression: true, sampleRate: 44100 },
      video: false
    });
    // Muted by default — push-to-talk unmutes
    localStream.getAudioTracks().forEach(t => { t.enabled = false; });
    mediaReadyResolve();
  } catch (err) {
    alert('לא ניתן לגשת למיקרופון. נא לאשר הרשאה ולרענן את הדף.\n\n' + err.message);
  }
}

// ── WebRTC ────────────────────────────────────────────────────────────────

function createPC() {
  pc = new RTCPeerConnection(ICE_SERVERS);

  localStream.getTracks().forEach(t => pc.addTrack(t, localStream));

  pc.onicecandidate = ({ candidate }) => {
    if (candidate) socket.emit('ice-candidate', { candidate, roomId });
  };

  pc.ontrack = ({ streams }) => {
    const audio = new Audio();
    audio.srcObject = streams[0];
    audio.play().catch(() => {}); // autoplay policy — browsers allow after user gesture
  };

  pc.onconnectionstatechange = () => {
    setStatus(pc.connectionState === 'connected');
  };
}

async function sendOffer() {
  const offer = await pc.createOffer();
  await pc.setLocalDescription(offer);
  socket.emit('offer', { offer, roomId });
}

async function flushIceCandidates() {
  for (const c of iceCandidateQueue) await pc.addIceCandidate(c);
  iceCandidateQueue.length = 0;
}

// ── Push to talk ──────────────────────────────────────────────────────────

function pttStart(e) {
  e.preventDefault();
  if (!localStream || isTalking) return;
  isTalking = true;

  localStream.getAudioTracks().forEach(t => { t.enabled = true; });
  pttBtn.classList.add('active');
  document.getElementById('ptt-label').textContent = 'שידור...';
  document.getElementById('display-content').innerHTML =
    '<div class="display-talking">' +
    '<div class="wave-bar"></div><div class="wave-bar"></div><div class="wave-bar"></div>' +
    '<div class="wave-bar"></div><div class="wave-bar"></div>' +
    '</div>';
  socket.emit('talking', roomId);
}

function pttEnd(e) {
  e.preventDefault();
  if (!localStream || !isTalking) return;
  isTalking = false;

  localStream.getAudioTracks().forEach(t => { t.enabled = false; });
  pttBtn.classList.remove('active');
  document.getElementById('ptt-label').textContent = 'לחץ להעביר';
  document.getElementById('display-content').className = 'display-standby';
  document.getElementById('display-content').textContent = 'STANDBY';
  socket.emit('stop-talking', roomId);
}

// Expose PTT handlers to inline HTML attrs
window.pttStart = pttStart;
window.pttEnd = pttEnd;

// ── Helpers ───────────────────────────────────────────────────────────────

function setStatus(connected) {
  const el = document.getElementById('conn-status');
  el.textContent = connected ? '● מחובר' : '● מנותק';
  el.className = 'badge ' + (connected ? 'green' : 'red');
}
