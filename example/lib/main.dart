import 'package:flutter/material.dart';
import 'package:s_standby/s_standby.dart';

void main() {
  runApp(const StandbyExampleApp());
}

class StandbyExampleApp extends StatelessWidget {
  const StandbyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 's_standby Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StandbyHomePage(),
    );
  }
}

class StandbyHomePage extends StatefulWidget {
  const StandbyHomePage({super.key});

  @override
  State<StandbyHomePage> createState() => _StandbyHomePageState();
}

class _StandbyHomePageState extends State<StandbyHomePage> {
  bool _isBusy = false;
  bool _isDismissible = true;
  bool _announceTransitions = false;
  String _lastResult = 'No result yet';

  void _handleDismiss({
    bool? wasSuccessful,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!mounted) return;

    String message;
    if (wasSuccessful == true) {
      message = 'Dismissed after success';
    } else if (wasSuccessful == false) {
      message = 'Dismissed after error: $error';
    } else {
      message = 'Dismissed before completion';
    }

    setState(() {
      _isBusy = false;
      _lastResult = message;
    });
  }

  void _handleCancel(String source) {
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _lastResult = 'Cancelled by user ($source)';
    });
  }

  Future<void> _runSuccessDemo() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final future = Future<void>.delayed(const Duration(seconds: 2));
    SStandby.show(
      isDismissible: _isDismissible,
      onDismissed: _handleDismiss,
      onCancel: () => _handleCancel('success demo'),
      future: future,
      id: 'success_demo',
      title: 'Working on it…',
    );
  }

  Future<void> _runErrorDemo() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final future = Future<void>.delayed(const Duration(seconds: 2), () {
      throw Exception('Something went wrong');
    });

    SStandby.show<void>(
      future: future,
      onDismissed: _handleDismiss,
      onCancel: () => _handleCancel('error demo'),
      id: 'error_demo',
      title: 'Processing…',
      isDismissible: _isDismissible,
    );
  }

  Future<void> _runCustomDemo() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final future = Future<void>.delayed(const Duration(seconds: 2), () {
      throw Exception('Custom error');
    });

    SStandby.show<void>(
      future: future,
      onDismissed: _handleDismiss,
      onCancel: () => _handleCancel('custom demo'),
      id: 'custom_demo',
      title: 'Customizing…',
      isDismissible: _isDismissible,
      dismissibleBarrierOpacity: 0.35,
      indicatorSize: 28,
      indicatorStrokeWidth: 4,
      indicatorColor: Colors.deepPurple,
      waitingDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      waitingPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      errorDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1.2),
      ),
      errorPadding: const EdgeInsets.all(16),
      errorBuilder: (context, error, stackTrace) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Custom error: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap outside to dismiss.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runSuccessPopDemo() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final future = Future<void>.delayed(const Duration(seconds: 2));

    SStandby.show<void>(
      future: future,
      id: 'success_pop_demo',
      title: 'Saving…',
      isDismissible: _isDismissible,
      successDismissible: _isDismissible,
      onDismissed: _handleDismiss,
      onCancel: () => _handleCancel('success pop demo'),
      successBuilder: (context) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Saved successfully!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _dismissCurrent() {
    // For demo purposes we dismiss any known overlay ids.
    for (final id in <String>[
      'success_demo',
      'error_demo',
      'custom_demo',
      'success_pop_demo',
      'timeout_demo',
      'auto_success_demo',
    ]) {
      SStandby.dismiss(id);
    }
  }

  Future<void> _runTimeoutDemo() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    SStandby.show<void>(
      id: 'timeout_demo',
      future: Future<void>.delayed(const Duration(seconds: 5)),
      timeout: const Duration(seconds: 1),
      isDismissible: _isDismissible,
      announceTransitions: _announceTransitions,
      semanticsLabelWaiting: 'Working…',
      semanticsLabelError: 'Timed out',
      onDismissed: _handleDismiss,
      onCancel: () => _handleCancel('timeout demo'),
      timeoutBuilder: (context, error, stackTrace) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red, width: 1.2),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_off, color: Colors.red, size: 40),
                SizedBox(height: 12),
                Text('Timed out (custom UI)'),
                SizedBox(height: 12),
                Text('Tap outside or use Dismiss button.'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runAutoDismissSuccessDemo() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    SStandby.show<void>(
      id: 'auto_success_demo',
      future: Future<void>.delayed(const Duration(seconds: 2)),
      title: 'Finishing…',
      isDismissible: _isDismissible,
      announceTransitions: _announceTransitions,
      semanticsLabelWaiting: 'Finishing',
      semanticsLabelSuccess: 'Done',
      onDismissed: _handleDismiss,
      onCancel: () => _handleCancel('auto-dismiss demo'),
      successBuilder: (context) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 1.2),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('All set! (auto dismiss in 1s)'),
              ],
            ),
          ),
        );
      },
      successAutoDismissAfter: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('s_standby Example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tap a button to show the overlay while a Future runs.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dismissible overlay'),
                subtitle: const Text('Allow tap outside to dismiss'),
                value: _isDismissible,
                onChanged: _isBusy
                    ? null
                    : (value) {
                        setState(() => _isDismissible = value);
                      },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Announce transitions'),
                subtitle: const Text('Accessibility / screen reader friendly'),
                value: _announceTransitions,
                onChanged: _isBusy
                    ? null
                    : (value) {
                        setState(() => _announceTransitions = value);
                      },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isBusy ? null : _runSuccessDemo,
                child: const Text('Run success demo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isBusy ? null : _runErrorDemo,
                child: const Text('Run error demo'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isBusy ? null : _runCustomDemo,
                child: const Text('Run custom demo'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _isBusy ? null : _runSuccessPopDemo,
                child: const Text('Run success pop demo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isBusy ? null : _runAutoDismissSuccessDemo,
                child: const Text('Run auto-dismiss success demo'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isBusy ? null : _runTimeoutDemo,
                child: const Text('Run timeout demo'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isBusy ? _dismissCurrent : null,
                child: const Text('Dismiss overlay (programmatic)'),
              ),
              const SizedBox(height: 12),
              Text(
                _isBusy ? 'Overlay running…' : 'Idle',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _lastResult,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
