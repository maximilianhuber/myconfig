# Copyright 2017 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
{ config, pkgs, pathExists, ... }:

let
  extraHosts = "${builtins.readFile ../static/extrahosts}";
in {
  networking.extraHosts = "${extraHosts}";
}
