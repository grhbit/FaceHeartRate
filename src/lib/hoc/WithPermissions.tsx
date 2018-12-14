import { Permissions } from "expo";
import React from "react";

export type WithPermissionsProps = {
  grantPermissions?: boolean;
};

type State = {
  response?: Permissions.PermissionResponse;
};

export default (...permissions: Permissions.PermissionType[]) => <P extends WithPermissionsProps>(ComposedComponent: React.ComponentType<P>) => {
  return class extends React.PureComponent<P, State> {
    public static displayName = `WithPermissions(${ComposedComponent.displayName})`;

    public state: State = {};

    public async componentDidMount() {
      const response = await Permissions.askAsync(...permissions);
      this.setState({ response });
    }

    public render() {
      const { response } = this.state;
      let status: boolean | undefined;

      if (response) {
        status = response.status === "granted";
      }

      return (<ComposedComponent grantPermissions={status} {...this.props} />);
    }
  };
}
