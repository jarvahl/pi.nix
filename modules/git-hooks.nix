{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
    {
      pre-commit = {
        check.enable = true;
        settings.hooks.treefmt.enable = true;
      };

      devShells.default = pkgs.mkShell {
        inherit (config.pre-commit) shellHook;
      };
    };
}
