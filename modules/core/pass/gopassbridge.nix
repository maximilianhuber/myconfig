# Copyright 2017-2020 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT

# this sets up the configuration generated by `gopass jsonapi configure`

{ config, pkgs, ... }:
let
  gopassWrapper = with pkgs; writeScriptBin "gopass_wrapper.sh" ''
    #!${stdenv.shell}
    if [ -f ~/.gpg-agent-info ] && [ -n "$(${procps}/bin/pgrep gpg-agent)" ]; then
      source ~/.gpg-agent-info
      export GPG_AGENT_INFO
    else
      eval $(${gnupg}/bin/gpg-agent --daemon)
    fi
    export GPG_TTY="$(tty)"

    ${gopass}/bin/gopass jsonapi listen

    exit $?
  '';
in {
  config = {
    home-manager.users.mhuber = {
      home.file = {
        ".mozilla/native-messaging-hosts/com.justwatch.gopass.json" = {
          text = ''
            {
                "name": "com.justwatch.gopass",
                "description": "Gopass wrapper to search and return passwords",
                "path": "${gopassWrapper}/bin/gopass_wrapper.sh",
                "type": "stdio",
                "allowed_extensions": [
                    "{eec37db0-22ad-4bf1-9068-5ae08df8c7e9}"
                ]
            }
          '';
        };
        ".config/chromium/NativeMessagingHosts/com.justwatch.gopass.json" = {
          text = ''
            {
                "name": "com.justwatch.gopass",
                "description": "Gopass wrapper to search and return passwords",
                "path": "${gopassWrapper}/bin/gopass_wrapper.sh",
                "type": "stdio",
                "allowed_origins": [
                    "chrome-extension://kkhfnlkhiapbiehimabddjbimfaijdhk/"
                ]
            }
          '';
        };
      };
    };
  };
}
