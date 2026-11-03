import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:agq_app/content/profile_photo_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const asset = 'assets/icons/sonny_headshot.png';
  late Directory dir;
  final old = Uint8List.fromList([1, 2, 3]);
  final fresh = Uint8List.fromList([4, 5, 6]);
  Future<void> validate(Uint8List bytes) async {
    if (bytes.first == 0) throw const FormatException('Bad image');
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('agq-photo-test-');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  test(
      'a new cache instance reuses the persisted URL without a network request',
      () async {
    var downloads = 0;
    ProfilePhotoCache cache() => ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async {
          downloads++;
          return old;
        },
        validate: validate);
    expect(await cache().watch(asset, 'photo-v1').last, old);
    expect(await cache().watch(asset, 'photo-v1').last, old);
    expect(downloads, 1);
  });
  test(
      'URL changes emit the old photo immediately, then persist the fresh photo',
      () async {
    final pending = Completer<Uint8List>();
    final cache = ProfilePhotoCache(
        directory: () async => dir,
        download: (url) async => url == 'photo-v1' ? old : pending.future,
        validate: validate);
    await cache.watch(asset, 'photo-v1').drain<void>();
    final values = <Uint8List>[];
    final first = Completer<void>();
    final done = cache.watch(asset, 'photo-v2').listen((bytes) {
      values.add(bytes);
      if (!first.isCompleted) first.complete();
    }).asFuture<void>();
    await first.future;
    expect(values.single, old);
    pending.complete(fresh);
    await done;
    expect(values, [old, fresh]);
    final restarted = ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async => throw StateError('Must use disk'),
        validate: validate);
    expect(await restarted.watch(asset, 'photo-v2').last, fresh);
    expect((await dir.list().toList()).length, 1);
  });
  test('offline or malformed replacement keeps the last valid disk photo',
      () async {
    final cache = ProfilePhotoCache(
        directory: () async => dir,
        download: (url) async {
          if (url == 'photo-v1') return old;
          if (url == 'offline') throw const SocketException('offline');
          return Uint8List.fromList([0]);
        },
        validate: validate);
    await cache.watch(asset, 'photo-v1').drain<void>();
    expect(await cache.watch(asset, 'offline').toList(), [old]);
    expect(await cache.watch(asset, 'broken').toList(), [old]);
    final restarted = ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async => throw StateError('Must use disk'),
        validate: validate);
    expect(await restarted.watch(asset, 'photo-v1').last, old);
  });
  test('non-profile artwork never downloads or creates cache files', () async {
    final cache = ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async => throw StateError('No downloads allowed'),
        validate: validate);
    expect(await cache.watch('assets/icons/agq_logo.png', 'logo').toList(),
        isEmpty);
    expect(await dir.list().toList(), isEmpty);
  });
  test('corrupted cache recovers using a valid download', () async {
    await File('${dir.path}/sonny_headshot.png.json').writeAsString('broken');
    final cache = ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async => fresh,
        validate: validate);
    expect(await cache.watch(asset, 'photo-v1').last, fresh);
  });
  test('simultaneous portrait consumers share one disk read and download',
      () async {
    var downloads = 0;
    final cache = ProfilePhotoCache(
      directory: () async => dir,
      download: (_) async {
        downloads++;
        await Future<void>.delayed(Duration.zero);
        return old;
      },
      validate: validate,
    );
    final results = await Future.wait([
      cache.watch(asset, 'photo-v1').last,
      cache.watch(asset, 'photo-v1').last
    ]);
    expect(results, [old, old]);
    expect(downloads, 1);
    var validations = 0;
    final restarted = ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async => throw StateError('Must use disk'),
        validate: (bytes) async {
          validations++;
          await validate(bytes);
        });
    await Future.wait([
      restarted.watch(asset, 'photo-v1').last,
      restarted.watch(asset, 'photo-v1').last
    ]);
    expect(validations, 1);
  });

  test('portrait file stores binary bytes without base64 expansion', () async {
    final bytes = Uint8List(1024 * 1024)..[0] = 1;
    final cache = ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async => bytes,
        validate: validate);
    await cache.watch(asset, 'photo-v1').drain<void>();
    final files = await dir.list().toList();
    expect(files.length, 1);
    expect(await File(files.single.path).length(),
        bytes.length + utf8.encode('photo-v1\n').length);
  });

  test('previous JSON photo caches remain readable without downloading',
      () async {
    await File('${dir.path}/sonny_headshot.png.json').writeAsString(
        jsonEncode({'url': 'photo-v1', 'bytes': base64Encode(old)}));
    final cache = ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async => throw StateError('Must use legacy cache'),
        validate: validate);
    expect(await cache.watch(asset, 'photo-v1').last, old);
  });
  test('real portrait bytes decode and persist in the new binary format',
      () async {
    final bytes = await File('assets/icons/sonny_headshot.png').readAsBytes();
    final cache = ProfilePhotoCache(
        directory: () async => dir, download: (_) async => bytes);
    expect(await cache.watch(asset, 'photo-v1').last, bytes);
    final restarted = ProfilePhotoCache(
        directory: () async => dir,
        download: (_) async => throw StateError('Must use disk'));
    expect(await restarted.watch(asset, 'photo-v1').last, bytes);
  });
}
