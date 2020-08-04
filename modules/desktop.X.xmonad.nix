# Copyright 2017 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ pkgs, ... }:
let
  my-xmobar = pkgs.callPackage ../pkgs/myXmobar {
    inherit pkgs;
 };
  my-xmonad = pkgs.haskellPackages.callPackage ../pkgs/myXMonad {
    inherit pkgs my-xmobar;
  };
  myxev = pkgs.writeShellScriptBin "myxev" ''
    ${pkgs.xorg.xev}/bin/xev -id $(${pkgs.xdotool}/bin/xdotool getactivewindow)
  '';

in {
  imports = [
    ./desktop.X.common
  ];

  config = {
    home-manager.users.mhuber = {
      home.packages = with pkgs; [
        my-xmonad
        my-xmobar

        dzen2
        myxev
      ];
      xsession.windowManager.command = "${my-xmonad}/bin/xmonad";
    };

    # system.activationScripts.cleanupXmonadState = "rm $HOME/.xmonad/xmonad.state || true";

    services = {
      xserver = {
        displayManager.defaultSession = "none+myXmonad";
        windowManager = {
          session = [{
            name = "myXmonad";
            start = ''
              exec &> >(tee -a /tmp/myXmonad.log)
              echo -e "\n\n$(date)\n\n"
              ${my-xmonad}/bin/xmonad &
              waitPID=$!
            '';
          }];
        };

        desktopManager.xterm.enable = false;
      };
    };
  };
}
