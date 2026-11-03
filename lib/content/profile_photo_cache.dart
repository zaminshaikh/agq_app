import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Two public team portraits only. One atomic file per photo bounds disk use;
/// the published URL is the version key. Never stores client/account data.
class ProfilePhotoCache {
  static final instance = ProfilePhotoCache();
  static const assets = {
    'assets/icons/sonny_headshot.png',
    'assets/icons/kash_headshot.png',
  };
  final Future<Directory> Function() directory;
  final Future<Uint8List> Function(String) download;
  final Future<void> Function(Uint8List) validate;
  final _memory = <String, _Photo>{};
  final _reading = <String, Future<_Photo?>>{};
  final _pending = <String, Future<_Photo>>{};
  final _latest = <String, String>{};

  ProfilePhotoCache({
    Future<Directory> Function()? directory,
    Future<Uint8List> Function(String)? download,
    Future<void> Function(Uint8List)? validate,
  })  : directory = directory ?? _directory,
        download = download ?? _download,
        validate = validate ?? _validate;

  static Future<Directory> _directory() async => Directory(
      '${(await getApplicationSupportDirectory()).path}/profile-photos');
  static Future<Uint8List> _download(String url) async {
    final client = http.Client();
    try {
      return await (() async {
        final response = await client.send(http.Request('GET', Uri.parse(url)));
        if (response.statusCode != 200) {
          throw const HttpException('Photo unavailable');
        }
        if ((response.contentLength ?? 0) > 5 * 1024 * 1024) {
          throw const FormatException('Invalid photo size');
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 5 * 1024 * 1024) {
            throw const FormatException('Invalid photo size');
          }
          bytes.add(chunk);
        }
        return bytes.takeBytes();
      })()
          .timeout(const Duration(seconds: 8));
    } finally {
      // Close the socket on timeout, failure, or oversized responses too.
      client.close();
    }
  }

  static Future<void> _validate(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 512);
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  }

  Future<File> _file(String asset, {bool legacy = false}) async {
    final dir = await directory();
    await dir.create(recursive: true);
    return File(
        '${dir.path}/${asset.split('/').last}.${legacy ? 'json' : 'cache'}');
  }

  Uint8List? peek(String asset) => _memory[asset]?.bytes;

  Future<_Photo?> _read(String asset) {
    if (_memory.containsKey(asset)) return Future.value(_memory[asset]);
    return _reading.putIfAbsent(
        asset,
        () => _readDisk(asset).whenComplete(() {
              _reading.remove(asset);
            }));
  }

  Future<_Photo?> _readDisk(String asset) async {
    try {
      final file = await _file(asset);
      _Photo photo;
      if (await file.exists()) {
        // Header is just a short URL; photo bytes stay binary, avoiding base64/JSON work.
        if (await file.length() > 5 * 1024 * 1024 + 8192) return null;
        final bytes = await file.readAsBytes();
        final separator = bytes.indexOf(10);
        if (separator <= 0 || separator > 8192) return null;
        photo = _Photo(utf8.decode(Uint8List.sublistView(bytes, 0, separator)),
            Uint8List.sublistView(bytes, separator + 1));
      } else {
        final legacy = await _file(asset, legacy: true);
        if (!await legacy.exists() || await legacy.length() > 7 * 1024 * 1024) {
          return null;
        }
        // Prior PR builds used base64 JSON. Decode those off the UI isolate.
        final raw =
            await compute(_decodeLegacyPhoto, await legacy.readAsString());
        photo = _Photo(raw['url'] as String, raw['bytes'] as Uint8List);
      }
      await _check(photo.bytes);
      return _memory.putIfAbsent(asset, () => photo);
    } catch (_) {
      return null;
    }
  }

  Future<void> _check(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Invalid photo size');
    }
    await validate(bytes);
  }

  Future<_Photo> _fetch(String asset, String url) async {
    final bytes = await download(url);
    await _check(bytes);
    final photo = _Photo(url, bytes);
    if (_latest[asset] == url) {
      _memory[asset] = photo;
      try {
        final target = await _file(asset);
        // Unique temporary files prevent concurrent downloads sharing a writer.
        final temporary =
            File('${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
        final writer = await temporary.open(mode: FileMode.write);
        try {
          await writer.writeFrom(utf8.encode('$url\n'));
          await writer.writeFrom(bytes);
          await writer.flush();
        } finally {
          await writer.close();
        }
        if (_latest[asset] == url) {
          await temporary.rename(target.path);
          final legacy = await _file(asset, legacy: true);
          if (await legacy.exists()) await legacy.delete();
        } else {
          await temporary.delete();
        }
      } catch (_) {
        /* Keep the validated in-memory photo if disk is unavailable. */
      }
    }
    return photo;
  }

  Stream<Uint8List> watch(String asset, String url) async* {
    if (!assets.contains(asset)) return;
    _latest[asset] = url;
    final previous = await _read(asset);
    if (previous != null) {
      yield previous.bytes;
      if (previous.url == url) return;
    }
    final key = '$asset|$url';
    try {
      final future = _pending.putIfAbsent(key, () => _fetch(asset, url));
      try {
        yield (await future).bytes;
      } finally {
        if (identical(_pending[key], future)) {
          final removed = _pending.remove(key);
          assert(identical(removed, future));
        }
      }
    } catch (_) {
      /* The cached photo or bundled widget remains visible offline. */
    }
  }
}

class _Photo {
  final String url;
  final Uint8List bytes;
  _Photo(this.url, this.bytes);
}

Map<String, Object> _decodeLegacyPhoto(String encoded) {
  final raw = jsonDecode(encoded);
  if (raw is! Map || raw['url'] is! String || raw['bytes'] is! String) {
    throw const FormatException('Invalid legacy photo');
  }
  return {
    'url': raw['url'] as String,
    'bytes': base64Decode(raw['bytes'] as String)
  };
}
