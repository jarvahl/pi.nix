{ self, ... }:

let
  homeManagerModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.programs.pi.coding-agent;
      package = cfg.package;

      wrapped = self.lib.piConfiguration {
        inherit package pkgs;
        inherit (cfg)
          environment
          extensions
          extraArgs
          skills;
      };
    in
    {
      options.programs.pi.coding-agent = {
        enable = lib.mkEnableOption "pi coding agent";

        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.system}.default;
          description = "Pi coding-agent package.";
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.value = lib.mkOption {
                type = lib.types.str;
                description = "Literal environment value.";
              };
            }
          );
          default = { };
          description = "Environment variables exported before launching Pi.";
        };

        extensions = lib.mkOption {
          type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
          default = [ ];
          description = "Extension paths passed to Pi.";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional arguments passed to Pi.";
        };

        skills = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "Skill paths passed to Pi.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ wrapped ];
      };
    };
in
{
  flake.homeModules.default = homeManagerModule;
}
