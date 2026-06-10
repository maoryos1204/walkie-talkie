self.addEventListener('push', event => {
  const data = event.data?.json() || {};
  event.waitUntil(
    self.registration.showNotification(data.title || 'Walkie Talkie', {
      body: data.body || 'מישהו מדבר בחדר שלך!',
      icon: '/icon.svg',
      badge: '/icon.svg',
      tag: 'walkie-talkie',
      renotify: true,
      vibrate: [200, 100, 200],
      data: { url: self.location.origin }
    })
  );
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const client of list) {
        if (client.url.startsWith(event.notification.data.url) && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow(event.notification.data.url);
    })
  );
});
