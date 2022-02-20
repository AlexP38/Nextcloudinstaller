#/bin/bash
read -p 'Container-Name: ' container
read -p 'E-Mail für letsencrypt: ' mail
lxc init images:debian/11 $container
lxc config device add $container myport80 proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
lxc config device add $container myport443 proxy listen=tcp:0.0.0.0:443 connect=tcp:127.0.0.1:443
lxc exec $container -- sh -c 'apt install apache2 certbot python3-certbot-apache && \
certbot register --email '"$mail"' --agree-tos && \
a2enmod proxy proxy_wstunnel ssl headers rewrite proxy_http'
