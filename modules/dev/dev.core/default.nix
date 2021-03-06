# Copyright 2019 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ pkgs, config, lib, ... }:
let
  cfg = config.myconfig.dev;
  cropLog = with pkgs;
    writeScriptBin "cropLog.hs" (lib.fileContents ./cropLog.hs);
in {
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (self: super: {
        diffoscope = super.diffoscope.overrideAttrs (oldAttrs: rec {
          disabledTests = oldAttrs.disabledTests ++ [ "test_ffprobe" ];
        });
      })
    ];
    home-manager.sharedModules = [{
      home.packages = with pkgs;
        ([
          meld
          diffoscope
          gnumake
          cmake
          automake
          cloc
          pass-git-helper
          jq
          cropLog
          mercurialFull
          gnuplot
          plantuml
          graphviz
        ] ++ lib.optional config.services.xserver.enable vscode-with-extensions
          ++ lib.optional config.services.xserver.enable nixos-unstable.freeplane
          ++ lib.optional config.services.xserver.enable xournalpp);
    }];
  };
}
