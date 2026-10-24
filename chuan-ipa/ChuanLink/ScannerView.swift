import SwiftUI
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
    let hint: String
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.onCode = onCode
        vc.hintText = hint
        return vc
    }

    func updateUIViewController(_ vc: ScannerVC, context: Context) {
        vc.onCode = onCode
        vc.setHint(hint)
    }
}

final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var hintText: String = ""

    private let session = AVCaptureSession()
    private var preview: AVCaptureVideoPreviewLayer?
    private var handled = false
    private let box = UIView()
    private let hintLabel = UILabel()
    private let titleLabel = UILabel()
    private let tipLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handled = false
        begin()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - UI

    private func buildUI() {
        titleLabel.text = "互传"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        tipLabel.text = "对着电脑屏幕上的二维码扫一下"
        tipLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        tipLabel.font = .systemFont(ofSize: 15)
        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 0
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tipLabel)

        box.layer.borderColor = UIColor.white.cgColor
        box.layer.borderWidth = 2.5
        box.layer.cornerRadius = 18
        box.backgroundColor = .clear
        box.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(box)

        hintLabel.text = hintText
        hintLabel.textColor = UIColor.systemYellow
        hintLabel.font = .systemFont(ofSize: 14)
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),

            tipLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tipLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tipLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            tipLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            box.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            box.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            box.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.68),
            box.heightAnchor.constraint(equalTo: box.widthAnchor),

            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.topAnchor.constraint(equalTo: box.bottomAnchor, constant: 22),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    func setHint(_ s: String) {
        hintText = s
        hintLabel.text = s
    }

    // MARK: - 相机

    private func begin() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                DispatchQueue.main.async {
                    if ok {
                        self?.configure()
                    } else {
                        self?.denied()
                    }
                }
            }
        default:
            denied()
        }
    }

    private func denied() {
        tipLabel.text = "没有相机权限"
        hintLabel.text = "去「设置 → 互传 → 相机」打开权限，再重新打开 App"
    }

    private func configure() {
        if preview != nil {
            if !session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
            }
            return
        }
        guard let dev = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: dev) else {
            tipLabel.text = "打不开相机"
            return
        }
        session.beginConfiguration()
        session.sessionPreset = .high
        if session.canAddInput(input) { session.addInput(input) }

        let out = AVCaptureMetadataOutput()
        if session.canAddOutput(out) {
            session.addOutput(out)
            out.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            out.metadataObjectTypes = [.qr]
        }
        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        preview = layer

        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    private func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() }
        }
    }

    // MARK: - 识别

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !handled else { return }
        for obj in metadataObjects {
            guard let code = obj as? AVMetadataMachineReadableCodeObject,
                  let s = code.stringValue, !s.isEmpty else { continue }
            handled = true
            stopSession()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onCode?(s)
            return
        }
    }
}
