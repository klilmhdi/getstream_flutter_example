// [firebase-messaging-sw.js]

importScripts('https://www.gstatic.com/firebasejs/8.6.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.6.1/firebase-messaging.js');

firebase.initializeApp({
  apiKey: "AIzaSyDvSlXp5XBWfp4vy6DxAp4ArX1GKxzkkD4",
  authDomain: "getstream-flutter-example.firebaseapp.com",
  projectId: "getstream-flutter-example",
  storageBucket: "getstream-flutter-example.appspot.com",
  messagingSenderId: "871056472442",
  appId: "1:871056472442:web:a085ff29e3d3a5228a3ec3"
});

const messaging = firebase.messaging();
