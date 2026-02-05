# webview\_flutter\_wkwebview

The Apple WKWebView implementation of [`webview_flutter`][1].

## Solflare Fork

This is a fork of the official `webview_flutter_wkwebview` package maintained by [Solflare](https://github.com/solflare-wallet).

### Why This Fork Exists

This fork adds the `addUserScript` method for injecting JavaScript at document start, before the page loads. This is essential for:

- **Wallet bridge injection** - Inject provider scripts before page JavaScript runs
- **Window object modification** - Set up `window` properties before any page code executes
- **Communication channels** - Establish native-to-web bridges early

### Custom Features

| Feature | Description |
|---------|-------------|
| `addUserScript(String script)` | Injects JavaScript at document start on all frames |

### Usage

```dart
if (controller.platform is WebKitWebViewController) {
  await (controller.platform as WebKitWebViewController).addUserScript('''
    window.solflare = { ready: true };
  ''');
}
```

### Related Packages

This fork works together with:
- [`webview_flutter`](https://github.com/solflare-wallet/packages/tree/main/packages/webview_flutter/webview_flutter) - Main package
- [`webview_flutter_platform_interface`](https://github.com/solflare-wallet/packages/tree/main/packages/webview_flutter/webview_flutter_platform_interface) - Shared types

---

## Usage

This package is [endorsed][2], which means you can simply use `webview_flutter`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you
should add it to your `pubspec.yaml` as usual.

### External Native API

The plugin also provides a native API accessible by the native code of iOS applications or packages.
This API follows the convention of breaking changes of the Dart API, which means that any changes to
the class that are not backwards compatible will only be made with a major version change of the
plugin. Native code other than this external API does not follow breaking change conventions, so
app or plugin clients should not use any other native APIs.

The API can be accessed by importing the native plugin `webview_flutter_wkwebview`:

Objective-C:

```objectivec
@import webview_flutter_wkwebview;
```

Then you will have access to the native class `FWFWebViewFlutterWKWebViewExternalAPI`.

## Contributing

For information on contributing to this plugin, see [`CONTRIBUTING.md`](CONTRIBUTING.md).

[1]: https://pub.dev/packages/webview_flutter
[2]: https://flutter.dev/to/endorsed-federated-plugin
