#!/usr/bin/env bash
# Copyright 2016-2018 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
set -e

thisdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$thisdir/../common.sh"

gate() {
    [ -d /etc/nixos ]
    nixos-version &> /dev/null
}

prepare() {
    $nixosConfigDir/modules/desktop/extrahosts/default.sh
}

deploy() {
    if [[ -f /etc/nixos/configuration.nix ]]; then
        echo "/etc/nixos/configuration.nix should not exist"
        exit 1
    fi
    if [[ ! -f /etc/nixos/hostid ]]; then
        echo "set hostid:"
        cksum /etc/machine-id |
            while read c rest; do printf "%x" $c; done |
            sudo tee /etc/nixos/hostid
    fi
}

upgrade() {
    [[ "$MYCONFIG_ARGS" == *"--fast"* ]] &&
        args="--fast"

    nixCmd="sudo \
        NIX_CURL_FLAGS='--retry=1000' \
        nixos-rebuild \
        $NIX_PATH_ARGS \
        --show-trace --keep-failed \
        $args \
        --fallback"

    # first run
    logH3 "nixos-rebuild without upgrade" "$args"
    $nixCmd ${NIXOS_REBUILD_CMD:-switch}

    # second run
    if [[ "$MYCONFIG_ARGS" != *"--fast"* ]]; then
        $thisdir/home-manager/update.sh
        $thisdir/modules/emacs/update.sh
        logH3 "nixos-rebuild with upgrade" "$args"
        $nixCmd  --upgrade ${NIXOS_REBUILD_CMD:-switch}
    fi
}

gate || {
    echo "... skip"
    exit 0
}
if [ $# -eq 0 ]; then
    prepare
    deploy
    upgrade
else
    ([[ ! -n "$(type -t $1)" ]] || [ "$(type -t $1)" != "function" ] ) && exit 0
    $@
fi
