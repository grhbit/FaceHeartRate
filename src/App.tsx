import { Permissions } from "expo";
import * as React from "react";
import { SafeAreaView, Text, View } from "react-native";

type State = {
  hasCameraPermission?: boolean;
};

export default class App extends React.Component<{}, State> {
  public state: State = {};

  public async componentDidMount() {
    const { status } = await Permissions.askAsync(Permissions.CAMERA);
    this.setState({ hasCameraPermission: status === "granted" });
  }

  public render() {
    const { hasCameraPermission } = this.state;
    if (hasCameraPermission === null) {
      return <View />;
    }

    return (
      <SafeAreaView>
        <Text>{hasCameraPermission ? "Grants permission to access camera" : "No access to camera"}</Text>
      </SafeAreaView>
    );
  }
}
