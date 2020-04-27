. ./common.sh

upgradeSubtree() {
    if ! git diff-index --quiet HEAD --; then
        logERR "uncommitted changes, do not upgrade $channel"
    fi

    local remoteName=$1
    local remoteURL=$2
    local prefix=$3
    local branch=$4

    local remotes=$(git remote)
    if [[ "$remotes" != *"$remoteName"* ]]; then
        git remote add "$remoteName" "$remoteURL"
        git subtree split --rejoin --prefix="$prefix" HEAD
    fi

    git fetch "$remoteName" -- "$branch"
    logINFO "the channel $branch was last upgraded $(git log --format="%cr" remotes/$remoteName/$branch -1)"
    (set -x;
     git subtree pull --prefix $prefix "$remoteName" "$branch" --squash)
}

upgradeNixpkgs() {
    logH1 "upgrade nixpkgs" "nixStableChannel=$nixStableChannel"
    upgradeSubtree \
        NixOS-nixpkgs-channels https://github.com/NixOS/nixpkgs-channels \
        "nixpkgs" \
        "$nixStableChannel"
}

upgradeNixosHardware() {
    upgradeSubtree \
        NixOS-nixos-hardware https://github.com/NixOS/nixos-hardware \
        "nixos/hardware/nixos-hardware/" \
        "master"
}

upgrade() {
    cd $myconfigDir
    if [[ "$(hostname)" == "$my_main_host" ]]; then
        if git diff-index --quiet HEAD --; then
            logH1 "upgrade" "nixpkgs"
            upgradeNixpkgs
            if git diff-index --quiet HEAD --; then
                logH1 "upgrade" "NixosHardware"
                upgradeNixosHardware
            fi
        else
            logINFO "skip updating subtrees, not clean"
        fi

        logH3 "update" "home-manager"
        ./nixos/lib/home-manager/update.sh
        logH3 "update" "extrahosts"
        ./nixos/modules/nixos.networking/extrahosts/update.sh
        logH3 "update" "nixpkgs-unstable"
        ./nixos/lib/nixpkgs-unstable/update.sh
        logH3 "update" "emacs"
        ./nixos/modules/emacs/update.sh
        logH3 "update" "my-wallpapers"
        ./nixos/modules/desktop.common/my-wallpapers/update.sh
        logH3 "update" "chisui/zsh-nix-shell"
        ./nixos/modules/zsh/update.sh
    fi
}

export -f upgrade