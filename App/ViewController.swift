import UIKit
import WebKit
import AVFoundation

final class ViewController: UIViewController,
                            WKNavigationDelegate,
                            WKUIDelegate {

    private var webView: WKWebView!
    private var fullscreenButton: UIButton!
    private var isLandscapeMode = false

    private let startURL = URL(
        string: "https://dragoplayer.in/"
    )!

    override var supportedInterfaceOrientations:
        UIInterfaceOrientationMask {

        return .all
    }

    override var preferredInterfaceOrientationForPresentation:
        UIInterfaceOrientation {

        return isLandscapeMode ? .landscapeRight : .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        configureWebView()
        configureFullscreenButton()

        loadWebsite()
    }

    private func configureWebView() {

        let configuration = WKWebViewConfiguration()

        configuration.allowsInlineMediaPlayback = true

        if #available(iOS 15.0, *) {
            configuration.mediaTypesRequiringUserActionForPlayback = []
        }

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        configuration.defaultWebpagePreferences = preferences

        webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        webView.translatesAutoresizingMaskIntoConstraints = false

        webView.navigationDelegate = self
        webView.uiDelegate = self

        webView.allowsBackForwardNavigationGestures = true

        webView.scrollView.contentInsetAdjustmentBehavior = .never

        webView.backgroundColor = .black
        webView.isOpaque = false

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),

            webView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),

            webView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),

            webView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
    }

    private func configureFullscreenButton() {

        fullscreenButton = UIButton(type: .system)

        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false

        fullscreenButton.setTitle(
            "⛶",
            for: .normal
        )

        fullscreenButton.titleLabel?.font =
            UIFont.systemFont(
                ofSize: 28,
                weight: .bold
            )

        fullscreenButton.tintColor = .white

        fullscreenButton.backgroundColor =
            UIColor.black.withAlphaComponent(0.65)

        fullscreenButton.layer.cornerRadius = 25

        fullscreenButton.clipsToBounds = true

        fullscreenButton.addTarget(
            self,
            action: #selector(toggleFullscreen),
            for: .touchUpInside
        )

        view.addSubview(fullscreenButton)

        NSLayoutConstraint.activate([

            fullscreenButton.widthAnchor.constraint(
                equalToConstant: 50
            ),

            fullscreenButton.heightAnchor.constraint(
                equalToConstant: 50
            ),

            fullscreenButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -14
            ),

            fullscreenButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -14
            )
        ])
    }

    private func loadWebsite() {

        let request = URLRequest(
            url: startURL,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 60
        )

        webView.load(request)
    }

    @objc
    private func toggleFullscreen() {

        if isLandscapeMode {

            exitLandscape()

        } else {

            enterLandscape()
        }
    }

    private func enterLandscape() {

        isLandscapeMode = true

        fullscreenButton.setTitle(
            "⤢",
            for: .normal
        )

        forceOrientation(
            .landscapeRight
        )

        requestVideoFullscreen()
    }

    private func exitLandscape() {

        isLandscapeMode = false

        fullscreenButton.setTitle(
            "⛶",
            for: .normal
        )

        exitVideoFullscreen()

        forceOrientation(
            .portrait
        )
    }

    private func forceOrientation(
        _ orientation: UIInterfaceOrientation
    ) {

        guard
            let windowScene = view.window?.windowScene
        else {
            return
        }

        if #available(iOS 16.0, *) {

            let preferences =
                UIWindowScene.GeometryPreferences.iOS(
                    interfaceOrientations:
                        orientation == .portrait
                        ? .portrait
                        : .landscapeRight
                )

            windowScene.requestGeometryUpdate(
                preferences
            ) { error in

                if let error = error {
                    print(
                        "Orientation error: \(error)"
                    )
                }
            }

            setNeedsUpdateOfSupportedInterfaceOrientations()

        } else {

            UIDevice.current.setValue(
                orientation.rawValue,
                forKey: "orientation"
            )

            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private func requestVideoFullscreen() {

        let javascript = """
        (() => {
            const videos = document.querySelectorAll('video');

            if (videos.length === 0) {
                return;
            }

            const video = videos[videos.length - 1];

            video.setAttribute('playsinline', '');
            video.setAttribute('webkit-playsinline', '');

            try {
                if (video.webkitEnterFullscreen) {
                    video.webkitEnterFullscreen();
                    return;
                }
            } catch (e) {}

            try {
                if (video.requestFullscreen) {
                    video.requestFullscreen();
                }
            } catch (e) {}
        })();
        """

        webView.evaluateJavaScript(
            javascript,
            completionHandler: nil
        )
    }

    private func exitVideoFullscreen() {

        let javascript = """
        (() => {
            try {
                if (document.exitFullscreen) {
                    document.exitFullscreen();
                }
            } catch (e) {}

            try {
                const videos =
                    document.querySelectorAll('video');

                videos.forEach(video => {
                    video.removeAttribute('fullscreen');
                });
            } catch (e) {}
        })();
        """

        webView.evaluateJavaScript(
            javascript,
            completionHandler: nil
        )
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {

        injectVideoEnhancements()
    }

    private func injectVideoEnhancements() {

        let javascript = """
        (() => {

            const prepareVideos = () => {

                const videos =
                    document.querySelectorAll('video');

                videos.forEach(video => {

                    video.setAttribute(
                        'playsinline',
                        ''
                    );

                    video.setAttribute(
                        'webkit-playsinline',
                        ''
                    );

                    video.style.maxWidth = '100%';
                    video.style.maxHeight = '100%';

                });
            };

            prepareVideos();

            const observer =
                new MutationObserver(() => {
                    prepareVideos();
                });

            observer.observe(
                document.documentElement,
                {
                    childList: true,
                    subtree: true
                }
            );

        })();
        """

        webView.evaluateJavaScript(
            javascript,
            completionHandler: nil
        )
    }

    // MARK: - New Window Handling

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration:
        WKWebViewConfiguration,
        for navigationAction:
        WKNavigationAction,
        windowFeatures:
        WKWindowFeatures
    ) -> WKWebView? {

        if let url = navigationAction.request.url {

            webView.load(
                URLRequest(url: url)
            )
        }

        return nil
    }

    // MARK: - Navigation

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction:
        WKNavigationAction,
        decisionHandler:
        @escaping (WKNavigationActionPolicy) -> Void
    ) {

        guard let url =
            navigationAction.request.url
        else {

            decisionHandler(.cancel)
            return
        }

        let scheme =
            url.scheme?.lowercased() ?? ""

        if scheme == "http" ||
           scheme == "https" {

            decisionHandler(.allow)

        } else {

            decisionHandler(.cancel)
        }
    }
}
