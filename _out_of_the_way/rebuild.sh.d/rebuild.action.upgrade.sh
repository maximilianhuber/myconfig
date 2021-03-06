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
    local oldCommit="$(git rev-parse HEAD)"
    if [[ ! -d $prefix ]]; then
        (set -x;
         git subtree add --prefix $prefix "$remoteName" "$branch" --squash)
    else
        (set -x;
         git subtree pull --prefix $prefix "$remoteName" "$branch" --squash)
    fi

    if [[ "$oldCommit" == "$(git rev-parse HEAD)" ]]; then
        return 0
    else
        return 1 # was updated
    fi
}

upgradeNixpkgs() {
    if git diff-index --quiet HEAD --; then
        logH1 "upgrade nixpkgs" "nixStableChannel=$nixStableChannel"
        upgradeSubtree \
            NixOS-nixpkgs https://github.com/NixOS/nixpkgs \
            "nixpkgs" \
            "$nixStableChannel"
    fi
}

upgradeNixosHardware() {
    if git diff-index --quiet HEAD --; then
        logH1 "upgrade nixos-hardware" ""
        upgradeSubtree \
            NixOS-nixos-hardware https://github.com/NixOS/nixos-hardware \
            "hardware/nixos-hardware/" \
            "master"
    fi
}

upgradeNixops() {
    if git diff-index --quiet HEAD --; then
        logH1 "upgrade nixops" ""
        upgradeSubtree \
            NixOS-nixops https://github.com/NixOS/nixops \
            "host.x1extremeG2/myconfig-master/nixops/" \
            "master"
    fi
}

upgrade() {
    cd $myconfigDir
    if [[ "$(hostname)" == "$my_main_host" ]]; then
        logH1 "upgrade" "start ..."
        wasUpdated=0

        upgradeNixpkgs &&
            upgradeNixosHardware &&
            upgradeNixops ||
                wasUpdated=1

        logH3 "update" "home-manager"
        ./modules/lib/home-manager/update.sh || wasUpdated=1
        logH3 "update" "nix-nixPath"
        ./modules/lib/nix-nixPath/update.sh || wasUpdated=1
        logH3 "update" "extrahosts"
        ./modules/nixos.networking/extrahosts/update.sh || wasUpdated=1
        logH3 "update" "emacs"
        ./modules/programs.emacs/update.sh || wasUpdated=1
        logH3 "update" "my-wallpapers"
        ./modules/services.xserver.my-wallpapers/update.sh || wasUpdated=1
        logH3 "update" "chisui/zsh-nix-shell"
        ./modules/shell.zsh/update.sh || wasUpdated=1

        return $wasUpdated
    fi
}

export -f upgrade
