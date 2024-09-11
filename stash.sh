#!/usr/bin/env bash
# https://feederbox.cc/gh/stash.sh
# requires cURL, jq to parse config
# requires watchexec to watch for changes
# https://github.com/watchexec/watchexec

__help="
stash.sh - a script to interact with stash | feederbox.cc/gh/stash.sh
v0.2.0
Usage: $0 [COMMAND] [PATHS]...
Commands:
  generate - generate supporting content
  scan - scan [PATHS] for metadata
  watch - watch [PATHS] for changes and scan
Options:
  [PATH] list of paths to scan or watch, seperated by space

example:
  $0 scan /path/to/scan /path/to/scan2
  $0 watch /path/to/watch /path/to/watch2
  $0 generate
"

__envsh_help="
check your .env.sh file or environment variables
STASH_URL should point to the /graphql endpoint of your stash instance
  eg: http://localhost:9999/graphql
STASH_APIKEY should be a valid apikey for your stash instance
"

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

start() {
  if [ -z "$STASH_URL" ] || [ -z "$STASH_APIKEY" ]; then
    echo "stash url and apikey not found"
    echo "$__envsh_help"
    exit 1
  fi
  healthcheck
  status=$?
  if [ $status -ne 0 ]; then
    echo "stash is not available"
    echo "$__envsh_help"
    exit 1
  fi
  config
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

watch() {
  # check if waschexec exists
  if ! command -v watchexec &> /dev/null; then
    echo "watchexec not found"
    echo "install watchexec from https://github.com/watchexec/watchexec/releases"
    exit 1
  fi
  # extract paths from arguments
  path=( "$@" )
  # convert paths to string-escaped json
  JSON_PATHS=$(printf '\\"%s\\",' "${path[@]}")
  # launch stash.sh scan <path> on file change
  watchexec --watch "${path[@]}" --restart "$0" scan "${path[@]}"
}

# run main commands
if [ -f .env.sh ]; then
  source .env.sh
fi

start
cmd=$1; shift
case "$cmd" in
  generate)
    generate
    ;;
  scan)
    scan "$@"
    ;;
  watch)
    watch "$@"
    ;;
  *)
    echo "$__help"
    exit 1
    ;;
esac