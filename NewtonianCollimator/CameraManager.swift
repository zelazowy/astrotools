import AVFoundation
import Combine

final class CameraManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.codex.newtoniancollimator.session")
    private var didConfigureSession = false

    override init() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        super.init()
    }

    func start() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }

        switch status {
        case .authorized:
            configureAndStartSession()
        case .notDetermined:
            requestCameraAccess()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Enable camera access in Settings to use the live collimation overlay."
            }
        @unknown default:
            DispatchQueue.main.async {
                self.errorMessage = "The camera authorization state is unknown."
            }
        }
    }

    func stop() {
        sessionQueue.async {
            guard self.session.isRunning else {
                return
            }

            self.session.stopRunning()
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else {
                return
            }

            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
            }

            if granted {
                self.configureAndStartSession()
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Camera access was denied. The overlay can still be adjusted, but the live preview will stay blank."
                }
            }
        }
    }

    private func configureAndStartSession() {
        sessionQueue.async {
            guard self.configureSessionIfNeeded() else {
                return
            }

            guard !self.session.isRunning else {
                return
            }

            self.session.startRunning()
        }
    }

    private func configureSessionIfNeeded() -> Bool {
        guard !didConfigureSession else {
            return true
        }

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        session.sessionPreset = .high

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        else {
            DispatchQueue.main.async {
                self.errorMessage = "The rear camera is unavailable on this device."
            }
            return false
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)

            guard session.canAddInput(input) else {
                DispatchQueue.main.async {
                    self.errorMessage = "The camera input could not be attached to the capture session."
                }
                return false
            }

            session.addInput(input)
            didConfigureSession = true
            return true
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to initialize the camera: \(error.localizedDescription)"
            }
            return false
        }
    }
}
