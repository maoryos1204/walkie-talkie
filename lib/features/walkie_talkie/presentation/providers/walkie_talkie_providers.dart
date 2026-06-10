import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shmuki_talk/core/constants/firestore_constants.dart';
import 'package:shmuki_talk/core/utils/logger.dart';
import 'package:shmuki_talk/features/auth/presentation/providers/auth_providers.dart';
import 'package:shmuki_talk/features/room/data/datasources/room_remote_datasource.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';

enum WalkieTalkieStatus {
  idle,
  initializing,
  ready,
  speaking,
  inQueue,
  listening,
  error,
}

class WalkieTalkieState {
  final WalkieTalkieStatus status;
  final bool isListenerOnly;
  final bool isMicrophoneActive;
  final bool isReceivingAudio;
  final String? errorMessage;
  final bool isConnected;

  const WalkieTalkieState({
    this.status = WalkieTalkieStatus.idle,
    this.isListenerOnly = false,
    this.isMicrophoneActive = false,
    this.isReceivingAudio = false,
    this.errorMessage,
    this.isConnected = false,
  });

  bool get isSpeaking => status == WalkieTalkieStatus.speaking;
  bool get isInQueue => status == WalkieTalkieStatus.inQueue;

  WalkieTalkieState copyWith({
    WalkieTalkieStatus? status,
    bool? isListenerOnly,
    bool? isMicrophoneActive,
    bool? isReceivingAudio,
    String? errorMessage,
    bool? isConnected,
  }) {
    return WalkieTalkieState(
      status: status ?? this.status,
      isListenerOnly: isListenerOnly ?? this.isListenerOnly,
      isMicrophoneActive: isMicrophoneActive ?? this.isMicrophoneActive,
      isReceivingAudio: isReceivingAudio ?? this.isReceivingAudio,
      errorMessage: errorMessage,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class WalkieTalkieNotifier extends StateNotifier<WalkieTalkieState> {
  final String _roomId;
  final Ref _ref;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription? _roomSubscription;
  StreamSubscription? _webrtcSubscription;
  StreamSubscription? _membersSubscription;

  final _firestore = FirebaseFirestore.instance;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  DateTime? _pttPressStart;
  Timer? _heartbeatTimer;
  Timer? _presenceTimer;

  static const _pttMinDuration = Duration(milliseconds: 300);

  WalkieTalkieNotifier(this._roomId, this._ref)
      : super(const WalkieTalkieState());

  String get _currentUserId =>
      _ref.read(currentUserProvider)?.uid ?? '';
  String get _currentUserName =>
      _ref.read(currentUserProvider)?.displayName ?? '';
  String? get _currentUserPhoto =>
      _ref.read(currentUserProvider)?.photoURL;

  CollectionReference get _roomRef =>
      _firestore.collection(FirestoreConstants.roomsCollection);
  CollectionReference _webrtcSessions(String roomId) =>
      _roomRef.doc(roomId).collection(FirestoreConstants.webrtcSessionsSubcollection);

  Future<void> initialize() async {
    state = state.copyWith(status: WalkieTalkieStatus.initializing);
    AppLogger.webrtc('Initializing WalkieTalkie for room: $_roomId');

    try {
      await _setupLocalMediaStream();
      await _setupWebRTCSignaling();
      _startPresenceHeartbeat();

      state = state.copyWith(
        status: WalkieTalkieStatus.ready,
        isConnected: true,
      );

      // Update member status to online
      final dataSource = _ref.read(roomRemoteDataSourceProvider);
      await dataSource.updateMemberStatus(
        _roomId,
        _currentUserId,
        FirestoreConstants.statusOnline,
      );
    } catch (e) {
      AppLogger.e('WalkieTalkie', 'Init failed', e);
      state = state.copyWith(
        status: WalkieTalkieStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _setupLocalMediaStream() async {
    if (state.isListenerOnly) return;

    final constraints = {
      'audio': {
        'mandatory': {
          'googEchoCancellation': 'true',
          'googNoiseSuppression': 'true',
          'googAutoGainControl': 'true',
          'googHighpassFilter': 'true',
        },
        'optional': [],
      },
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);

    // Mute by default — only unmute when speaking
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = false;
    }

    AppLogger.webrtc('Local media stream ready (muted)');
  }

  Future<void> _setupWebRTCSignaling() async {
    // Watch for new WebRTC sessions targeting this user
    _webrtcSubscription = _webrtcSessions(_roomId)
        .where('state', isEqualTo: FirestoreConstants.webrtcStatePending)
        .snapshots()
        .listen(_handleIncomingSession);
  }

  Future<void> _handleIncomingSession(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;

      final data = change.doc.data() as Map<String, dynamic>;
      final speakerId = data['speakerId'] as String?;

      if (speakerId == _currentUserId) continue;
      if (data['offer'] == null) continue;

      AppLogger.webrtc('Incoming offer from $speakerId');
      await _handleOffer(change.doc.id, data);
    }
  }

  Future<void> _handleOffer(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    final pc = await _createPeerConnection(sessionId);
    _peerConnections[sessionId] = pc;

    final offerData = data['offer'] as Map<String, dynamic>;
    await pc.setRemoteDescription(RTCSessionDescription(
      offerData['sdp'] as String,
      offerData['type'] as String,
    ));

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        pc.addTrack(track, _localStream!);
      }
    }

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    await _webrtcSessions(_roomId).doc(sessionId).update({
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
      'state': FirestoreConstants.webrtcStateActive,
    });

    // Listen for ICE candidates
    _listenForIceCandidates(sessionId, pc, isLocal: true);
  }

  Future<RTCPeerConnection> _createPeerConnection(String sessionId) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null) return;
      _webrtcSessions(_roomId)
          .doc(sessionId)
          .collection(FirestoreConstants.candidatesSubcollection)
          .add({
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'candidate': candidate.candidate,
        'isLocal': true,
      });
    };

