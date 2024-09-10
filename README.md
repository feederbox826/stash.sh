# stash.sh

a shell script to make stash management easier

## usage
```sh
stash.sh scan /mnt/data /mnt/otherdata
stash.sh generate
```

scan and generate options are taken from stash defaults and can be overridden in `config.sh`

## download
direct:
```sh
wget https://raw.githubusercontent.com/feederbox826/stash.sh/main/stash.sh
wget https://raw.githubusercontent.com/feederbox826/stash.sh/main/.env.example.sh -O .env.sh
stash.sh generate
```

docker:
```
docker run ghcr.io/feederbox826/stash-sh generate
```
