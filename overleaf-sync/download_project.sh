#!/bin/bash

# Default configuration (override these using environment variables passed to script):
DEFAULT_GIT_URL="git@github.com:kamil271e/thesis-backup.git"
DEFAULT_OVERLEAF_PROJECT="6526ee300d923bdfd54986a4"
# DEFAULT_SESSION="s%3AqJInreH5vT_bJEL1kT-QKibLf_Ujz0np.ZT%2BB4joK7tIYHUMy3MZhxK%2Fn7SNCNjdxaBzgIvwvoQE"

if [ -z "$1" ]; then
    echo "Usage: $0 <session>"
    exit 1
fi

DEFAULT_SESSION="$1"
echo $DEFAULT_SESSION

set -e

# Easy layered configuration mechanism. Fallback to above DEFAULTs if no environment variable is set:
fallback() {
    if [[ -z "$1" ]]; then
        echo "$2" 
    else
        echo "$1"
    fi
}
GIT_URL=$(fallback "$GIT_URL" "$DEFAULT_GIT_URL")
OVERLEAF_PROJECT=$(fallback "$OVERLEAF_PROJECT" "$DEFAULT_OVERLEAF_PROJECT")
SESSION=$(fallback "$SESSION" "$DEFAULT_SESSION")

AUTO=false
if [[ "$1" =~ ^.*auto.*$ ]]; then
    echo "Automatic sync enabled."
    AUTO=true
fi

validate() {
    if [[ "${GIT_URL}" =~ ^.+git$ ]]; then
        echo "GIT_URL: ${GIT_URL}"
    else
        echo "Please pass a valid GIT_URL (ending with '.git')"
        exit 1
    fi
    if [[ "${OVERLEAF_PROJECT}" =~ ^[a-f0-9]{24}$ ]]; then
        echo "OVERLEAF_PROJECT: ${OVERLEAF_PROJECT}"
    else
        echo "Please pass a valid OVERLEAF_PROJECT (ID consisting of 24 hex chars)"
        exit 2
    fi
#     if [[ "${SESSION}" =~ ^s%[a-zA-Z0-9\.]{12,}$ ]]; then
    if [[ "${SESSION}" =~ ^[s%:].{12,}$ ]]; then
        echo "SESSION: ${SESSION}"
    else
        echo "Please pass a valid SESSION (starting with 's%')"
        exit 3
    fi
}

validate

sync() {
    curl "https://www.overleaf.com/project/${OVERLEAF_PROJECT}/download/zip" -H "origin: https://www.overleaf.com" \
        -K base.cmdline -H "cookie: overleaf_session2=${SESSION}" --compressed > overleaf-project.zip
    if [[ $(stat --printf="%s" overleaf-project.zip) -lt 100 ]]; then
        echo "Warning: Downloaded response (archive) is smaller than excepted."
        if [[ $(cat overleaf-project.zip) == *"Forbidden"* ]]; then
            echo ">> Access seems to be forbidden. This is likely due to an invalid session."
            echo ">> It is recommended to update your session as described in the README!"
            exit 10
        fi
    fi
    unzip -o overleaf-project.zip -d ../thesis
    rm overleaf-project.zip
    git add .
    git commit -m "Sync with Overleaf project"
    echo "Ready to push !"
}

sync
