import { Camera, FaceDetector, Permissions, TrackedFaceFeature } from "expo";
import React from "react";
import { Text, View } from 'react-native';
import withPermissions, { WithPermissionsProps } from "../lib/hoc/WithPermissions";

type Props = {};

class CameraScreen extends React.PureComponent<Props & WithPermissionsProps> {
  public onFacesDetected = (options: { faces: TrackedFaceFeature[] }) => {
    const { faces } = options;
    if (faces.length === 0) {
      return;
    }
  };

  public render() {
    const { grantPermissions } = this.props;

    if (grantPermissions === undefined) {
      return <View />
    }

    if (grantPermissions === false) {
      return <Text>Needs permission to use camera</Text>
    }

    return (
      <Camera
        style={{ flex: 1 }}
        onFacesDetected={this.onFacesDetected}
        faceDetectorSettings={{
          detectLandmarks: FaceDetector.Constants.Landmarks.all,
          mode: FaceDetector.Constants.Mode.fast,
          runClassifications: FaceDetector.Constants.Classifications.all,
        }}
      />
    );
  }
}

export default withPermissions(Permissions.CAMERA)(CameraScreen);
