import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s_standby/s_standby.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SStandby', () {
    Future<void> pumpHost(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('host'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('reports success and auto dismisses without successBuilder',
        (tester) async {
      await pumpHost(tester);

      final completer = Completer<void>();
      bool? dismissedWasSuccessful;

      SStandby.show<void>(
        id: 't_success',
        future: completer.future,
        title: 'Working',
        onDismissed: ({wasSuccessful, error, stackTrace}) {
          dismissedWasSuccessful = wasSuccessful;
        },
      );

      completer.complete();
      await tester.pump();
      await tester.pump(); // allow microtask dismiss
      await tester.pump(const Duration(milliseconds: 500));

      expect(dismissedWasSuccessful, isTrue);
    });

    testWidgets('shows successBuilder and dismisses programmatically',
        (tester) async {
      await pumpHost(tester);

      final completer = Completer<void>();
      bool? dismissedWasSuccessful;

      SStandby.show<void>(
        id: 't_success_ui',
        future: completer.future,
        successBuilder: (context) => const Text('Yay'),
        onDismissed: ({wasSuccessful, error, stackTrace}) {
          dismissedWasSuccessful = wasSuccessful;
        },
      );

      completer.complete();
      await tester.pump();

      SStandby.dismiss('t_success_ui');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(dismissedWasSuccessful, isTrue);
    });

    testWidgets('reports error when future fails', (tester) async {
      await pumpHost(tester);

      final completer = Completer<void>();
      bool? dismissedWasSuccessful;
      Object? dismissedError;

      SStandby.show<void>(
        id: 't_error',
        future: completer.future,
        onDismissed: ({wasSuccessful, error, stackTrace}) {
          dismissedWasSuccessful = wasSuccessful;
          dismissedError = error;
        },
      );

      completer.completeError(StateError('boom'));
      await tester.pump();

      // Dismiss programmatically.
      SStandby.dismiss('t_error');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(dismissedWasSuccessful, isFalse);
      expect(dismissedError, isA<StateError>());
    });

    testWidgets('reports timeout as error and uses timeoutBuilder',
        (tester) async {
      await pumpHost(tester);

      bool? dismissedWasSuccessful;
      Object? dismissedError;

      final completer = Completer<void>();

      SStandby.show<void>(
        id: 't_timeout',
        future: completer.future,
        timeout: const Duration(milliseconds: 10),
        timeoutBuilder: (context, e, st) => const Text('Timed out UI'),
        onDismissed: ({wasSuccessful, error, stackTrace}) {
          dismissedWasSuccessful = wasSuccessful;
          dismissedError = error;
        },
      );

      // Allow timeout to fire.
      await tester.pump(const Duration(milliseconds: 20));

      SStandby.dismiss('t_timeout');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(dismissedWasSuccessful, isFalse);
      expect(dismissedError, isA<TimeoutException>());
    });

    testWidgets('reports null when dismissed before completion',
        (tester) async {
      await pumpHost(tester);

      final completer = Completer<void>();
      bool? dismissedWasSuccessful;

      SStandby.show<void>(
        id: 't_cancel',
        future: completer.future,
        title: 'Waiting',
        onDismissed: ({wasSuccessful, error, stackTrace}) {
          dismissedWasSuccessful = wasSuccessful;
        },
      );

      SStandby.dismiss('t_cancel');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(dismissedWasSuccessful, isNull);
    });

    testWidgets('auto dismisses successBuilder after duration', (tester) async {
      await pumpHost(tester);

      final completer = Completer<void>();
      bool? dismissedWasSuccessful;

      SStandby.show<void>(
        id: 't_auto_success',
        future: completer.future,
        successBuilder: (context) => const Text('Done'),
        successAutoDismissAfter: const Duration(milliseconds: 50),
        onDismissed: ({wasSuccessful, error, stackTrace}) {
          dismissedWasSuccessful = wasSuccessful;
        },
      );

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(dismissedWasSuccessful, isTrue);
    });

    testWidgets('onDismissed fires only once', (tester) async {
      await pumpHost(tester);

      final completer = Completer<void>();
      var count = 0;

      SStandby.show<void>(
        id: 't_once',
        future: completer.future,
        title: 'Once',
        onDismissed: ({wasSuccessful, error, stackTrace}) {
          count++;
        },
      );

      // Dismiss twice.
      SStandby.dismiss('t_once');
      SStandby.dismiss('t_once');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(count, 1);
    });
  });
}
