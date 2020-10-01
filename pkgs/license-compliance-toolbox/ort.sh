#!/usr/bin/env bash
# Copyright 2019 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT

#
# A simple script which generates the ort docker image on demand and wraps calls
# to ort into a docker layer
#
# Based on Code from https://github.com/heremaps/oss-review-toolkit (Licensed under Apache-2.0)
#

set -e

baseTag=ort:latest
tag=myort:latest
DEBUG_LEVEL="--info"
case $1 in
    "--no-debug") shift; DEBUG_LEVEL="" ;;
    "--info") shift; ;;
    "--debug") shift; DEBUG_LEVEL="--debug"; set -x ;;
esac

helpMsg() {
    cat<<EOF
usage:
  $0 --all <folder>
  $0 --short <folder>
  $0 --analyze <folder>
  $0 --download <yaml>
  $0 --scan <yaml>
  $0 --report <yaml>
  $0 [args]
  $0 --help

Builds the ort image on demand.
Remove the ort:latest image to enforce rebuild of the docker image.

If the workdir ends on -enc it is treated as gocryptfs folder and the user is asked interactively for a password.
EOF
}

#################################################################################
# function to build ort docker image
#################################################################################
buildImageIfMissing() {
    if [[ "$(docker images -q $tag 2> /dev/null)" == "" ]]; then
        if [[ "$(docker images -q $baseTag 2> /dev/null)" == "" ]]; then
            ORT=$(mktemp -d)
            trap 'rm -rf $ORT' EXIT
            git clone https://github.com/oss-review-toolkit/ort $ORT

            docker build \
                --network=host \
                -t $baseTag $ORT
        else
        echo "docker base image already build"
        fi
        docker build -t $tag -<<EOF
FROM $baseTag
ENV JAVA_OPTS "-Xms2048M -Xmx16g -XX:MaxPermSize=4096m -XX:MaxMetaspaceSize=4g"
RUN set -x \
 && ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N "" \
 && apt-get update \
 && apt-get install -y --no-install-recommends gocryptfs fuse \
 && rm -rf /var/lib/apt/lists/* \
 && (echo "if [[ -d /workdir-enc ]]; then\n  set -e\n  trap 'kill -TERM \\\$PID; wait \\\$PID; fusermount -u /workdir' TERM INT\n  mkdir /workdir\n  gocryptfs /workdir-enc /workdir\n  set +e\n  /opt/ort/bin/ort \"\\\$@\" &\n  PID=\\\$!\n  wait \\\$PID\n  wait \\\$PID\n  EXIT_STATUS=\\\$?\n  fusermount -u /workdir\n  exit \\\$EXIT_STATUS\nelse\n  exec /opt/ort/bin/ort \"\\\$@\" \nfi\n" > /opt/entrypoint.sh)

ENTRYPOINT ["/bin/bash", "/opt/entrypoint.sh"]
EOF
    else
        echo "docker image already build"
    fi
}

#################################################################################
# function to run dockerized ort commands
#################################################################################
prepareDotOrt() {
    declare -a types=("analyzer" "downloader" "scanner" )
    for type in ${types[@]}; do
        mkdir -p "$HOME/.ort/dockerHome/.ort/$type"
        if [[ ! -e "$HOME/.ort/$type" ]]; then
            ln -s "$HOME/.ort/dockerHome/.ort/$type" "$HOME/.ort/$type"
        fi
    done
}

getOutFolder() {
    local workdir="$(readlink -f "$1")"
    local out="${workdir%_ort}_ort"
    mkdir -p "$out"
    echo "$out"
}

runOrt() {
    local workdir="$(readlink -f "$1")"
    [[ ! -d "$workdir" ]] && exit 1
    shift

    if [[ "$workdir" == *"-enc" ]]; then
        workdirMountArgs="--device /dev/fuse --cap-add SYS_ADMIN -v $workdir:/workdir-enc"
    else
        workdirMountArgs="-v $workdir:/workdir"
    fi

    prepareDotOrt

    (set -x;
     docker run -i \
            --rm \
            -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -u $(id -u $USER):$(id -g $USER) \
            -v "$HOME/.ort/dockerHome":"$HOME" \
            $workdirMountArgs \
            -v "$(getOutFolder "$workdir")":/out \
            -w /workdir \
            --net=host \
            $tag $DEBUG_LEVEL \
            $@;
     times
     )
}

#################################################################################
# actual calls to ort features
#################################################################################
analyzeFolder() {
    local folderToScan="$(readlink -f "$1")"
    [[ ! -d "$folderToScan" ]] && exit 1

    printf "\n\n\nanalyze: $folderToScan\n\n"

    local logfile="$(getOutFolder "$folderToScan")/analyzer.logfile"
    runOrt "$folderToScan" \
           analyze -i /workdir --output-dir /out --output-formats JSON,YAML --allow-dynamic-versions |
        tee -a "$logfile"
}

downloadSource() {
    local analyzeResult="$(readlink -f "$1")"
    [[ ! -f "$analyzeResult" ]] && exit 1

    local analyzeResultFolder="$(dirname $analyzeResult)"
    local analyzeResultFile="$(basename $1)"
    local logfile="$(getOutFolder "$analyzeResultFolder")/downloader.logfile"
    runOrt "$analyzeResultFolder" \
           download --ort-file "$analyzeResultFile" --output-dir /out/downloads |
        tee -a "$logfile"
}

cleanAnalyzeGeneratedDirs() {
    local analyzeResultFolder="$1"
    shift
    if [[ -d "$analyzeResultFolder/native-scan-results" ]]; then
        rm -rf "$analyzeResultFolder/native-scan-results"
    fi
    if [[ -d "$analyzeResultFolder/downloads" ]]; then
        rm -rf "$analyzeResultFolder/downloads"
    fi
}

scanAnalyzeResult() {
    local analyzeResult="$(readlink -f "$1")"
    [[ ! -f "$analyzeResult" ]] && exit 1

    printf "\n\n\nscan: $analyzeResult\n\n"

    local analyzeResultFolder="$(dirname $analyzeResult)"
    local analyzeResultFile="$(basename $1)"
    local logfile="$(getOutFolder "$analyzeResultFolder")/scanner.logfile"

    cleanAnalyzeGeneratedDirs "$analyzeResultFolder"

    runOrt "$analyzeResultFolder" \
           scan  --ort-file "$analyzeResultFile" --output-dir /out --download-dir /out/downloads --output-formats JSON,YAML |
        tee -a "$logfile"

    cleanAnalyzeGeneratedDirs "$analyzeResultFolder"
}

reportScanResult() {
    local scanResult="$(readlink -f "$1")"
    [[ ! -f "$scanResult" ]] && exit 1

    printf "\n\n\nreport: $scanResult\n\n"

    local scanResultFolder="$(dirname $scanResult)"
    local scanResultFile="$(basename $1)"
    local logfile="$(getOutFolder "$scanResultFolder")/reporter.logfile"
    runOrt "$scanResultFolder" \
           report -f StaticHtml,WebApp,Excel,NoticeTemplate,SPDXDocument,GitLabLicensemodel,EVALUATEDMODELJSON,AMAZONOSSATTRIBUTIONBUILDER --ort-file "$scanResultFile" --output-dir /out |
        tee -a "$logfile"
}

doAll() {
    local folderToScan="$1"
    [[ ! -d "$folderToScan" ]] && exit 1

    local outFolder=$(getOutFolder "$folderToScan")
    if [[ ! -z "$2" ]]; then
        outFolder="$outFolder/$2"
        mkdir -p "$outFolder"
    fi

    local reportResult="$outFolder/scan-report-web-app.html"
    if [[ ! -f "$reportResult" ]]; then
        local scanResult="$outFolder/scan-result.yml"
        if [[ ! -f "$scanResult" ]]; then
            local analyzeResult="$outFolder/analyzer-result.yml"
            if [[ ! -f "$analyzeResult" ]]; then
                analyzeFolder "$folderToScan"
            else
                echo "skip analyze ..."
            fi
            scanAnalyzeResult "$analyzeResult"
        else
            echo "skip scan ..."
        fi
        reportScanResult "$scanResult"
    else
        echo "skip report ..."
    fi
}

doShort() {
    local folderToScan="$1"
    [[ ! -d "$folderToScan" ]] && exit 1

    local outFolder=$(getOutFolder "$folderToScan")

    local reportResult="$outFolder/scan-report-web-app.html"
    if [[ ! -f "$reportResult" ]]; then
        local analyzeResult="$outFolder/analyzer-result.yml"
        if [[ ! -f "$analyzeResult" ]]; then
            analyzeFolder "$folderToScan"
        else
            echo "skip analyze ..."
        fi
        reportScanResult "$scanResult" short
    else
        echo "skip report ..."
    fi
}

#################################################################################
# main
#################################################################################
buildImageIfMissing
case $1 in
    "--all") shift; doAll "$@" ;;
    "--short") shift; doShort "$@" ;;
    "--analyze") shift; analyzeFolder "$@" ;;
    "--download") shift; downloadSource "$@" ;;
    "--scan") shift; scanAnalyzeResult "$@" ;;
    "--report") shift; reportScanResult "$@" ;;
    "--help") helpMsg ;;
    *) runOrt "$(pwd)" "$@" ;;
esac
times
