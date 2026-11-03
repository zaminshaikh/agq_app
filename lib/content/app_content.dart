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
  StreamSubscription<Map<String, dynamic>?>? _contentSubscription;
  int _version = -1;
  Future<void>? _initialization;
  bool _disposed = false;
  Future<void> _cacheWrites = Future<void>.value();
  final Future<String?> Function() _readCache;
  final Future<void> Function(String) _writeCache;
  final Stream<Map<String, dynamic>?> Function() _documents;
  static final _tokenPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)\}');
  static final _requiredTokens = <String, Set<String>>{};

  AppContent({
    Future<String?> Function()? readCache,
    Future<void> Function(String)? writeCache,
    Stream<Map<String, dynamic>?> Function()? documents,
  })  : _readCache = readCache ?? _readPreferences,
        _writeCache = writeCache ?? _writePreferences,
        _documents = documents ?? _publishedDocuments;

  static Future<String?> _readPreferences() async =>
      (await SharedPreferences.getInstance()).getString(_cacheKey);
  static Future<void> _writePreferences(String value) async {
    await (await SharedPreferences.getInstance()).setString(_cacheKey, value);
  }

  static Stream<Map<String, dynamic>?> _publishedDocuments() =>
      FirebaseFirestore.instance
          .doc('appContent/published')
          .snapshots()
          .map((snapshot) => snapshot.data());

  static void watch(BuildContext context, {Set<String>? keys}) {
    if (keys == null) {
      InheritedModel.inheritFrom<_ContentModel>(context);
    } else {
      for (final key in keys) {
        InheritedModel.inheritFrom<_ContentModel>(context, aspect: key);
      }
    }
  }

  static void watchImage(BuildContext context, String asset) {
    final key = defaultAppImages[asset];
    if (key != null) {
      InheritedModel.inheritFrom<_ContentModel>(context, aspect: key);
    }
  }

  static String text(String key, [Map<String, Object?> values = const {}]) =>
      instance.resolveText(key, values);

  String resolveText(String key, [Map<String, Object?> values = const {}]) {
    final template = _texts[key] ?? defaultAppText[key] ?? key;
    if (values.isEmpty || !template.contains('{')) return template;
    // Single pass prevents a user's data from being interpreted as another token.
    return template.replaceAllMapped(
        _tokenPattern,
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

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      final cached = await _readCache();
      if (_disposed) return;
      if (cached != null) applyDocument(jsonDecode(cached));
    } catch (_) {
      // Bundled defaults remain available without waiting for disk or network.
    }
    if (_disposed) return;
    try {
      _contentSubscription = _documents().listen((data) {
        if (_disposed || data == null || !applyDocument(data)) return;
        final cached = jsonEncode(
            {'version': _version, 'texts': _texts, 'images': _images});
        // Serialize writes so an older snapshot cannot overwrite a newer cache.
        _cacheWrites = _cacheWrites.then((_) async {
          try {
            await _writeCache(cached);
          } catch (_) {/* Best effort. */}
        });
      }, onError: (Object error) {
        debugPrint('App content unavailable; using cached content.');
      });
    } catch (_) {
      debugPrint('App content unavailable; using cached content.');
    }
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
        final required = _requiredTokens.putIfAbsent(entry.key as String,
            () => _tokenPattern.allMatches(fallback).map((m) => m[0]!).toSet());
        final actual =
            _tokenPattern.allMatches(value).map((m) => m[0]!).toSet();
        final key = entry.key as String;
        if ((key.endsWith('_email_message') ||
                key.endsWith('_phone_message')) &&
            _contactValue(key, value) == null) {
          continue;
        }
        if (setEquals(required, actual) && value != fallback) {
          texts[key] = value;
        }
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
    final changed = !mapEquals(_texts, texts) ||
        _images.length != images.length ||
        images.entries
            .any((entry) => !mapEquals(_images[entry.key], entry.value));
    final newer = data['version'] != _version;
    _version = data['version'];
    if (changed) {
      _texts = texts;
      _images = images;
      notifyListeners();
    }
    return changed || newer;
  }

  @override
  void dispose() {
    _disposed = true;
    _contentSubscription?.cancel();
    super.dispose();
  }
}

class AppContentScope extends StatefulWidget {
  final Widget child;
  const AppContentScope({super.key, required this.child});
  @override
  State<AppContentScope> createState() => _AppContentScopeState();
}

class _AppContentScopeState extends State<AppContentScope> {
  @override
  void initState() {
    super.initState();
    AppContent.instance.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    AppContent.instance.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ContentModel(
      texts: AppContent.instance._texts,
      images: AppContent.instance._images,
      child: widget.child);
}

class _ContentModel extends InheritedModel<String> {
  final Map<String, String> texts;
  final Map<String, Map<String, String>> images;
  const _ContentModel(
      {required this.texts, required this.images, required super.child});
  @override
  bool updateShouldNotify(_ContentModel oldWidget) =>
      !identical(texts, oldWidget.texts) ||
      !identical(images, oldWidget.images);
  @override
  bool updateShouldNotifyDependent(
          _ContentModel oldWidget, Set<String> dependencies) =>
      dependencies.any((key) =>
          texts[key] != oldWidget.texts[key] ||
          !mapEquals(images[key], oldWidget.images[key]));
}
