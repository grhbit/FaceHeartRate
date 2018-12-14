export type RouteName = "Camera" | "Main";

const Routes: { [keyname in RouteName]: string } = {
  Camera: "Camera",
  Main: "Main"
};

export default Routes;
