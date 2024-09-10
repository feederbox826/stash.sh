FROM alpine
RUN apk add --no-cache bash curl jq
COPY ./stash.sh /stash.sh
CMD ["/stash.sh"]