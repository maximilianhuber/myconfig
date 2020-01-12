# Copyright 2017-2020 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ config, pkgs, ... }:
{
  config = {
    nixpkgs.overlays = [
      (self: super: let
        pass = super.pass.overrideDerivation ( drv: {
          # should work for 1.7.3
          patches = drv.patches ++ [ ./patches/pass_-_copy_by_default.diff ];
          doInstallCheck = false;
        });
      in {
        inherit pass;
        pass-git-helper = super.python3Packages.callPackage ./pass-git-helper.nix {
          inherit (super.python3Packages) buildPythonApplication;
          inherit (self.python3Packages) pyxdg;
        };
      })
    ];
    home-manager.users.mhuber = {
      home.packages = with pkgs; [
        pass
        pass-git-helper
      ];
      home.file = {
        ".config/pass-git-helper/git-pass-mapping.ini".source = ./config/pass-git-helper/git-pass-mapping.ini;
      };
    };
  };
}