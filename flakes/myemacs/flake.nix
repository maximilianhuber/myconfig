{
  description = "my doom-emacs configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # emacs.url = "github:nix-community/emacs-overlay";
    nix-doom-emacs.url = "github:vlaci/nix-doom-emacs";
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-doom-emacs, ... }: {
    nixosModule = { config, lib, pkgs, ... }: {
      config = {
        nixpkgs.overlays = [
          (self: super: {
            dune =
              super.dune_1; # see: https://github.com/vlaci/nix-doom-emacs/issues/166
            emacs =
              super.emacs.overrideDerivation (drv: { nativeComp = true; });
          })
        ];
        environment = {
          variables = { EDITOR = "emacs -nw"; };
          shellAliases = {
            ec = "emacs";
            vim = "emacs -nw";
            emacs = "emacs";
          };
        };
        home-manager.sharedModules = [
          ({ config, ... }:
            let
              xclipedit = pkgs.writeShellScriptBin "xclipedit" ''
                set -euo pipefail
                tempfile="$(mktemp)"
                trap "rm $tempfile" EXIT
                if [ -t 0 ]; then
                    xclip -out > "$tempfile"
                else
                    cat > "$tempfile"
                fi
                ${config.programs.doom-emacs.package}/bin/emacs "$tempfile"
                ${pkgs.xclip}/bin/xclip < "$tempfile"
              '';
            in {
              imports = [
                # doom emacs
                nix-doom-emacs.hmModule
              ];
              programs.doom-emacs = {
                enable = true;
                doomPrivateDir = let
                  doomPrivateDeriv = pkgs.stdenv.mkDerivation rec {
                    name = "doomPrivateDeriv-1.0";
                    src = ./doom.d;
                    installPhase = ''
                      mkdir -p "$out"
                      cp -r * "$out"
                    '';
                  };
                in "${doomPrivateDeriv}";
                extraPackages = [
                  pkgs.mu
                  pkgs.gnuplot
                  (pkgs.nerdfonts.override { fonts = [ "Inconsolata" ]; })
                ];
                extraConfig = ''
                  (setq mu4e-mu-binary "${pkgs.mu}/bin/mu")
                '';
              };
              home.packages = with pkgs; [
                xclipedit
                emacs-all-the-icons-fonts

                aspell
                aspellDicts.de
                aspellDicts.en

                shellcheck
              ];
              # programs.zsh.shellAliases = {
              #   magit = ''${doom-emacs-bin-path} -e "(magit-status \"$(pwd)\")"'';
              # };
              home.file = {
                ".doom.d/imports" = {
                  source = ./doom.d-imports;
                  recursive = true;
                };
              };

            })
        ];
      };
    };
  };
}
