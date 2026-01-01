// sw.js - Service Worker для оффлайн работы
const CACHE_NAME = 'wifi-scanner-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/scripts/termux-root.sh',
  '/tools/backup-extractor.py'
];

// Установка Service Worker
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

// Активация и очистка старых кэшей
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Перехват запросов
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Возвращаем из кэша или делаем сетевой запрос
        return response || fetch(event.request);
      })
  );
});
