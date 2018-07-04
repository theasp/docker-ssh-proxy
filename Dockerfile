FROM alpine:latest
RUN apk --no-cache add openssh-client bash sshpass netcat-openbsd
COPY start.sh lib.sh /
CMD /start.sh
