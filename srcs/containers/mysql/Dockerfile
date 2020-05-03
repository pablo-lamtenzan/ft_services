FROM alpine:latest

RUN apk update && apk add mariadb mariadb-client && apk add --no-cache --upgrade bash \
&& rm -rf /var/cache/apk/*

COPY ./init_docker.sh .
COPY ./init_mysql.sh .
COPY wp.sql .

RUN chmod 777 init_docker.sh
RUN chmod 777 init_mysql.sh

EXPOSE 3306

ENTRYPOINT [ "./init_docker.sh" ]