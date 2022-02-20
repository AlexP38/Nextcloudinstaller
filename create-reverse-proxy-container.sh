#/bin/bash
lxc config device add reverse-proxy myport80 proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
lxc config device add reverse-proxy myport443 proxy listen=tcp:0.0.0.0:443 connect=tcp:127.0.0.1:443
apt install apache2 certbot python3-certbot-apache
certbot register --email webmastermini@paltian.net --agree-tos
a2enmod proxy proxy_wstunnel ssl headers rewrite
