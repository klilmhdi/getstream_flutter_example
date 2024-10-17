importScripts('https://www.gstatic.com/firebasejs/8.6.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.6.1/firebase-messaging.js');

firebase.initializeApp({
    apiKey: 'AIzaSyDvSlXp5XBWfp4vy6DxAp4ArX1GKxzkkD4',
    appId: '1:871056472442:web:a085ff29e3d3a5228a3ec3',
    messagingSenderId: '871056472442',
    projectId: 'getstream-flutter-example',
    authDomain: 'getstream-flutter-example.firebaseapp.com',
    storageBucket: 'getstream-flutter-example.appspot.com',
    measurementId: 'G-L178ST726N',
});

const messaging = firebase.messaging();

const app = firebase.initializeApp(firebaseConfig);

if ("measurementId" in firebaseConfig) {
  const analytics = firebase.analytics();
}