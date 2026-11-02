import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_defaults.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults survive missing, blank, and malformed overrides', () {
    final content = AppContent();
    expect(content.resolveText('contact.support_email'),
        'carter@agqconsulting.com');
    expect(content.applyDocument({'version': 'bad'}), false);
    content.applyDocument({
      'version': 1,
      'texts': {'contact.support_email': ''}
    });
    expect(content.resolveText('contact.support_email'),
        'carter@agqconsulting.com');
  });
  test('templates preserve dynamic values and reject missing or extra tokens',
      () {
    final key = defaultAppText.keys
        .firstWhere((key) => defaultAppText[key]!.contains('{email}'));
    final content = AppContent();
    content.applyDocument({
      'version': 1,
      'texts': {key: 'Hello {email}'}
    });
    expect(content.resolveText(key, {'email': '{email}@example.com'}),
        'Hello {email}@example.com');
    content.applyDocument({
      'version': 2,
      'texts': {key: 'Hello'}
    });
    expect(content.resolveText(key, {'email': 'test@example.com'}),
        contains('test@example.com'));
    content.applyDocument({
      'version': 3,
      'texts': {key: 'Hello {email} {unknown}'}
    });
    expect(content.resolveText(key, {'email': 'test@example.com'}),
        isNot(contains('{unknown}')));
  });
  test(
      'old snapshots cannot overwrite newer content and reset restores defaults',
      () {
    final content = AppContent();
    content.applyDocument({
      'version': 2,
      'texts': {'contact.support_email': 'new@example.com'}
    });
    expect(content.applyDocument({'version': 1, 'texts': {}}), false);
    expect(content.resolveText('contact.support_email'), 'new@example.com');
    content.applyDocument({'version': 3, 'texts': {}});
    expect(content.resolveText('contact.support_email'),
        'carter@agqconsulting.com');
  });
  test(
      'images accept published storage URLs and reject unknown or unsafe sources',
      () {
    final content = AppContent();
    final key = defaultAppImages['assets/icons/sonny_headshot.png']!;
    content.applyDocument({
      'version': 1,
      'images': {
        key: {'url': 'http://example.com/x.png', 'contentType': 'image/png'}
      }
    });
    expect(content.imageFor('assets/icons/sonny_headshot.png'), null);
    content.applyDocument({
      'version': 2,
      'images': {
        key: {
          'url': 'https://firebasestorage.googleapis.com/v0/b/test/o/image',
          'contentType': 'image/png'
        }
      }
    });
    expect(content.imageFor('assets/icons/sonny_headshot.png')?['url'],
        contains('firebasestorage.googleapis.com'));
    content.applyDocument({'version': 3, 'images': {}});
    expect(content.imageFor('assets/icons/sonny_headshot.png'), null);
  });
  testWidgets('an open screen updates copy without resetting widget state',
      (tester) async {
    await tester.pumpWidget(
        AppContentScope(child: const MaterialApp(home: _CopyScreen())));
    expect(find.text('carter@agqconsulting.com'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    AppContent.instance.applyDocument({
      'version': 100,
      'texts': {'contact.support_email': 'changed@example.com'}
    });
    await tester.pump();
    expect(find.text('changed@example.com'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    AppContent.instance.applyDocument({'version': 101, 'texts': {}});
    await tester.pump();
  });
  testWidgets('bundled portrait renders without remote configuration',
      (tester) async {
    await tester.pumpWidget(AppContentScope(
        child: const MaterialApp(
            home: AppContentImage('assets/icons/sonny_headshot.png'))));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), null);
  });
}

class _CopyScreen extends StatefulWidget {
  const _CopyScreen();
  @override
  State<_CopyScreen> createState() => _CopyScreenState();
}

class _CopyScreenState extends State<_CopyScreen> {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    AppContent.watch(context);
    return Scaffold(
        body: Column(children: [
      Text(AppContent.text('contact.support_email')),
      Text('$count'),
      ElevatedButton(
          onPressed: () => setState(() => count++),
          child: const Text('Increment'))
    ]));
  }
}
