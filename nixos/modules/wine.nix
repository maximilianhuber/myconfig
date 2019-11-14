# Copyright 2017 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ pkgs, ... }:
{
  config = let
      wineCfg = {
        wineBuild = "wineWow";
        gstreamerSupport = false;
      };
    in {
    environment.systemPackages = with pkgs; [
      (wine.override wineCfg)
      (winetricks.override {wine = wine.override wineCfg;})
    ];
    hardware.opengl.driSupport32Bit = true;
  };
}