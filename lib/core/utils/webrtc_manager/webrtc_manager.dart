// import 'package:flutter_webrtc/flutter_webrtc.dart';
//
// late RTCPeerConnection peerConnection;
//
// void setupPeerConnection() async {
//   // Initialize the PeerConnection
//   Map<String, dynamic> _configuration = {
//     "iceServers": [
//       {
//         "urls": "stun:stun.l.google.com:19302", // Free STUN server
//       },
//       {
//         "urls": "turn:your-turn-server.com:3478", // TURN server for fallback
//         "username": "your-username",
//         "credential": "your-password",
//       },
//     ]
//   };
//
//   peerConnection = await createPeerConnection(_configuration, constraints);
//
//   // Listen for ICE connection state changes
//   peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
//     print('ICE Connection State changed: $state');
//     switch (state) {
//       case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
//       case RTCIceConnectionState.RTCIceConnectionStateFailed:
//         print('Connection lost. Attempting to reconnect...');
//         reconnect();
//         break;
//       case RTCIceConnectionState.RTCIceConnectionStateConnected:
//         print('Connection established.');
//         break;
//       default:
//         print('ICE state: $state');
//     }
//   };
// }
//
// void reconnect() {
//   // Example reconnection logic
//   print('Reconnecting...');
//   // Restart ICE candidate negotiation
//   peerConnection.restartIce();
//   // You may also need to reinitialize signaling or renegotiate SDP
// }