    pc.onTrack = (RTCTrackEvent event) {
      AppLogger.webrtc('Received remote track');
      state = state.copyWith(isReceivingAudio: true);
    };

    pc.onConnectionState = (RTCPeerConnectionState connectionState) {
      AppLogger.webrtc('Connection state: $connectionState');
      if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _peerConnections.remove(sessionId);
        pc.close();
      }
    };

    return pc;
  }

  void _listenForIceCandidates(
    String sessionId,
    RTCPeerConnection pc, {
    required bool isLocal,
  }) {
    _webrtcSessions(_roomId)
        .doc(sessionId)
        .collection(FirestoreConstants.candidatesSubcollection)
        .where('isLocal', isEqualTo: !isLocal)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data() as Map<String, dynamic>;
        pc.addCandidate(RTCIceCandidate(
          data['candidate'] as String,
          data['sdpMid'] as String?,
          data['sdpMLineIndex'] as int?,
        ));
      }
    });
  }

  // PTT Events

  void onPttPressed() {
    _pttPressStart = DateTime.now();
  }

  Future<void> onPttReleased() async {
    if (_pttPressStart == null) return;

    final pressDuration = DateTime.now().difference(_pttPressStart!);
    _pttPressStart = null;

    // Anti-accidental press filter
    if (pressDuration < _pttMinDuration) {
      AppLogger.webrtc('PTT press too short (${pressDuration.inMilliseconds}ms) - ignored');
      return;
    }

    if (state.isSpeaking) {
      await stopSpeaking();
    } else if (state.status == WalkieTalkieStatus.ready) {
      await startSpeaking();
    }
  }

  Future<void> startSpeaking() async {
    if (state.isListenerOnly) return;

    AppLogger.webrtc('Attempting to claim speaker role');

    final dataSource = _ref.read(roomRemoteDataSourceProvider);
    final claimed = await dataSource.tryClaimSpeaker(
      _roomId,
      _currentUserId,
      _currentUserName,
      _currentUserPhoto,
    );

    if (!claimed) {
      AppLogger.webrtc('Channel busy - could not claim speaker');
      return;
    }

    // Unmute microphone
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
      }
    }

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Create WebRTC offers for all connected peers
    await _broadcastToAllPeers();

    state = state.copyWith(
      status: WalkieTalkieStatus.speaking,
      isMicrophoneActive: true,
    );

    AppLogger.webrtc('Started speaking');
  }

  Future<void> stopSpeaking() async {
    if (!state.isSpeaking) return;

    AppLogger.webrtc('Stopping speaking');

    // Mute microphone
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = false;
      }
    }

    // Release speaker in Firestore
    final dataSource = _ref.read(roomRemoteDataSourceProvider);
    await dataSource.releaseSpeaker(_roomId, _currentUserId);

    // Close all peer connections
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();

    // Clean up WebRTC session docs
    final sessions = await _webrtcSessions(_roomId)
        .where('speakerId', isEqualTo: _currentUserId)
        .get();
    for (final doc in sessions.docs) {
      await doc.reference.update({'state': FirestoreConstants.webrtcStateEnded});
    }

    state = state.copyWith(
      status: WalkieTalkieStatus.ready,
      isMicrophoneActive: false,
    );

    HapticFeedback.lightImpact();
    AppLogger.webrtc('Stopped speaking');
  }

  Future<void> _broadcastToAllPeers() async {
    // Get all members in the room (except current user)
    final members = await _ref.read(roomRemoteDataSourceProvider)
        .watchRoomMembers(_roomId)
        .first;

    final otherMembers = members.where((m) => m.userId != _currentUserId);

    for (final member in otherMembers) {
      await _createOfferForPeer(member.userId);
    }
  }

  Future<void> _createOfferForPeer(String peerId) async {
    try {
      final sessionRef = _webrtcSessions(_roomId).doc();
      final pc = await _createPeerConnection(sessionRef.id);

      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          pc.addTrack(track, _localStream!);
        }
      }

      final offer = await pc.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });
      await pc.setLocalDescription(offer);

      await sessionRef.set({
        'speakerId': _currentUserId,
        'targetUserId': peerId,
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
        'state': FirestoreConstants.webrtcStatePending,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _peerConnections[sessionRef.id] = pc;
      _listenForAnswer(sessionRef.id, pc);
      _listenForIceCandidates(sessionRef.id, pc, isLocal: false);
    } catch (e) {
      AppLogger.e('WalkieTalkie', 'Create offer failed for peer $peerId', e);
    }
  }

  void _listenForAnswer(String sessionId, RTCPeerConnection pc) {
    _webrtcSessions(_roomId).doc(sessionId).snapshots().listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if (data['answer'] == null) return;
      if (pc.signalingState == RTCSignalingState.RTCSignalingStateStable) return;

      final answerData = data['answer'] as Map<String, dynamic>;
      await pc.setRemoteDescription(RTCSessionDescription(
        answerData['sdp'] as String,
        answerData['type'] as String,
      ));
    });
  }

  Future<void> joinQueue() async {
    if (state.isListenerOnly || state.isInQueue) return;

    final dataSource = _ref.read(roomRemoteDataSourceProvider);
    final isAdmin = _ref.read(isAdminProvider(_roomId));

    await dataSource.joinQueue(
      _roomId,
      _currentUserId,
      _currentUserName,
      _currentUserPhoto,
      isAdmin: isAdmin,
    );

    state = state.copyWith(status: WalkieTalkieStatus.inQueue);
    HapticFeedback.mediumImpact();
  }

  Future<void> leaveQueue() async {
    final dataSource = _ref.read(roomRemoteDataSourceProvider);
    await dataSource.leaveQueue(_roomId, _currentUserId);
    state = state.copyWith(status: WalkieTalkieStatus.ready);
  }

  void toggleListenerMode() {
    final newValue = !state.isListenerOnly;
    state = state.copyWith(isListenerOnly: newValue);

    final dataSource = _ref.read(roomRemoteDataSourceProvider);
    dataSource.setListenerOnly(_roomId, _currentUserId, newValue);

    if (newValue) {
      // Stop microphone if in listener mode
      if (_localStream != null) {
        for (final track in _localStream!.getAudioTracks()) {
          track.enabled = false;
        }
      }
      if (state.isSpeaking) stopSpeaking();
      if (state.isInQueue) leaveQueue();
    }
  }

  void _startPresenceHeartbeat() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updatePresence(),
    );
  }

  Future<void> _updatePresence() async {
    try {
      await _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(_currentUserId)
          .update({
        'lastSeen': FieldValue.serverTimestamp(),
        'status': state.isSpeaking
            ? FirestoreConstants.statusSpeaking
            : state.isInQueue
                ? FirestoreConstants.statusInQueue
                : FirestoreConstants.statusOnline,
        'currentRoomId': _roomId,
      });
    } catch (e) {
      AppLogger.e('WalkieTalkie', 'Presence update failed', e);
    }
  }

  void onBackground() {
    // Stop transmission if speaking, maintain presence in background
    if (state.isSpeaking) stopSpeaking();
    _presenceTimer?.cancel();
  }

  void onForeground() {
    _startPresenceHeartbeat();
    _updatePresence();
  }

  @override
  Future<void> dispose() async {
    _presenceTimer?.cancel();
    _heartbeatTimer?.cancel();
    _roomSubscription?.cancel();
    _webrtcSubscription?.cancel();
    _membersSubscription?.cancel();

    if (state.isSpeaking) {
      await stopSpeaking();
    }

    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();

    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();

    // Update presence to offline for this room
    try {
      await _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(_currentUserId)
          .update({
        'status': FirestoreConstants.statusOnline,
        'currentRoomId': null,
      });
    } catch (_) {}

    super.dispose();
    AppLogger.webrtc('WalkieTalkie disposed');
  }
}

final walkieTalkieProvider = StateNotifierProvider.family<
    WalkieTalkieNotifier, WalkieTalkieState, String>((ref, roomId) {
  return WalkieTalkieNotifier(roomId, ref);
});
