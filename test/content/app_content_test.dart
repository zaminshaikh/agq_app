import 'package:agq_app/content/app_content.dart';
import 'package:agq_app/content/content_defaults.dart';
import 'package:agq_app/content/content_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults survive missing, blank, and malformed overrides', () {
    final content = AppContent();
    expect(content.resolveText('signup.cid_help'),
        defaultAppText['signup.cid_help']);
    expect(content.applyDocument({'version': 'bad'}), false);
    content.applyDocument({
      'version': 1,
      'texts': {'signup.cid_help': ''}
    });
    expect(content.resolveText('signup.cid_help'),
        defaultAppText['signup.cid_help']);
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
      'texts': {'signup.cid_help': 'new@example.com'}
    });
    expect(content.applyDocument({'version': 1, 'texts': {}}), false);
    expect(content.resolveText('signup.cid_help'), 'new@example.com');
    content.applyDocument({'version': 3, 'texts': {}});
    expect(content.resolveText('signup.cid_help'),
        defaultAppText['signup.cid_help']);
  });
  test(
      'legacy split contact resolves into complete text and new text takes precedence',
      () {
    final content = AppContent();
    content.applyDocument({
      'version': 1,
      'texts': {
        'text.screens.authenticate.create_account.create_account.your_client_id_number_cid_is_an_8_digi_1450b8':
            'Please contact {supportEmail} for your code.',
        'contact.support_email': 'custom@example.com'
      }
    });
    expect(content.resolveText('signup.cid_help'),
        'Please contact custom@example.com for your code.');
    content.applyDocument({
      'version': 2,
      'texts': {
        'signup.cid_help': 'Contact the team at next@example.com.',
        'contact.support_email': 'old@example.com'
      }
    });
    expect(content.resolveText('signup.cid_help'),
        'Contact the team at next@example.com.');
  });
  test(
      'contact actions use the same full line and reject missing or ambiguous destinations',
      () {
    final content = AppContent();
    content.applyDocument({
      'version': 1,
      'texts': {
        'contact.sonny_email_message': 'Write to new@example.com for help.',
        'contact.sonny_phone_message': 'Call us: +1 (555) 123-4567',
      }
    });
    expect(content.resolveContactTarget('contact.sonny_email_message'),
        'new@example.com');
    expect(content.resolveContactTarget('contact.sonny_phone_message'),
        '+15551234567');
    content.applyDocument({
      'version': 2,
      'texts': {
        'contact.sonny_email_message': 'No address here',
        'contact.sonny_phone_message': 'Call 555-123-4567 or 555-111-2222',
      }
    });
    expect(content.resolveContactTarget('contact.sonny_email_message'),
        'sonny@agqconsulting.com');
    expect(content.resolveContactTarget('contact.sonny_phone_message'),
        '+16314879818');
    content.applyDocument({
      'version': 3,
      'texts': {
        'text.screens.profile.pages.help.email_sonny_agqconsulting_com_58c8a4':
            'Email the team: {email}',
        'contact.sonny_email': 'custom@example.com',
      }
    });
    expect(content.resolveText('contact.sonny_email_message'),
        'Email the team: custom@example.com');
    expect(content.resolveContactTarget('contact.sonny_email_message'),
        'custom@example.com');
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
  test('fixed buttons, chart labels and logos ignore old remote overrides', () {
    final content = AppContent();
    final fixedLabels = [
      'Logout',
      'No accounts',
      'No clients available',
      'Asset Timeline',
      'Last Week',
      'Last Month',
      'Last Year'
    ];
    final keys = defaultAppText.keys
        .where((key) => fixedLabels.contains(defaultAppText[key]))
        .toList();
    expect(keys.length, greaterThanOrEqualTo(fixedLabels.length));
    content.applyDocument({
      'version': 1,
      'texts': {for (final key in keys) key: 'Changed'},
      'images': {
        'image.agq_logo_png': {
          'url': 'https://firebasestorage.googleapis.com/v0/b/test/o/logo',
          'contentType': 'image/png'
        },
      }
    });
    for (final key in keys) {
      expect(content.resolveText(key), defaultAppText[key]);
    }
    expect(content.imageFor('assets/icons/agq_logo.png'), null);
    expect(defaultAppImages.length, 2);
    expect(
        configurableAppText.any((key) =>
            defaultAppText[key]!.startsWith('The connection is taking longer')),
        true);
  });
  testWidgets('an open screen updates copy without resetting widget state',
      (tester) async {
    await tester.pumpWidget(
        const AppContentScope(child: MaterialApp(home: _CopyScreen())));
    expect(find.text(defaultAppText['signup.cid_help']!), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    AppContent.instance.applyDocument({
      'version': 100,
      'texts': {'signup.cid_help': 'changed@example.com'}
    });
    await tester.pump();
    expect(find.text('changed@example.com'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    AppContent.instance.applyDocument({'version': 101, 'texts': {}});
    await tester.pump();
  });
  testWidgets('bundled portrait renders without remote configuration',
      (tester) async {
    await tester.pumpWidget(const AppContentScope(
        child: MaterialApp(
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
      Text(AppContent.text('signup.cid_help')),
      Text('$count'),
      ElevatedButton(
          onPressed: () => setState(() => count++),
          child: const Text('Increment'))
    ]));
  }
}
