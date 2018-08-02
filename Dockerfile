#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG version="0.11.0"
ARG plugins="git,filemanager,cors,realip,expires,cache,http.login,http.jwt"

# process wrapper
RUN go get -v github.com/abiosoft/parent

RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=false /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:3.8
LABEL maintainer "Abiola Ibrahim <abiola89@gmail.com>"

ARG version="0.11.0"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

# Telemetry Stats
ENV ENABLE_TELEMETRY="false"

RUN apk add --no-cache openssh-client git tar php7-fpm curl

# essential php libs
RUN apk add --no-cache php7-curl php7-dom php7-gd php7-ctype php7-zip php7-xml php7-iconv php7-sqlite3 php7-mysqli php7-pgsql php7-json php7-phar php7-openssl php7-pdo php7-pdo_mysql php7-session php7-mbstring php7-bcmath php7-tokenizer

# symblink php7 to php
RUN ln -sf /usr/bin/php7 /usr/bin/php

# symlink php-fpm7 to php-fpm
RUN ln -sf /usr/bin/php-fpm7 /usr/bin/php-fpm

# composer
RUN curl --silent --show-error --fail --location \
      --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" \
      "https://getcomposer.org/installer" \
    | php -- --install-dir=/usr/bin --filename=composer

# allow environment variable access.
RUN echo "clear_env = no" >> /etc/php7/php-fpm.conf

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins


EXPOSE 80 443 2015
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.php /srv/index.php

# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
