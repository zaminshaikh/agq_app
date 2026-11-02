import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_defaults.dart';
import 'content_image.dart';

/// Public app copy and artwork only. Never stores client or account data.
class AppContent extends ChangeNotifier {
  static final instance = AppContent();
  static const _cacheKey = 'agq.appContent.v1';
  Map<String, String> _texts = {};
  Map<String, Map<String, String>> _images = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  int _version = -1;

  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<AppContentScope>();
  }

  static String text(String key, [Map<String, Object?> values = const {}]) =>
      instance.resolveText(key, values);

  String resolveText(String key, [Map<String, Object?> values = const {}]) {
    final template = _texts[key] ?? defaultAppText[key] ?? key;
    // Single pass prevents a user's data from being interpreted as another token.
    return template.replaceAllMapped(
        RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)\}'),
        (match) => values.containsKey(match[1])
            ? '${values[match[1]] ?? ''}'
            : match[0]!);
  }

  static ImageProvider imageProvider(String asset) =>
      ContentImageProvider(asset: asset, url: instance.imageFor(asset)?['url']);

  Map<String, String>? imageFor(String asset) =>
      _images[defaultAppImages[asset]];

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) applyDocument(jsonDecode(cached));
    } catch (_) {
      /* Bundled defaults work even if the local cache is unavailable. */
    }
    _subscription = FirebaseFirestore.instance
        .doc('appContent/published')
        .snapshots()
        .listen(
      (snapshot) {
        final data = snapshot.data();
        if (data != null && applyDocument(data)) {
          // Cache only JSON content, never Firestore audit timestamps.
          unawaited(_cache(
              {'version': _version, 'texts': _texts, 'images': _images}));
        }
      },
      onError: (Object error) {
        debugPrint('App content unavailable; using cached content.');
      },
    );
  }

  Future<void> _cache(Map<String, dynamic> data) async {
    try {
      await (await SharedPreferences.getInstance())
          .setString(_cacheKey, jsonEncode(data));
    } catch (_) {/* Caching is best effort. */}
  }

  /// Reject malformed values individually so a bad config cannot blank the app.
  @visibleForTesting
  bool applyDocument(dynamic data) {
    if (data is! Map || data['version'] is! int || data['version'] < _version) {
      return false;
    }
    final texts = <String, String>{};
    final rawTexts = data['texts'];
    if (rawTexts is Map) {
      for (final entry in rawTexts.entries) {
        final fallback = defaultAppText[entry.key];
        final value = entry.value;
        if (fallback == null ||
            value is! String ||
            value.trim().isEmpty ||
            value.length > 12000) {
          continue;
        }
        final pattern = RegExp(r'\{[A-Za-z][A-Za-z0-9_]*\}');
        final required = pattern.allMatches(fallback).map((m) => m[0]).toSet();
        final actual = pattern.allMatches(value).map((m) => m[0]).toSet();
        if (setEquals(required, actual)) texts[entry.key as String] = value;
      }
    }
    final images = <String, Map<String, String>>{};
    final rawImages = data['images'];
    if (rawImages is Map) {
      for (final entry in rawImages.entries) {
        final value = entry.value;
        if (!defaultAppImages.containsValue(entry.key) || value is! Map) {
          continue;
        }
        final url = value['url'];
        final contentType = value['contentType'];
        if (url is! String || contentType is! String) continue;
        final uri = Uri.tryParse(url);
        if (uri?.scheme == 'https' &&
            uri?.host == 'firebasestorage.googleapis.com' &&
            const ['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']
                .contains(contentType)) {
          images[entry.key as String] = {
            'url': url,
            'contentType': contentType
          };
        }
      }
    }
    _version = data['version'];
    _texts = texts;
    _images = images;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AppContentScope extends InheritedNotifier<AppContent> {
  AppContentScope({super.key, required super.child})
      : super(notifier: AppContent.instance);
}
