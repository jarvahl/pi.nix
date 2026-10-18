{ lib, ... }:

{
  flake.lib.piConfiguration =
    { package
    , pkgs
    , extensions ? [ ]
    , skills ? [ ]
    , environment ? { }
    , extraArgs ? [ ]
    ,
    }:
    let
      environmentPrelude = lib.concatLines (
        lib.mapAttrsToList
          (
            name: value:
              "export ${lib.escapeShellArg name}=${lib.escapeShellArg value.value}"
          )
          environment
      );

      extensionArgs = lib.concatMapStringsSep "\n"
        (
          extension:
          ''
            extension=${lib.escapeShellArg "${extension}"}
            args+=(--extension "$extension")
            extension_dir="''${extension%/*}"
            if [ -d "$extension_dir/skills" ]; then
              args+=(--skill "$extension_dir/skills")
            fi
          ''
        )
        extensions;

      skillArgs = lib.concatMapStringsSep "\n"
        (
          skill: "args+=(--skill ${lib.escapeShellArg "${skill}"})"
        )
        skills;

      extraArgsText = lib.concatMapStringsSep "\n"
        (
          argument: "args+=(${lib.escapeShellArg argument})"
        )
        extraArgs;
    in
    pkgs.writeShellScriptBin "pi" ''
      ${environmentPrelude}
      args=()
      ${extensionArgs}
      ${skillArgs}
      ${extraArgsText}
      exec ${lib.escapeShellArg (lib.getExe package)} "''${args[@]}" "$@"
    '';
}
