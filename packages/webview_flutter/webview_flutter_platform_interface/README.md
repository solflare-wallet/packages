# webview_flutter_platform_interface

A common platform interface for the [`webview_flutter`](https://pub.dev/packages/webview_flutter) plugin.

This interface allows platform-specific implementations of the `webview_flutter`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.

## Solflare Fork

This is a fork of the official `webview_flutter_platform_interface` package maintained by [Solflare](https://github.com/solflare-wallet).

### Why This Fork Exists

This fork adds the `ProcessTerminationDetails` type and `setOnWebViewRenderProcessTerminated` method to support Android render process crash detection across the WebView plugin stack.

### Custom Types

| Type | Description |
|------|-------------|
| `ProcessTerminationDetails` | Contains `didCrash` (boolean) and `rendererPriorityAtExit` (int) for render process termination info |

### Related Packages

This fork works together with:
- [`webview_flutter`](https://github.com/solflare-wallet/packages/tree/main/packages/webview_flutter/webview_flutter) - Main package
- [`webview_flutter_android`](https://github.com/solflare-wallet/packages/tree/main/packages/webview_flutter/webview_flutter_android) - Android implementation
- [`webview_flutter_wkwebview`](https://github.com/solflare-wallet/packages/tree/main/packages/webview_flutter/webview_flutter_wkwebview) - iOS/macOS implementation

---

# Usage

To implement a new platform-specific implementation of `webview_flutter`, extend
[`WebviewPlatform`](lib/src/webview_platform.dart) with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`WebviewPlatform` by calling
`WebviewPlatform.instance = MyPlatformWebview()`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.
