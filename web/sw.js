// sw.js

self.addEventListener('install', (event) => {
  console.log('Service Worker: Installing.');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('Service Worker: Activating.');
  event.waitUntil(self.clients.claim());
});

self.addEventListener('message', (event) => {
  console.log('Service Worker: Received message:', event.data);
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const title = event.data.title || 'Incoming call';
    showCallNotification(title);
  }
});

function showCallNotification(title) {
  const options = {
    body: 'You have an incoming call.',
    icon: '/icons/img.png',
    actions: [
      { action: 'accept', title: 'Accept Call' },
      { action: 'cancel', title: 'Cancel Call' }
    ],
    requireInteraction: true
  };

  console.log('Service Worker: Showing call notification with title:', title);
  self.registration.showNotification(title, options);

  // Notify all clients to play audio
  self.clients.matchAll().then((clients) => {
    clients.forEach((client) => {
      client.postMessage({ type: 'PLAY_AUDIO' });
    });
  });
}

self.addEventListener('notificationclick', (event) => {
  console.log('Service Worker: Notification clicked:', event.action);
  event.notification.close(); // Close the notification

  if (event.action === 'accept') {
    console.log('Service Worker: Call accepted');
    // Notify all clients (open tabs) about the accepted call
    self.clients.matchAll().then((clients) => {
      clients.forEach((client) => {
        client.postMessage({ type: 'CALL_ACCEPTED' });
      });
    });
    // Add additional logic to handle call acceptance
  } else if (event.action === 'cancel') {
    console.log('Service Worker: Call canceled');
    // Notify all clients (open tabs) about the canceled call
    self.clients.matchAll().then((clients) => {
      clients.forEach((client) => {
        client.postMessage({ type: 'CALL_CANCELED' });
      });
    });
    // Add additional logic to handle call cancellation
  } else {
    // Handle notification body click
    console.log('Service Worker: Notification body clicked');
    // Optionally, navigate the user to a specific page
  }
});