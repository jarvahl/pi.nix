{
  inputs,
  pkgs,
  lib,
  buildNpmPackage,
  nodejs_22,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  typescript,
  typescript-go,
  pixman,
  cairo,
  pango,
  libpng,
  libjpeg,
  giflib,
  librsvg,
  gitMinimal,
  openssh,
  ripgrep,
  fd,
  ...
}:
let
  version = "0.78.0";
  buildNpmPackage' = buildNpmPackage.override {
    nodejs = nodejs_22;
  };
  runtimeBins = lib.makeBinPath [
    nodejs_22
    gitMinimal
    openssh
    ripgrep
    fd
  ];

  pi = buildNpmPackage' {
    pname = "pi-coding-agent";
    inherit version;

    src = fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      rev = "v${version}";
      hash = "sha256-W5qKzWJb9lGTpniNrlPPx3+LfnZFzJ53g+qQzcOSqCo=";
    };

    npmDepsHash = "sha256-8G62D+NhZHo+LnnIiG8/M48a229x0NIL+t8ArlAvj6Y=";

    nativeBuildInputs = [
      makeWrapper
      pkg-config
      typescript
      typescript-go
    ];

    buildInputs = [
      pixman
      cairo
      pango
      libpng
      libjpeg
      giflib
      librsvg
    ];

    preBuild = ''
      find packages -name package.json -exec sed -i \
        -e 's/--watch --preserveWatchOutput//g' \
        {} \;

      for file in packages/ai/src/models.ts packages/agent/src/agent.ts packages/tui/src/utils.ts; do
        if [ -f "$file" ]; then
          sed -i '1i// @ts-nocheck' "$file"
        fi
      done
    '';

    buildPhase = ''
      runHook preBuild
      npm run build --workspace=packages/tui --workspace=packages/ai --workspace=packages/agent --workspace=packages/coding-agent
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/node_modules/@earendil-works

      for package in tui ai agent coding-agent mom pods; do
        if [ -d "packages/$package/dist" ]; then
          mkdir -p "$out/lib/node_modules/@earendil-works/pi-$package"
          cp -r packages/$package/dist/. "$out/lib/node_modules/@earendil-works/pi-$package/"
          cp "packages/$package/package.json" "$out/lib/node_modules/@earendil-works/pi-$package/"
        fi
      done

      cp -rL node_modules/. "$out/lib/node_modules/"

      makeWrapper ${nodejs_22}/bin/node $out/bin/pi \
        --add-flags "$out/lib/node_modules/@earendil-works/pi-coding-agent/cli.js" \
        --set PI_PACKAGE_DIR "$out/lib/node_modules/@earendil-works/pi-coding-agent" \
        --prefix NODE_PATH : "$out/lib/node_modules" \
        --suffix PATH : "${runtimeBins}" \
        --run 'export NPM_CONFIG_PREFIX="''${NPM_CONFIG_PREFIX:-''${XDG_DATA_HOME:-$HOME/.local/share}/pi/npm}"'

      runHook postInstall
    '';

    meta = {
      description = "Pi, a minimal terminal coding harness";
      homepage = "https://github.com/earendil-works/pi";
      license = lib.licenses.mit;
      mainProgram = "pi";
    };
  };
in
inputs.wrappers.lib.wrapPackage {
  inherit pkgs;
  package = pi;
}
