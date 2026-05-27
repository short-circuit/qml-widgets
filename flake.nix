{
  description = "Quickshell touch gesture widgets — edge-swipe OSK, volume, brightness, hotkey bar";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.stdenv.mkDerivation {
        pname = "qml-touch-widgets";
        version = "0.1.0";
        src = self;

        dontBuild = true;

        installPhase = ''
          mkdir -p $out/share/qml-touch-widgets
          cp shell.qml $out/share/qml-touch-widgets/
          cp -r touch-hotkeys $out/share/qml-touch-widgets/touch-hotkeys
          cp README.md $out/share/qml-touch-widgets/ 2>/dev/null || true
        '';

        meta = with nixpkgs.lib; {
          description = "Edge-swipe gesture widgets for touchscreen convertibles on Quickshell + Hyprland";
          homepage = "https://github.com/shortcircuit/qml-widgets";
          license = licenses.mit;
          platforms = platforms.linux;
          maintainers = [];
        };
      };
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "qml-touch-widgets-dev";

        packages = with pkgs; [
          quickshell
          ydotool
          brightnessctl
          wireplumber
        ];

        shellHook = ''
          echo "qml-touch-widgets dev shell"
          echo "  Run: qs -p $PWD"
          echo ""
        '';
      };
    });
  };
}
