'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "9e276a8a4b07bbcee0d6f09353387864",
"version.json": "6f6d24d01da3f63cce69e49884179cd4",
"index.html": "dbb4ee345e93606da050ebf212b8c7ef",
"/": "dbb4ee345e93606da050ebf212b8c7ef",
"main.dart.js": "2bb36fdf809500d31ca5ac4eb71ea7c6",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "fb5c47da7e27784364b0eee6479d67eb",
"icons/favicon.ico": "2e75aa8e5d8916cfbeb24c8e69f63386",
"icons/apple-touch-icon.png": "fb5c47da7e27784364b0eee6479d67eb",
"icons/icon-192.png": "e5ee17a5f8253321bb1f5a612664cd10",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/icon-192-maskable.png": "ee6d701bd4724e1b44d03cd715ba4c1e",
"icons/icon-512-maskable.png": "6183c5bf1aaa2ab1c43e76c1877f301c",
"icons/README.txt": "d3df3991a31f034bfa98afdfa3c622e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/icon-512.png": "b343e0a40ee8bfccd6171e318b83606d",
"manifest.json": "2f84cadad40a87768661ddb816e4dda8",
"assets/AssetManifest.json": "7715dcd9da3a55672d657d0c180d24c2",
"assets/NOTICES": "5da9c3bec0b8fe3688aabdbf88c3896d",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "56ea88a574d16c4302143499bd8839fe",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "9571cf55dc9417445cd9e3b24b69e147",
"assets/fonts/MaterialIcons-Regular.otf": "f4d68a7c55bea9570e94d452870ecefd",
"assets/assets/hike_5.jpeg": "0968151e063ae1b6563136f68be563c1",
"assets/assets/she_travel.png": "2dd12ba2657812dc31d62b7ec88f84c3",
"assets/assets/past3.webp": "b79e6467e16b47c2d78f4b505671cfb8",
"assets/assets/bali.webp": "69b20bd61b7e026b55ed13541448aa03",
"assets/assets/safety3.webp": "4d242dc9e9e3d410ae2120062a4123d8",
"assets/assets/safety2.webp": "adeb43a3068ac072445188da7b4fa3cb",
"assets/assets/image_2.webp": "f5ce0d4642ed6f8d2f40894685a6b1c7",
"assets/assets/hike_4.jpeg": "20f3715b4ec68dd5e3889eba61a8edeb",
"assets/assets/AdobeStock_506875945.mov": "f69d7d507785cf858a53b68af130f9dd",
"assets/assets/image_5.webp": "2b50420c561983fc826cc2c470108590",
"assets/assets/hike_3.jpeg": "46ae8e4b61af505c7ed6ea6be2be6fbd",
"assets/assets/image_9.webp": "bc33ced2c9d278faad7673b5ba7d7e93",
"assets/assets/safety.webp": "0ad4e13a7b05292df53c5a32ef7faf98",
"assets/assets/hike_2.jpeg": "2a326f90aefb47d25db7c2042b905109",
"assets/assets/image_11.webp": "e1f5655b9b947495997b3ab3b10c887f",
"assets/assets/she_travel.svg": "a05fa4e5c99a56b7fc3635cd6cc2961d",
"assets/assets/email.svg": "140c929c194a5f5bb7a08eceb68893c4",
"assets/assets/image_7.webp": "304dfbced938f4f73887b84e418d9998",
"assets/assets/past2.jpeg": "75690b0e2e11317c3d4a57c83d09fc54",
"assets/assets/mission.webp": "2c2568c5dfcd602402e7840a56fad168",
"assets/assets/safety_group.webp": "feb7d938e19cc42961315230bf929cb4",
"assets/assets/hike_1.jpeg": "0ecf58f4a6141dd376c9410c96b0a4e4",
"assets/assets/facebook.svg": "c843b96415558ef821cc57cf55b9ff79",
"assets/assets/whatsapp.svg": "b446a5514b6f3f83c6dddcec87da10ad",
"assets/assets/aleksa_portrait.png": "3fba71f3cc9113aa0cdc8ec3064c7439",
"assets/assets/image_6.webp": "ad31a31610bb1386e92acaf7c958e8b8",
"assets/assets/past1.webp": "b79e6467e16b47c2d78f4b505671cfb8",
"assets/assets/image_1.webp": "a90289f0341c0176ba0d29a2b7cbf9fd",
"assets/assets/data/local_events.json": "13a2e10e65a1b82aae55841df7be02a8",
"assets/assets/data/memories.json": "9138c3c3e2424a9b1f1d06f047a972c8",
"assets/assets/data/gallery.json": "f6c8703f1fc297160651f9e3c0634114",
"assets/assets/home_image.webp": "548b5b3a8cfb3ff3f57384d5e653f5c1",
"assets/assets/ig.svg": "2f93e8bb7b95fb9119b40b563d5dce95",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
