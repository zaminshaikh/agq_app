import 'dart:async';
import 'dart:convert';
import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'initialization is shared and defaults remain usable during slow cache reads',
      () async {
    final cache = Completer<String?>();
    var reads = 0, subscriptions = 0;
    final source = StreamController<Map<String, dynamic>?>();
    final content = AppContent(
      readCache: () {
        reads++;
        return cache.future;
      },
      writeCache: (_) async {},
      documents: () {
        subscriptions++;
        return source.stream;
      },
    );
    final first = content.initialize();
    expect(identical(first, content.initialize()), true);
    expect(content.resolveText('signup.cid_help'),
        defaultAppText['signup.cid_help']);
    expect(reads, 1);
    cache.complete(jsonEncode({
      'version': 1,
      'texts': {'signup.cid_help': 'cached@example.com'}
    }));
    await first;
    expect(subscriptions, 1);
    expect(content.resolveText('signup.cid_help'), 'cached@example.com');
    await content.initialize();
    expect(subscriptions, 1);
    content.dispose();
    await source.close();
  });

  test('duplicate snapshots and version-only updates do not notify widgets',
      () {
    final content = AppContent();
    var notifications = 0;
    content.addListener(() => notifications++);
    final doc = {
      'version': 1,
      'texts': {'signup.cid_help': 'cached@example.com'}
    };
    expect(content.applyDocument(doc), true);
    expect(notifications, 1);
    expect(content.applyDocument(doc), false);
    expect(content.applyDocument({...doc, 'version': 2}), true);
    expect(notifications, 1);
    content.dispose();
  });

  test('disk cache writes stay ordered when a previous write is slow',
      () async {
    final source = StreamController<Map<String, dynamic>?>();
    final firstWrite = Completer<void>();
    final lastWrite = Completer<void>();
    final versions = <int>[];
    final content = AppContent(
      readCache: () async => null,
      documents: () => source.stream,
      writeCache: (value) async {
        final version = jsonDecode(value)['version'] as int;
        versions.add(version);
        if (version == 1) {
          await firstWrite.future;
        } else {
          lastWrite.complete();
        }
      },
    );
    await content.initialize();
    source.add({
      'version': 1,
      'texts': {'signup.cid_help': 'first@example.com'}
    });
    source.add({
      'version': 2,
      'texts': {'signup.cid_help': 'second@example.com'}
    });
    await Future<void>.delayed(Duration.zero);
    expect(versions, [1]);
    firstWrite.complete();
    await lastWrite.future;
    expect(versions, [1, 2]);
    content.dispose();
    await source.close();
  });

  testWidgets(
      'only consumers of changed keys rebuild; fixed UI and photos stay independent',
      (tester) async {
    final counts = <String, int>{};
    AppContent.instance
        .applyDocument({'version': 1000, 'texts': {}, 'images': {}});
    await tester.pumpWidget(AppContentScope(
        child: MaterialApp(
            home: Scaffold(
                body: Column(children: [
      _Consumer('signup.cid_help', counts),
      _Consumer('contact.sonny_email_message', counts),
      _Consumer('portrait', counts, image: true),
      _Consumer('fixed', counts, fixed: true),
    ])))));
    expect(counts.values, everyElement(1));
    AppContent.instance.applyDocument({
      'version': 1001,
      'texts': {'signup.cid_help': 'new@example.com'},
      'images': {}
    });
    await tester.pump();
    expect(counts['signup.cid_help'], 2);
    expect(counts['contact.sonny_email_message'], 1);
    expect(counts['portrait'], 1);
    expect(counts['fixed'], 1);
    AppContent.instance.applyDocument({
      'version': 1002,
      'texts': {'signup.cid_help': 'new@example.com'},
      'images': {
        defaultAppImages['assets/icons/sonny_headshot.png']!: {
          'url': 'https://firebasestorage.googleapis.com/v0/b/test/o/photo',
          'contentType': 'image/png'
        }
      }
    });
    await tester.pump();
    expect(counts['signup.cid_help'], 2);
    expect(counts['portrait'], 2);
    expect(counts['fixed'], 1);
    // New version, identical visible content: zero rebuilds.
    AppContent.instance.applyDocument({
      'version': 1003,
      'texts': {'signup.cid_help': 'new@example.com'},
      'images': {
        defaultAppImages['assets/icons/sonny_headshot.png']!: {
          'url': 'https://firebasestorage.googleapis.com/v0/b/test/o/photo',
          'contentType': 'image/png'
        }
      }
    });
    await tester.pump();
    expect(counts['signup.cid_help'], 2);
    expect(counts['portrait'], 2);
  });
}

class _Consumer extends StatelessWidget {
  final String contentKey;
  final Map<String, int> counts;
  final bool image, fixed;
  const _Consumer(this.contentKey, this.counts,
      {this.image = false, this.fixed = false});
  @override
  Widget build(BuildContext context) {
    if (image) {
      AppContent.watchImage(context, 'assets/icons/sonny_headshot.png');
    } else if (!fixed) {
      AppContent.watch(context, keys: {contentKey});
    }
    counts.update(contentKey, (count) => count + 1, ifAbsent: () => 1);
    return Text(fixed || image ? contentKey : AppContent.text(contentKey));
  }
}
