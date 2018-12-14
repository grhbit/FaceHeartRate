import { FaceDetector } from "expo";

declare module "expo" {
    interface CameraProps {
        faceDetectorSettings?: FaceDetector.DetectionOptions;
    }

    namespace Permissions {
      function askAsync(...type: PermissionType[]): Promise<PermissionResponse>;
    }
}
