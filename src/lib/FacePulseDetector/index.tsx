import React from "react";
import { requireNativeComponent, ViewProps } from "react-native";

export type TrackingID = number;

export type Point = {
  x: number;
  y: number;
}

export type FaceDetectedResponse = {
  trackingID: TrackingID;
  lt: Point;
  lb: Point;
  rt: Point;
  rb: Point;
};

export type HeartRateResponse = {
  trackingID: TrackingID;
  meanBpm: number;
  maxBpm: number;
  minBpm: number;
};

export type Props = {
  onFacesDetected?: (res: FaceDetectedResponse) => void;
  onHeartRate?: (res: HeartRateResponse) => void;
};

const RNFacePulseDetector = requireNativeComponent("FacePulseDetector") as React.ComponentType<any>;

class FacePulseDetector extends React.Component<ViewProps & Props> {
  public render() {
    return (
      <RNFacePulseDetector
        {...this.props}
        onFacesDetected={this.onFaceDetected}
        onHeartRate={this.onHeartRate}
      />
    );
  }

  private onFaceDetected = ({ nativeEvent }: { nativeEvent: FaceDetectedResponse }) => {
    if (this.props.onFacesDetected) {
      this.props.onFacesDetected(nativeEvent);
    }
  }

  private onHeartRate = ({ nativeEvent }: { nativeEvent: HeartRateResponse }) => {
    if (this.props.onHeartRate) {
      this.props.onHeartRate(nativeEvent);
    }
  }
}

export default FacePulseDetector;
