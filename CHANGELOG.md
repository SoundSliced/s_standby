# Changelog

## 1.0.1

- **Fixed** cancellation reporting when reusing the same overlay id.
- **Fixed** cleanup dismissal guard so user-initiated dismissals are recorded reliably.
- **Added** optional `onCancel` callback to let callers stop their own work on dismissal.
- **Docs** Clarified border inset behavior and ensured examples remain up to date. 

## 1.0.0

- **Changed** `onDismissed` signature to include contextual result data:
  - `wasSuccessful` (`true`, `false`, or `null` when dismissed before completion)
  - `error` and `stackTrace` when the Future fails
- **Docs** Added README usage and callback semantics.
- **Added** `SStandby.dismiss(id)` for programmatic dismissal (cancels in-flight work).
- **Added** timeout support via `timeout` and optional `timeoutBuilder`.
- **Added** success auto-dismiss via `successAutoDismissAfter` (when using `successBuilder`).
- **Added** basic accessibility support (`semanticsLabel*`, `announceTransitions`).
- **Tests** Added widget tests covering success/error/cancel/timeout.
