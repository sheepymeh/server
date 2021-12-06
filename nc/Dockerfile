FROM nextcloud:fpm

RUN apt-get update && apt-get install -y \
    supervisor \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord

VOLUME /var/www/html

ENV MYSQL_DATABASE=nextcloud
ENV MYSQL_USER=nextcloud
ENV MYSQL_HOST=host.docker.internal:3306

COPY supervisord.conf /

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
