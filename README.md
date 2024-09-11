# stash.sh

a shell script to make stash management easier

## usage
```
stash.sh - a script to interact with stash | feederbox.cc/gh/stash.sh
Usage: stash.sh [COMMAND] [PATHS]...
Commands:
  generate - generate supporting content
  scan - scan [PATHS] for metadata
  watch - watch [PATHS] for changes and scan
Options:
  [PATH] list of paths to scan or watch, seperated by space

example:
  stash.sh scan /path/to/scan /path/to/scan2
  stash.sh watch /path/to/watch /path/to/watch2
  stash.sh generate
```

scan and generate options are taken from stash defaults and can be overridden in `config.sh`

## download
direct:
```
wget https://raw.githubusercontent.com/feederbox826/stash.sh/main/stash.sh
wget https://raw.githubusercontent.com/feederbox826/stash.sh/main/.env.example.sh -O .env.sh
stash.sh generate
```

docker:
```
docker run ghcr.io/feederbox826/stash-sh generate
```
