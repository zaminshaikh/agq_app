import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_defaults.dart';
import 'inline_contacts.dart';

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

  static String contactTarget(String key) => instance.resolveContactTarget(key);

  String resolveContactTarget(String key) =>
      _contactValue(key, resolveText(key)) ??
      _contactValue(key, defaultAppText[key] ?? '') ??
      '';

  static String? _contactValue(String key, String text) {
    final email = key.endsWith('_email_message');
    final pattern = email
        ? RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')
        : RegExp(r'\+?[0-9][0-9 ()-]{5,}[0-9]');
    final matches = pattern.allMatches(text).toList();
    if (matches.length != 1) return null;
    final value = matches.single.group(0)!;
    if (email) return value;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) return null;
    return value.startsWith('+') ? '+$digits' : digits;
  }

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
    final rawTexts =
        data['texts'] is Map ? Map<dynamic, dynamic>.from(data['texts']) : null;
    if (rawTexts is Map) {
      for (final entry in inlineContacts.entries) {
        if (rawTexts.containsKey(entry.key)) continue;
        final legacy = rawTexts[entry.value[0]];
        final contact = rawTexts[entry.value[1]];
        final token = entry.value[2];
        final fallback = defaultAppText[entry.key]!;
        final pattern = token == 'phone'
            ? RegExp(r'\+?[0-9][0-9 ()-]{5,}[0-9]')
            : RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
        final fallbackContact = pattern.firstMatch(fallback)!.group(0)!;
        final address = contact is String && contact.trim().isNotEmpty
            ? contact
            : fallbackContact;
        rawTexts[entry.key] = legacy is String
            ? legacy.replaceAll('{$token}', address)
            : fallback.replaceFirst(pattern, address);
      }
    }
    if (rawTexts is Map) {
      for (final entry in rawTexts.entries) {
        final fallback = defaultAppText[entry.key];
        final value = entry.value;
        if (!configurableAppText.contains(entry.key) ||
            fallback == null ||
            value is! String ||
            value.trim().isEmpty ||
            value.length > 12000) {
          continue;
        }
        final pattern = RegExp(r'\{[A-Za-z][A-Za-z0-9_]*\}');
        final required = pattern.allMatches(fallback).map((m) => m[0]).toSet();
        final actual = pattern.allMatches(value).map((m) => m[0]).toSet();
        final key = entry.key as String;
        if ((key.endsWith('_email_message') ||
                key.endsWith('_phone_message')) &&
            _contactValue(key, value) == null) {
          continue;
        }
        if (setEquals(required, actual)) texts[key] = value;
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
