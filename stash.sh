#!/usr/bin/env bash
# requires cURL, jq to parse config

if [ -f .env.sh ]; then
  source .env.sh
fi

stash() {
  query=$1
  curl \
    --silent \
    --show-error \
    --insecure \
    -X POST "$STASH_URL" \
    -H "Content-Type: application/json" \
    -H "ApiKey: $STASH_APIKEY" \
    -d "{\"query\":\"$query\"}"
}

start() {
  if [ -z "$STASH_URL" ] || [ -z "$STASH_APIKEY" ]; then
    echo "stash url and apikey not found"
    echo "check your stash url and apikey in .env.sh"
    exit 1
  fi
  healthcheck
  status=$?
  if [ $status -ne 0 ]; then
    echo "stash is not available"
    echo "check your stash url and apikey in .env.sh"
    exit 1
  fi
  config
}

config() {
  if [ -f "config.sh" ]; then
    source config.sh
  else
    echo "config.sh not found"
    echo "creating config.sh from stash api"
    getconfig
  fi
}

healthcheck() {
  stash 'query { version { version }}' > /dev/null
}

scan() {
  path=( "$@" )
  JSON_PATHS=$(printf '\\"%s\\",' "${path[@]}")
  gql_input="{ paths: [${JSON_PATHS:0:-1}] ${PARSED_SCAN_OPTIONS:1}"
  stash "mutation { metadataScan(input: $gql_input) }" > /dev/null
}

generate() {
  stash "mutation { metadataGenerate(input: $PARSED_GEN_OPTIONS) }" > /dev/null
}

getconfig() {
  GENERATE_OPTIONS='covers sprites previews imagePreviews markers markerImagePreviews markerScreenshots transcodes phashes interactiveHeatmapsSpeeds imageThumbnails clipPreviews'
  SCAN_OPTIONS='scanGenerateCovers scanGeneratePreviews scanGenerateImagePreviews scanGenerateSprites scanGeneratePhashes scanGenerateThumbnails scanGenerateClipPreviews'
  CONFIG_OUTPUT=$(stash "query { configuration { defaults { generate { $GENERATE_OPTIONS } scan { $SCAN_OPTIONS }}}}")
  # output to config.sh
  PARSED_SCAN_OPTIONS=$(echo "$CONFIG_OUTPUT" | jq -rc '.data.configuration.defaults.scan' | tr -d '"')
  PARSED_GEN_OPTIONS=$(echo "$CONFIG_OUTPUT" | jq -rc '.data.configuration.defaults.generate' | tr -d '"')
  echo "#!/bin/sh" > config.sh
  echo "export PARSED_GEN_OPTIONS=\"$PARSED_GEN_OPTIONS\"" >> config.sh
  echo "export PARSED_SCAN_OPTIONS=\"$PARSED_SCAN_OPTIONS\"" >> config.sh
}

# run main commands
cmd=$1; shift
case "$cmd" in
  generate)
    generate
    ;;
  scan)
    scan "$@"
    ;;
  *)
    echo "Usage: $0 generate | scan <path> [path]..."
    exit 1
    ;;
esac