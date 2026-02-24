// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

/// Implementation of `WKUIDelegate` that calls to Dart in callback methods.
class UIDelegateImpl: NSObject, WKUIDelegate, WKNavigationDelegate {
  let api: PigeonApiProtocolWKUIDelegate
  unowned let registrar: ProxyAPIRegistrar

  private var popupWebView: WKWebView?
  private weak var popupViewController: UIViewController?

  private static let iosVersionRegex = try? NSRegularExpression(
    pattern: "CPU (?:iPhone )?OS (\\d+)_(\\d+)")

  init(api: PigeonApiProtocolWKUIDelegate, registrar: ProxyAPIRegistrar) {
    self.api = api
    self.registrar = registrar
  }

  func webView(
    _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    let isJavaScriptInitiated = navigationAction.navigationType == .other

    registrar.dispatchOnMainThread { onFailure in
      self.api.onCreateWebView(
        pigeonInstance: self, webView: webView, configuration: configuration,
        navigationAction: navigationAction
      ) { result in
        if case .failure(let error) = result {
          onFailure("WKUIDelegate.onCreateWebView", error)
        }
      }
    }

    // Only create a native popup for JS-initiated window.open() calls (e.g. OAuth).
    // For user-initiated target="_blank" links, return nil so the Dart callback
    // can load the URL in the parent WebView instead.
    guard isJavaScriptInitiated else { return nil }

    let popup = WKWebView(frame: .zero, configuration: configuration)
    popup.uiDelegate = self
    popup.navigationDelegate = self
    popup.customUserAgent = UIDelegateImpl.sanitizedUserAgent(for: popup)
    self.popupWebView = popup

    DispatchQueue.main.async {
      let popupVC = UIViewController()
      popup.frame = popupVC.view.bounds
      popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      popupVC.view.addSubview(popup)
      popupVC.modalPresentationStyle = .pageSheet
      self.popupViewController = popupVC

      if let windowScene = webView.window?.windowScene,
         let rootVC = windowScene.keyWindow?.rootViewController {
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
          topVC = presented
        }
        topVC.present(popupVC, animated: true)
      }
    }

