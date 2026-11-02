import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
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
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const HttpException('Photo unavailable');
    }
    return response.bodyBytes;
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

  Future<File> _file(String asset) async {
    final dir = await directory();
    await dir.create(recursive: true);
    return File('${dir.path}/${asset.split('/').last}.json');
  }

  Uint8List? peek(String asset) => _memory[asset]?.bytes;

  Future<_Photo?> _read(String asset) async {
    if (_memory.containsKey(asset)) return _memory[asset];
    try {
      final raw = jsonDecode(await (await _file(asset)).readAsString());
      if (raw['url'] is! String || raw['bytes'] is! String) return null;
      final bytes = base64Decode(raw['bytes']);
      await _check(bytes);
      return _memory[asset] = _Photo(raw['url'], bytes);
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
        await temporary.writeAsString(
            jsonEncode({'url': url, 'bytes': base64Encode(bytes)}),
            flush: true);
        if (_latest[asset] == url) {
          await temporary.rename(target.path);
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
