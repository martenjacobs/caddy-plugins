#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG plugins="git,filemanager,cors,realip,expires,cache"

# process wrapper
RUN go get -v github.com/abiosoft/parent

RUN PLUGINS=${plugins} /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:3.7
LABEL maintainer "Abiola Ibrahim <abiola89@gmail.com>"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2015
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html

# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
