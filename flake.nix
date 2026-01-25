{
  description = "claude-code-native - Anthropic's official CLI for Claude";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      version = "2.1.19";
      baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

      # Platform-specific binary info
      platformInfo = {
        "aarch64-darwin" = {
          platform = "darwin-arm64";
          hash = "sha256-04asj20UefhdMfNpQhyCQTXBAknDIIcBfQWl9CiFLEE=";
        };
        "x86_64-darwin" = {
          platform = "darwin-x64";
          hash = "sha256-viZrOpUvSD2DWK0UHir+ZhFwOGUG9Hnq2ZIxnk/cOKw=";
        };
        "aarch64-linux" = {
          platform = "linux-arm64";
          hash = "sha256-jEthskynYNb3qi8ZcnFj0SLp/Qw86R8QaiG2kYp7G7s=";
        };
        "x86_64-linux" = {
          platform = "linux-x64";
          hash = "sha256-Tiocc4cezzsTM3a1fe0DMzp6Y4fy0qOmJ5u5Cgf3qUQ=";
        };
      };

      supportedSystems = builtins.attrNames platformInfo;

    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        info = platformInfo.${system};
      in
      {
        packages = {
          claude-code-native = pkgs.stdenv.mkDerivation {
            pname = "claude-code-native";
            inherit version;

            src = pkgs.fetchurl {
              url = "${baseUrl}/${version}/${info.platform}/claude";
              hash = info.hash;
            };

            dontUnpack = true;
            dontBuild = true;

            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.autoPatchelfHook
            ];

            buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.stdenv.cc.cc.lib
            ];

            installPhase = ''
              runHook preInstall
              install -Dm755 $src $out/bin/claude
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Anthropic's official CLI for Claude";
              homepage = "https://claude.ai";
              license = licenses.unfree;
              mainProgram = "claude";
              platforms = supportedSystems;
            };
          };

          default = self.packages.${system}.claude-code-native;
        };

        apps = {
          claude-code-native = flake-utils.lib.mkApp {
            drv = self.packages.${system}.claude-code-native;
            name = "claude";
          };
          default = self.apps.${system}.claude-code-native;
        };
      }
    );
}
