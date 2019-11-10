# Copyright 2017 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ config, lib, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      clamav
    ];
    services.clamav = {
      daemon.enable = true;
      updater.enable = true;
    };
  };
}