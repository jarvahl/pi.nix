{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    let
      package = pkgs.callPackage ../../packages/pi-coding-agent.nix { };
      pi = self.lib.piConfiguration {
        inherit package pkgs;
      };
    in
    {
      apps.default = {
        type = "app";
        program = "${pi}/bin/pi";
        meta.description = "Run Pi with its default configuration.";
      };

      packages.default = package;
    };
}
