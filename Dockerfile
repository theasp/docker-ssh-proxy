FROM alpine:latest
RUN apk update && apk add openssh-client bash sshpass && rm -rf /var/cache/apk/*
COPY start.sh lib.sh /
CMD /start.sh
