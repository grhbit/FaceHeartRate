import { Permissions } from "expo";
import React from "react";
import { Text, View } from 'react-native';
import { NavigationScreenOptions } from "react-navigation";
import styled from "styled-components/native";
import FacePulseDetector, { HeartRateResponse } from "../lib/FacePulseDetector";
import withPermissions, { WithPermissionsProps } from "../lib/hoc/WithPermissions";

type Props = {};

type BorderBoxState = {
  lt: { x: number, y: number };
  lb: { x: number, y: number };
  rt: { x: number, y: number };
  rb: { x: number, y: number };
};

type HeartRateState = {
  meanBpm: number;
  maxBpm: number;
  minBpm: number;
};

const BPMText = styled.Text`
  position: absolute;
  left: 30;
  bottom: 30;
  font-size: 32px;
  color: #fff;
  text-shadow: -1px 1px 3px rgba(0, 0, 0, 0.75);
`;

const HighBPMText = styled.Text`
  position: absolute;
  left: 30;
  bottom: 80;
  font-size: 20px;
  color: #ff0;
  text-shadow: -1px 1px 3px rgba(0, 0, 0, 0.75);
`;

const LowBPMText = styled.Text`
  position: absolute;
  left: 30;
  bottom: 60;
  font-size: 20px;
  color: #ffc;
  text-shadow: -1px 1px 3px rgba(0, 0, 0, 0.75);
`;

class CameraScreen extends React.PureComponent<Props & WithPermissionsProps, BorderBoxState & HeartRateState> {
  public static navigationOptions: NavigationScreenOptions = {
    header: null
  };

  public state: BorderBoxState & HeartRateState = {
    lb: { x: 0, y: 0 },
    lt: { x: 0, y: 0 },
    maxBpm: 0,
    meanBpm: 0,
    minBpm: 0,
    rb: { x: 0, y: 0 },
    rt: { x: 0, y: 0 },
  };

  public render() {
    const { grantPermissions } = this.props;

    const { meanBpm, minBpm, maxBpm } = this.state;

    if (grantPermissions === undefined) {
      return <View />
    }

    if (grantPermissions === false) {
      return <Text>Needs permission to use camera</Text>
    }

    return (
      <FacePulseDetector
        style={{ flex: 1, position: "relative" }}
        onHeartRate={this.onHeartRate}
      >
        <HighBPMText>
          {"High: "}
          {maxBpm < 20 ? "" : maxBpm.toFixed(3)}
        </HighBPMText>
        <LowBPMText>
          {"Low: "}
          {minBpm < 20 ? "" : minBpm.toFixed(3)}
        </LowBPMText>
        <BPMText>
          {"BPM: "}
          {meanBpm < 20 ? "Calculating..." : meanBpm.toFixed(3)}
        </BPMText>
      </FacePulseDetector>
    );
  }

  private onHeartRate = ({ trackingID, ...rest }: HeartRateResponse) => {
    const {
      meanBpm,
      maxBpm,
      minBpm
    } = rest;

    this.setState({
      maxBpm,
      meanBpm,
      minBpm
    });
  }
}

export default withPermissions(Permissions.CAMERA)(CameraScreen);
