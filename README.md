# s_standby

A lightweight Flutter utility to show a progress overlay while a `Future` runs, with optional error/success builders.

## Features

- Shows a waiting overlay while a `Future` is pending
- Optional custom waiting, error, and success builders
- Customizable indicator, padding, and decoration
- Dismissible barrier support
- Unified `onDismissed` callback with contextual success/error data
- Optional `onCancel` callback to stop your own work on dismissal
- Programmatic dismissal via `SStandby.dismiss(id)`
- Optional timeout handling (`timeout`, `timeoutBuilder`)
- Optional auto-dismiss for success UI (`successAutoDismissAfter`)
- Optional accessibility semantics/announcements

## Example

![Example overlay](https://raw.githubusercontent.com/SoundSliced/s_standby/main/example/assets/example.gif)

## Note about borders looking “inset”

`s_standby` uses `pop_overlay` under the hood. By default, `pop_overlay` wraps your widget in a small “frame” that adds a tiny padding (`frameWidth`, default `0.5`) and clips the child. If your waiting/error/success UI draws a 1px border (e.g. `DecoratedBox` / `Container(decoration:)`) this can *look* like the border is inset from the popup bounds by ~0.5–1px.

To keep your custom decoration aligned with the visible popup bounds, `s_standby` sets `frameWidth: 0` (and disables the extra shadow) for its pop content.

## Usage

### Basic usage

```dart
SStandby.show<void>(
  future: myFuture,
  id: 'basic_save',
  title: 'Saving…',
  isDismissible: true,
  onDismissed: ({wasSuccessful, error, stackTrace}) {
    if (wasSuccessful == true) {
      // success
    } else if (wasSuccessful == false) {
      // error
      debugPrint('Error: $error');
    } else {
      // dismissed before completion
    }
  },
);
```

### Advanced usage

```dart
SStandby.show<void>(
  future: myFuture,
  id: 'save_user',
  title: 'Saving…',
  isDismissible: true,
  onCancel: () {
    // Stop your own work here (cancel subscription, abort request, etc.)
  },
  successBuilder: (context) => const Text('Saved!'),
  successAutoDismissAfter: const Duration(seconds: 1),
  timeout: const Duration(seconds: 10),
  timeoutBuilder: (context, error, stackTrace) => const Text('Timed out'),
  semanticsLabelWaiting: 'Saving user',
  semanticsLabelSuccess: 'Saved',
  announceTransitions: true,
  onDismissed: ({wasSuccessful, error, stackTrace}) {
    if (wasSuccessful == true) {
      // success
    } else if (wasSuccessful == false) {
      // error
      debugPrint('Error: $error');
    } else {
      // dismissed before completion
    }
  },
);
```

### Programmatic dismissal

```dart
SStandby.dismiss('save_user');
```

### `onDismissed` semantics

- `wasSuccessful == true` → Future completed successfully
- `wasSuccessful == false` → Future completed with error (see `error`/`stackTrace`)
- `wasSuccessful == null` → dismissed before completion (user cancelled)

## Compatibility

Version 1.0.1 contains fixes only — no breaking changes or deprecations.



See `example/lib/main.dart` for a full demo.