    return popup
  }

  /// Builds a sanitized UA from the WebView's default, adding the Version/X.X
  /// and Safari/604.1 tokens that WKWebView omits. This ensures Google OAuth
  /// compatibility regardless of what custom UA the parent WebView has.
  private static func sanitizedUserAgent(for webView: WKWebView) -> String? {
    guard let defaultUA = webView.value(forKey: "userAgent") as? String,
          !defaultUA.contains("Safari/") else {
      return webView.value(forKey: "userAgent") as? String
    }

    var version = "17.0"
    if let regex = iosVersionRegex,
       let match = regex.firstMatch(
         in: defaultUA, range: NSRange(defaultUA.startIndex..., in: defaultUA)),
       let r1 = Range(match.range(at: 1), in: defaultUA),
       let r2 = Range(match.range(at: 2), in: defaultUA) {
      version = "\(defaultUA[r1]).\(defaultUA[r2])"
    }

    return defaultUA
      .replacingOccurrences(of: "Mobile/", with: "Version/\(version) Mobile/")
      + " Safari/604.1"
  }

  func webViewDidClose(_ webView: WKWebView) {
    if webView == popupWebView {
      dismissPopup()
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    guard webView == popupWebView,
          let url = webView.url?.absoluteString else { return }

    // Google OAuth callback pages (gsi/transform, o/oauth2) post credentials
    // via postMessage and don't reliably call window.close(). Auto-dismiss
    // after a short delay so the credential reaches the opener.
    if url.contains("/gsi/") || url.contains("/o/oauth2/") {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.dismissPopup()
      }
    }
  }

  private func dismissPopup() {
    DispatchQueue.main.async {
      self.popupViewController?.dismiss(animated: true) {
        self.popupWebView = nil
        self.popupViewController = nil
      }
    }
  }

  #if compiler(>=6.0)
    @available(iOS 15.0, macOS 12.0, *)
    func webView(
      _ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
      initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
      decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
      let wrapperCaptureType: MediaCaptureType
      switch type {
      case .camera:
        wrapperCaptureType = .camera
      case .microphone:
        wrapperCaptureType = .microphone
      case .cameraAndMicrophone:
        wrapperCaptureType = .cameraAndMicrophone
      @unknown default:
        wrapperCaptureType = .unknown
      }

      registrar.dispatchOnMainThread { onFailure in
        self.api.requestMediaCapturePermission(
          pigeonInstance: self, webView: webView, origin: origin, frame: frame,
          type: wrapperCaptureType
        ) { result in
          DispatchQueue.main.async {
            switch result {
            case .success(let decision):
              switch decision {
              case .deny:
                decisionHandler(.deny)
              case .grant:
                decisionHandler(.grant)
              case .prompt:
                decisionHandler(.prompt)
              }
            case .failure(let error):
              decisionHandler(.deny)
              onFailure("WKUIDelegate.requestMediaCapturePermission", error)
            }
          }
        }
      }
    }
  #else
    @available(iOS 15.0, macOS 12.0, *)
    func webView(
      _ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
      initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
      decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
      let wrapperCaptureType: MediaCaptureType
      switch type {
      case .camera:
        wrapperCaptureType = .camera
      case .microphone:
        wrapperCaptureType = .microphone
      case .cameraAndMicrophone:
        wrapperCaptureType = .cameraAndMicrophone
      @unknown default:
        wrapperCaptureType = .unknown
      }

      registrar.dispatchOnMainThread { onFailure in
        self.api.requestMediaCapturePermission(
          pigeonInstance: self, webView: webView, origin: origin, frame: frame,
          type: wrapperCaptureType
        ) { result in
          DispatchQueue.main.async {
            switch result {
            case .success(let decision):
              switch decision {
              case .deny:
                decisionHandler(.deny)
              case .grant:
                decisionHandler(.grant)
              case .prompt:
                decisionHandler(.prompt)
              }
            case .failure(let error):
              decisionHandler(.deny)
              onFailure("WKUIDelegate.requestMediaCapturePermission", error)
            }
          }
        }
      }
    }
  #endif

  #if compiler(>=6.0)
    func webView(
      _ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
      initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor () -> Void
    ) {
      registrar.dispatchOnMainThread { onFailure in
        self.api.runJavaScriptAlertPanel(
          pigeonInstance: self, webView: webView, message: message, frame: frame
        ) { result in
          DispatchQueue.main.async {
            if case .failure(let error) = result {
              onFailure("WKUIDelegate.runJavaScriptAlertPanel", error)
            }
            completionHandler()
          }
        }
      }
    }
  #else
    func webView(
      _ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
      initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void
    ) {
      registrar.dispatchOnMainThread { onFailure in
        self.api.runJavaScriptAlertPanel(
          pigeonInstance: self, webView: webView, message: message, frame: frame
        ) { result in
          DispatchQueue.main.async {
            if case .failure(let error) = result {
              onFailure("WKUIDelegate.runJavaScriptAlertPanel", error)
            }
            completionHandler()
          }
        }
      }
    }
  #endif

  #if compiler(>=6.0)
    func webView(
      _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
      initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor (Bool) -> Void
    ) {
      registrar.dispatchOnMainThread { onFailure in
        self.api.runJavaScriptConfirmPanel(
          pigeonInstance: self, webView: webView, message: message, frame: frame
        ) { result in
          DispatchQueue.main.async {
            switch result {
            case .success(let confirmed):
              completionHandler(confirmed)
            case .failure(let error):
              completionHandler(false)
              onFailure("WKUIDelegate.runJavaScriptConfirmPanel", error)
            }
          }
        }
      }
    }
  #else
    func webView(
      _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
      initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void
    ) {
      registrar.dispatchOnMainThread { onFailure in
        self.api.runJavaScriptConfirmPanel(
          pigeonInstance: self, webView: webView, message: message, frame: frame
        ) { result in
          DispatchQueue.main.async {
            switch result {
            case .success(let confirmed):
              completionHandler(confirmed)
            case .failure(let error):
              completionHandler(false)
              onFailure("WKUIDelegate.runJavaScriptConfirmPanel", error)
            }
          }
        }
      }
    }
  #endif

  #if compiler(>=6.0)
    func webView(
      _ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
      defaultText: String?, initiatedByFrame frame: WKFrameInfo,
      completionHandler: @escaping @MainActor (String?) -> Void
    ) {
      registrar.dispatchOnMainThread { onFailure in
        self.api.runJavaScriptTextInputPanel(
          pigeonInstance: self, webView: webView, prompt: prompt, defaultText: defaultText,
          frame: frame
        ) { result in
          DispatchQueue.main.async {
            switch result {
            case .success(let response):
              completionHandler(response)
            case .failure(let error):
              completionHandler(nil)
              onFailure("WKUIDelegate.runJavaScriptTextInputPanel", error)
            }
          }
        }
      }
    }
  #else
    func webView(
      _ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
      defaultText: String?, initiatedByFrame frame: WKFrameInfo,
      completionHandler: @escaping (String?) -> Void
    ) {
      registrar.dispatchOnMainThread { onFailure in
        self.api.runJavaScriptTextInputPanel(
          pigeonInstance: self, webView: webView, prompt: prompt, defaultText: defaultText,
          frame: frame
        ) { result in
          DispatchQueue.main.async {
            switch result {
            case .success(let response):
              completionHandler(response)
            case .failure(let error):
              completionHandler(nil)
              onFailure("WKUIDelegate.runJavaScriptTextInputPanel", error)
            }
          }
        }
      }
    }
  #endif
}

/// ProxyApi implementation for `WKUIDelegate`.
///
/// This class may handle instantiating native object instances that are attached to a Dart instance
/// or handle method calls on the associated native class or an instance of that class.
class UIDelegateProxyAPIDelegate: PigeonApiDelegateWKUIDelegate {
  func pigeonDefaultConstructor(pigeonApi: PigeonApiWKUIDelegate) throws -> WKUIDelegate {
    return UIDelegateImpl(
      api: pigeonApi, registrar: pigeonApi.pigeonRegistrar as! ProxyAPIRegistrar)
  }
}
