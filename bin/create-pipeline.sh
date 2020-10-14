#!/bin/bash

set -euo pipefail

export SERVICE="."
export PIPELINE_TYPE=""
export REPOSITORY=git@github.com:steven-ph/buildkite-github-action.git

CURRENT_DIR=$(pwd)
ROOT_DIR="$( dirname "${BASH_SOURCE[0]}" )"/..
STATUS_CHECK=false
BUILDKITE_ORG_SLUG=someorgslug # update to your buildkite org slug

USAGE="USAGE: $(basename "$0") [-s|--service] service_name [-t|--type] pipeline_type

Eg: create-pipeline --type pull-request
    create-pipeline --type merge --service foo-service
    create-pipeline --type merge --status-checks

NOTE: BUILDKITE_TOKEN must be set in environment

ARGUMENTS:
    -t | --type           buildkite pipeline type <merge|pull-request|deploy> (required)
    -s | --service        service name (optional, default: deploy root pipeline)
    -r | --repository     github repository url (optional, default: buildkite-github-action)
    -c | --status-checks      enable github status checks (optional, default: true)
    -h | --help           show this help text"

[ -z $BUILDKITE_TOKEN ] && { echo "BUILDKITE_TOKEN is not set."; exit 1;}

while [ $# -gt 0 ]; do
    if [[ $1 =~ "--"* ]]; then
        case $1 in
            --help|-h) echo "$USAGE"; exit; ;;
            --service|-s) SERVICE=$2;;
            --type|-t) PIPELINE_TYPE=$2;;
            --repository|-r) REPOSITORY=$2;;
            --status-check|-c) STATUS_CHECK=${2:-true};;
        esac
    fi
    shift
done

[ -z "$PIPELINE_TYPE" ] && { echo "$USAGE"; exit 1; }

export PIPELINE_NAME=$([ $SERVICE == "." ] && echo "" || echo "$SERVICE-")$PIPELINE_TYPE

BUILDKITE_CONFIG_FILE=.buildkite/pipelines/$PIPELINE_TYPE.json
[ ! -f "$BUILDKITE_CONFIG_FILE" ] && { echo "Invalid pipeline type: File not found $BUILDKITE_CONFIG_FILE"; exit; }

BUILDKITE_CONFIG=$(cat $BUILDKITE_CONFIG_FILE | envsubst)

if [ $STATUS_CHECK == "false" ]; then
  pipeline_settings='{ "provider_settings": { "trigger_mode": "none" } }'
  BUILDKITE_CONFIG=$((echo $BUILDKITE_CONFIG; echo $pipeline_settings) | jq -s add)
fi

cd $ROOT_DIR

echo "Creating $PIPELINE_TYPE pipeline.."
RESPONSE=$(curl -s POST "https://api.buildkite.com/v2/organizations/$BUILDKITE_ORG_SLUG/pipelines" \
  -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  -d "$BUILDKITE_CONFIG"
)

[[ "$RESPONSE" == *errors||message* ]] && { echo $RESPONSE | jq; exit 1; }

echo "done."

cd $CURRENT_DIR

unset REPOSITORY
unset PIPELINE_TYPE
unset SERVICE
unset PIPELINE_NAME
