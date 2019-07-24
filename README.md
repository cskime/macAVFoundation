# AVFoundation Sample
skt 과제 중 맥북 카메라를 사용해서 사람 얼굴을 캡쳐하는 프로그램이 필요해서 맥북 카메라를 켜고 그 화면을 png 이미지로 캡쳐해 저장할 수 있는 간단한 프로젝트를 만들었습니다. macOS에서 내장 카메라/오디오에 접근하려면 애플에서 제공하는 AVFoundation 프레임워크를 사용해야 하는데, 내장 비디오 장치를 찾아 `AVCaptureInput`로 만들고 출력 형식(이 프로젝트에서는 이미지 파일 저장)에 따라 `AVCaptureOutput`을 만들어서 `AVCaptureSession`에 추가한 뒤 session을 시작해서 `previewLayer`에 표시해 주는 과정을 볼 수 있습니다.
- ([AVFoundation Document](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture)).

## 주로 사용되는 클래스
- `AVCaptureSession` : capture activity와 input device에서 output으로의 데이터 흐름을 관리하는 주요 객체입니다.
- `AVCaptureDevice` : `AVCaptureSession`에 입력되는 오디오, 비디오 등 장치. 하드웨어 캡쳐 관련 기능을 컨트롤하는 객체. `mediaType`에 따라 비디오/오디오 장치에 각각 접근할 수 있습니다.
- `AVCaptureDeviceInput` : `AVCaptureSession`에 input data로 제공되는 객체입니다. `AVCaptureDevice`를 먼저 찾은 후에 input으로 만듭니다.
- `AVCaptureStillImageOutput` : `AVCaptureSession`에서 기록된 media를 이미지로 출력하는 객체입니다. 출력 형식에 따라 `AVCaptureOutput`의 subclass를 다르게 사용할 수 있습니다.

## Sample Project Description
## 프로젝트 설정
- `info.plist`에서 `Privacy - Camera Usage Description` 키를 추가해야 합니다.
- macOS 개발은 iOS와 달리 [Project - Capabilities - App Sandbox - Hardware] 탭에서 카메라 항목을 체크해야 합니다.

### ViewController Class
Session에 input과 output이 모두 설정된 후 session을 시작해야 합니다. `viewDidLoad()`에서 `SessionControll1r`와 `SessionInput`, `SessionImageOutput` 인스턴스를 만들고, device input을 찾으면 session에 input, output을 설정해줍니다. previewLayer는 session에 input과 output이 모두 설정된 후에 view에 설정해야 합니다.
``` swift
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        camSession = SessionController()
        videoInput = SessionInput(for: .video)
        imageOutput = SessionImageOutput()

        if let input = videoInput.createDefaultDeviceInput() {
            camSession.configureSessionInput(input: input)
            camSession.configureSessionOutput(output: imageOutput.getImageOutput(), preset: .photo)
            camSession.setPreviewLayer(at: self.view)
        }

        captureButton.isEnabled = false
    }
```

### SessionController Class
카메라 사용 권한을 체크하고 `AVCaptureSession`을 설정하고 관리합니다.
- `verifyAuthorization(for:)` : 카메라 사용 권한을 체크합니다. `AVCaptureDevice.authorizationStatus(for:)` 메서드를 사용해서 현재 카메라 권한 설정 여부를 확인하고 필요한 경우 카메라 사용 권한을 요청합니다(`AVCaptureDevice.requestAccess(for:)`).
- `configureSessionInput(input:)` : session에 input을 추가합니다. input이나 output의 configuration 작업은 `beginConfigureation()`과 `commitConfiguration()` 사이에서 진행합니다.
- `configureSessionOutput(output:preset:)` : session에 output 추가합니다. output을 추가할 때 `sessionPreset`을 설정할 수 있습니다. preset은 출력 품질을 설정합니다(A constant value indicating the quality level or bit rate of the output).
- `setPreviewLayer(at:)` : 미리보기 화면을 보여주는 `AVCaptureVideoPreviewLayer()` 객체를 `NSView`의 레이어의 sub layer로 추가하면 특정 view에서 현재 기록되는 video를 확인할 수 있습니다. `NSView`는 레이어를 기본으로 갖고 있지 않아서 `CALayer()`로 초기화해야 합니다.
- `updatePreviewLayer(frame:)` : 창 크기 조절할 때 preview layer의 크기도 함께 변화시키도록 frame을 갱신하는 용도로 사용합니다. 여기서는 ViewController의 view를 preview로 사용했으므로 `viewWillLayout()`에서 호출하면 창 크기 변화에 따라 preview 크기를 맞출 수 있습니다.
- `startSession()` : 카메라 사용 권한을 허용했고 세션이 실행되지 않은 상태에서 `startRunning()`을 호출해 세션을 시작합니다.
- `stopSession()` : `stopRunning()`을 호출해서 세션을 종료합니다.

### SessionInput Class
`AVCaptureInput`을 `mediaType`에 따라 생성해 줍니다.
- `init(mediaType:)` : `AVMediaType`을 `.video`, `.audio`, `.depthData` 등으로 설정함에 따라 다른 input을 만들 수 있습니다. 여기서는 `.video` 타입으로 설정합니다.
- `createDefaultDeviceInput() -> AVCaptureDeviceInput?` : `mediaType`에 해당하는 deivce를 찾고 그로부터 Input을 생성해 반환합니다.

### SessionImageOutput Class
이미지로 출력할 때는 `AVCaptureStillImageOutput` 객체를 사용합니다.
- `init()` : output setting을 설정합니다. `kCVPixelBufferPixelFormatTypeKey`키에 대한 값을 설정하는데 애플에서 권장되는 설정이 있습니다(https://developer.apple.com/documentation/avfoundation/avcapturestillimageoutput/1389306-outputsettings). 여기서는 `kCVPixelFormatType_32BGRA` 값을 설정합니다.
- `getImageOutput() -> AVCaptureStillImageOutput` : output을 반환합니다.
- `capturePNGImage(path:URL)` : `captureStillImageAsynchronously(connection:completeHandler:)` 메서드를 사용해서 이미지로 캡쳐합니다. 현재 session에 input과 output이 등록되어 있으면 그 쌍을 잇는 `connection`이 생성되는데, 이것을 입력으로 하여 `completeHandler`에서 `imageSampleBuffer`로 캡쳐 이미지를 제공합니다. `convertToNSImage()`를 사용해 버퍼에 이미지를 `NSImage` 형태로 변환한 뒤 `pngWrite()`를 통해 지정 경로에 저장할 수 있습니다.
