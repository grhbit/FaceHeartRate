import React from "react";
import { NavigationScreenProps, withNavigation } from "react-navigation";
import styled from "styled-components/native";
import Routes from "../routes";

const Box = styled.View`
  flex: 1;
  justify-content: center;
  align-items: center;
`;

const Button = styled.Button``;

type Props = {};

class MainScreen extends React.Component<Props & NavigationScreenProps> {
  public render() {
    return <Box><Button title="Go to CameraScreen" onPress={this.handlePress} /></Box>;
  }

  private handlePress = () => {
    const {
      navigation
    } = this.props;

    navigation.push(Routes.Camera);
  }
}

export default withNavigation(MainScreen);
