import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:pop_overlay/pop_overlay.dart';
import 'package:ticker_free_circular_progress_indicator/ticker_free_circular_progress_indicator.dart';

/// Overlay utility to show a progress indicator while a Future is running.
///
/// The provided [future] is wrapped in a [CancelableOperation] internally so
/// that dismissing the overlay (background tap or programmatic dismissal) will
/// attempt to cancel the underlying computation.
///
/// The [onDismissed] callback reports how the overlay ended:
/// - `wasSuccessful == true`  : Future completed successfully
/// - `wasSuccessful == false` : Future completed with error (see `error`/`stackTrace`)
/// - `wasSuccessful == null`  : dismissed before completion (user cancelled)
class SStandby {
  static final Map<String, CancelableOperation<Object?>> _operationsById =
      <String, CancelableOperation<Object?>>{};
  static final Map<String, VoidCallback> _fireOnDismissedById =
      <String, VoidCallback>{};

  // Guard to ensure we only notify once, even if pop_overlay triggers multiple
  // dismissal paths.
  static final Set<String> _dismissedOverlayIds = <String>{};

  static void show<T>({
    required Future<T> future,
    required String id,
    FutureOr<void> Function()? onCancel,
    void Function({
      bool? wasSuccessful,
      Object? error,
      StackTrace? stackTrace,
    })? onDismissed,
    String? title,
    bool isDismissible = true,
    double dismissibleBarrierOpacity = 0.5,
    WidgetBuilder? waitingBuilder,
    Widget Function(
            BuildContext context, Object? error, StackTrace? stackTrace)?
        errorBuilder,
    WidgetBuilder? successBuilder,
    bool successDismissible = true,

    /// If provided and [successBuilder] is used, the success UI will auto-dismiss
    /// after this duration.
    Duration? successAutoDismissAfter,

    /// If provided, the [future] will be wrapped with [Future.timeout].
    Duration? timeout,

    /// Optional builder specifically for timeout errors.
    Widget Function(
            BuildContext context, Object? error, StackTrace? stackTrace)?
        timeoutBuilder,

    /// Customize default waiting wrapper.
    Decoration? waitingDecoration,
    EdgeInsetsGeometry waitingPadding = const EdgeInsets.all(8.0),

    /// Customize default error wrapper.
    Decoration? errorDecoration,
    EdgeInsetsGeometry errorPadding = const EdgeInsets.all(8.0),

    /// Accessibility.
    String? semanticsLabelWaiting,
    String? semanticsLabelError,
    String? semanticsLabelSuccess,
    bool announceTransitions = false,

    /// Indicator customization.
    double indicatorSize = 20,
    double indicatorStrokeWidth = 3,
    Color? indicatorColor,
    Widget? indicator,
  }) {
    final String overlayId = _overlayIdFor(id);

    // If the caller reuses an id, clean up any prior state.
    _dismissInternal(id, reason: 'cleanup');
    // Reset dismissal guard for the new overlay instance.
    _dismissedOverlayIds.remove(overlayId);

    bool hasFiredUserOnDismissed = false;
    bool? completionResult;
    Object? completionError;
    StackTrace? completionStackTrace;

    void fireUserOnDismissed() {
      if (hasFiredUserOnDismissed) return;
      hasFiredUserOnDismissed = true;
      onDismissed?.call(
        wasSuccessful: completionResult,
        error: completionError,
        stackTrace: completionStackTrace,
      );
    }

    Future<T> effectiveFuture = future;
    if (timeout != null) {
      effectiveFuture = future.timeout(timeout);
    }

    final cancelable = CancelableOperation<T>.fromFuture(
      effectiveFuture,
      onCancel: () {
        onCancel?.call();
        fireUserOnDismissed();
      },
    );

    _operationsById[id] = cancelable as CancelableOperation<Object?>;
    _fireOnDismissedById[id] = fireUserOnDismissed;

    // Capture completion for later dismissal reporting.
    cancelable.value.then((_) {
      completionResult = true;
      // Ensure callback arrives even if the overlay isn't actually removed.
      fireUserOnDismissed();
    }).catchError((error, stackTrace) {
      completionResult = false;
      completionError = error;
      completionStackTrace = stackTrace;
      // Ensure callback arrives even if the overlay isn't actually removed.
      fireUserOnDismissed();
    });

    final bool shouldDismissOnBarrier =
        isDismissible || errorBuilder != null || successDismissible;

    bool hasAutoDismissScheduled = false;
    bool hasAnnouncedWaiting = false;
    bool hasAnnouncedError = false;
    bool hasAnnouncedSuccess = false;

    PopOverlay.addPop(
      PopOverlayContent(
        id: overlayId,
        // pop_overlay's default non-template wrapper adds a frame with
        // `frameWidth` padding (default is 0.5) and clips child content.
        // When callers draw a 1px border inside their widget (DecoratedBox,
        // Container decoration, etc.) this can look like the border is inset
        // from the popup bounds by ~0.5–1px.
        //
        // We neutralize that wrapper by removing the frame padding and
        // shadow so the widget we provide defines the visible bounds.
        frameColor: Colors.white.withValues(alpha: 0.8),
        frameWidth: 0,
        hasBoxShadow: false,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        dismissBarrierColor:
            Colors.black.withValues(alpha: dismissibleBarrierOpacity),
        shouldDismissOnBackgroundTap: shouldDismissOnBarrier,
        widget: FutureBuilder<T>(
          future: cancelable.value,
          builder: (context, snapshot) {
            final scheme = Theme.of(context).colorScheme;
            final Color surface = scheme.surface;
            final Color onSurface = scheme.onSurface;
            final Decoration resolvedWaitingDecoration = waitingDecoration ??
                BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                );
            final Decoration resolvedErrorDecoration = errorDecoration ??
                BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                );
            final Widget resolvedIndicator = indicator ??
                SizedBox(
                  height: indicatorSize,
                  width: indicatorSize,
                  child: TickerFreeCircularProgressIndicator(
                    strokeWidth: indicatorStrokeWidth,
                    color: indicatorColor ?? scheme.primary,
                  ),
                );

            if (snapshot.connectionState == ConnectionState.waiting) {
              if (announceTransitions &&
                  semanticsLabelWaiting != null &&
                  !hasAnnouncedWaiting) {
                // Some Flutter SDKs expose SemanticsService.announce, others do
                // not depending on version/channel. We still provide semantics
                // labels regardless; announcements are best-effort.
                hasAnnouncedWaiting = true;
              }

              if (waitingBuilder != null) {
                return waitingBuilder(context);
              }

              return Center(
                child: Semantics(
                  label: semanticsLabelWaiting ?? title,
                  container: true,
                  liveRegion: announceTransitions,
                  child: DecoratedBox(
                    decoration: resolvedWaitingDecoration,
                    child: Padding(
                      padding: waitingPadding,
                      child: Column(
                        children: [
                          if (title != null) ...[
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          resolvedIndicator,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              completionResult ??= false;
              completionError ??= snapshot.error;
              completionStackTrace ??= snapshot.stackTrace;

              final bool isTimeout = completionError is TimeoutException;

              if (announceTransitions && !hasAnnouncedError) {
                hasAnnouncedError = true;
              }

              if (isTimeout && timeoutBuilder != null) {
                return timeoutBuilder(
                  context,
                  snapshot.error,
                  snapshot.stackTrace,
                );
              }

              if (errorBuilder != null) {
                return errorBuilder(
                  context,
                  snapshot.error,
                  snapshot.stackTrace,
                );
              }

              return Semantics(
                label:
                    semanticsLabelError ?? (isTimeout ? 'Timed out' : 'Error'),
                container: true,
                liveRegion: announceTransitions,
                child: DecoratedBox(
                  decoration: resolvedErrorDecoration,
                  child: Padding(
                    padding: errorPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          isTimeout ? 'Timed out' : 'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            dismiss(id);
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Success.
            completionResult ??= true;

            if (successBuilder != null) {
              if (announceTransitions &&
                  semanticsLabelSuccess != null &&
                  !hasAnnouncedSuccess) {
                hasAnnouncedSuccess = true;
              }

              if (successAutoDismissAfter != null && !hasAutoDismissScheduled) {
                hasAutoDismissScheduled = true;
                Future.delayed(successAutoDismissAfter, () {
                  dismiss(id);
                });
              }

              return Semantics(
                label: semanticsLabelSuccess,
                container: true,
                liveRegion: announceTransitions,
                child: successBuilder(context),
              );
            }

            // If no success builder, dismiss immediately.
            Future.microtask(() {
              dismiss(id);
            });
            return const SizedBox.shrink();
          },
        ),
        onDismissed: () {
          // Called when overlay is removed (background tap or programmatically).
          // Ensure we report once.
          if (_dismissedOverlayIds.contains(overlayId)) return;
          _dismissedOverlayIds.add(overlayId);

          _operationsById.remove(id);
          _fireOnDismissedById.remove(id);
          fireUserOnDismissed();
          cancelable.cancel();
        },
      ),
    );
  }

  static void hide(String id) => dismiss(id);

  /// Dismiss the overlay if present, and cancel the in-flight operation (if any).
  static void dismiss(String id) {
    _dismissInternal(id, reason: 'api');
  }

  static void _dismissInternal(String id, {required String reason}) {
    final String overlayId = _overlayIdFor(id);

    final bool hasOperation = _operationsById.containsKey(id);
    final bool hasActiveOverlay = PopOverlay.isActiveById(overlayId);

    if (!hasOperation && !hasActiveOverlay) {
      // Nothing to dismiss; avoid marking as dismissed so future overlays
      // with the same id can still report their callbacks.
      return;
    }

    final op = _operationsById.remove(id);
    op?.cancel();

    // In some environments (notably widget tests), pop_overlay may not invoke
    // PopOverlayContent.onDismissed. Make programmatic dismissal deterministic
    // by firing the callback here as well (guarded by overlayId).
    if (!_dismissedOverlayIds.contains(overlayId)) {
      _dismissedOverlayIds.add(overlayId);
      final fire = _fireOnDismissedById.remove(id);
      fire?.call();
    } else {
      _fireOnDismissedById.remove(id);
    }

    PopOverlay.removePop(overlayId);
  }

  static String _overlayIdFor(String id) => 'awaitOverlay_$id';
}
