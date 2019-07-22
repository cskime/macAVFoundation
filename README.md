# AVFoundation Framework
- iOS, macOS에서 사용가능한 장치의 카메라, 오디오 등에 접근하기 위한 프레임워크 
([Document](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture))

## Classes
- AVCaptureSession
- AVCaptureDevic
- AVCaptureInput(여기서는 디바이스 카메라를 사용하므로 AVCaptureDeviceInput)
- AVCaptureOutput(여기서는 png 이미지를 저장하므로 AVCaptureStillImageOutput)

## Sample
### SessionController Class
- `verifyAuthorization(for:)` : 카메라 권한 설정
  - info.plist에서 Privacy - Camera Usage Description 키 추가
  - mac은 [Project - Capabilities - App Sandbox - Hardware] 탭의 카메라를 체크
- `configureSessionInput(input:)` : session에 input 추가
- `configureSessionOutput(output:preset:)` : session에 output 추가. 
  - sessionPreset 설정. A constant value indicating the quality level or bit rate of the output.
- `setPreviewLayer(at:)` : `startRunning()` 후 미리보기
  - `NSView`의 `layer` 속성에 `AVCaptureVideoPreviewLayer`를 subLayer로 설정
  - `NSView`는 기본으로 레이어를 갖지 않아서 `CALayer()`로 초기화필
- `updatePreviewLayer(frame:)` : 창 크기 조절할 때 layer 크기도 함께 변화. ViewController의 `viewWillLayout()`에서 호출


### SessionInput
- `init(mediaType:)` : 미디어 타입과 함께 초기화. 여기서는 `.video`
- `createDefaultDeviceInput() -> AVCaptureDeviceInput?` : device input 반환

### SessionImageOutput
- `getImageOutput() -> AVCaptureStillImageOutput` : image output 반환
- `capturePNGImage(path:URL)` : 지정 경로에 현재 session video를 캡쳐해서 png 파일로 저장
  - `captureStillImageAsynchronously(connection:completeHandler:)` : 캡쳐한 image를 `completeHandler`에서 `imageSampleBuffer`로 제공.
  - `convertToNSImage()`로 image buffer를 nsimage로 변환, `pngWrite`를 통해 PNG 포맷 이미지 저장
