{
  description = "Quickshell touch gesture widgets — edge-swipe OSK, volume, brightness";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      name = "qml-touch-widgets";
      src = ./.;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share/qml-touch-widgets
        cp shell.qml $out/share/qml-touch-widgets/
        cp README.md $out/share/qml-touch-widgets/ 2>/dev/null || true
      '';
    };
  };
}
