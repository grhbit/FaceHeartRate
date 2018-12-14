import * as React from "react";
import { createStackNavigator } from "react-navigation";
import Routes from "./routes";
import CameraScreen from "./screens/CameraScreen";
import MainScreen from "./screens/MainScreen";


const RootStack = createStackNavigator({
  [Routes.Camera]: CameraScreen,
  [Routes.Main]: MainScreen,
}, {
  initialRouteName: Routes.Main
});

export default class App extends React.Component {
  public render() {
    return <RootStack />;
  }
}
