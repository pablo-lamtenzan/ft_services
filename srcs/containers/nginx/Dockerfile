FROM alpine:latest

RUN apk update && apk add nginx && apk add --no-cache --upgrade bash \
&& apk add openssl && mkdir -p var/run/nginx && apk add openssl openssh \
&& rm -rf /var/cache/apk/*

RUN adduser -D -g 'www' www \
&& mkdir /www && chown -R www:www /var/lib/nginx \
&& chown -R www:www /www

RUN mkdir /etc/nginx/ssl \
&& openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out /etc/nginx/ssl/www.pem -keyout /etc/nginx/ssl/www.key -subj "/C=FR/ST=Lyon/L=Paris/O=42 School/OU=plamtenz/CN=ft_services"

RUN rm /etc/nginx/nginx.conf

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY id_rsa_key_ssh /etc/ssh/ssh_host_rsa_key
COPY sshd_config /etc/ssh/

COPY setup.sh .

RUN chmod +x setup.sh
RUN chmod 600 /etc/ssh/ssh_host_rsa_key

EXPOSE 1234 80 443
CMD ./setup.sh