// notification.js

function showCallNotification(title) {
  console.log('notification.js: Attempting to show call notification.');
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.ready.then(function(registration) {
      if (registration.active) {
        console.log('notification.js: Sending SHOW_NOTIFICATION message to Service Worker.');
        registration.active.postMessage({ type: 'SHOW_NOTIFICATION', title: title });
      } else {
        console.log('notification.js: No active Service Worker.');
      }
    }).catch(function(error) {
      console.log('notification.js: Service Worker not ready:', error);
    });
  } else {
    console.log('notification.js: Service Workers are not supported in this browser.');
  }
}

// Listen for messages from the Service Worker
navigator.serviceWorker.addEventListener('message', function(event) {
  console.log('notification.js: Received message from Service Worker:', event.data);
  if (event.data) {
    if (event.data.type === 'CALL_ACCEPTED') {
      // Notify Flutter that the call was accepted
      window.dispatchEvent(new CustomEvent('call-accepted'));
    } else if (event.data.type === 'CALL_CANCELED') {
      // Notify Flutter that the call was canceled
      window.dispatchEvent(new CustomEvent('call-canceled'));
    } else if (event.data.type === 'PLAY_AUDIO') {
      // Notify Flutter to play audio
      window.dispatchEvent(new CustomEvent('play-audio'));
    }
  }
});