{ pkgs
, lib
, buildNpmPackage
, nodejs_22
, fetchFromGitHub
, makeWrapper
, pkg-config
, typescript
, pixman
, cairo
, pango
, libpng
, libjpeg
, giflib
, librsvg
, gitMinimal
, openssh
, ripgrep
, fd
, ...
}:

(buildNpmPackage.override {
  nodejs = nodejs_22;
}) (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.78.0";

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Cw+W5w6yuL+cH+JfgCbEwiyeXloMb7yFd46TXJPZGTg=";
  };

  npmDepsHash = "sha256-TxMiT7nJqLZRXKFoxb4FpsETGe3I99qU7olTgNsoQd4=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    typescript
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
      --suffix PATH : "${lib.makeBinPath [
        nodejs_22
        gitMinimal
        openssh
        ripgrep
        fd
      ]}" \
      --run 'export NPM_CONFIG_PREFIX="''${NPM_CONFIG_PREFIX:-''${XDG_DATA_HOME:-$HOME/.local/share}/pi/npm}"'

    runHook postInstall
  '';

  meta = {
    description = "Pi, a minimal terminal coding harness";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
})
