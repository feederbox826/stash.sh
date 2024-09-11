FROM alpine
RUN apk add --no-cache bash curl watchexec jq
COPY ./stash.sh /stash.sh
CMD ["/stash.sh"]