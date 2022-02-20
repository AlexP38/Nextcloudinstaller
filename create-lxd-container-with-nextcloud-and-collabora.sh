#/bin/bash
diff=""
while [ $diff != "Y" && != "N" ]
do
read -p 'Do you want Nextcloud and Collabora in different Containers? (Y/N)' diff
done
if [ $diff = "N" ]
then
read -p 'lxd-Container-Name: ' container
container2=$container
else
read -p 'lxd-Nextcloud-Container-Name: ' container
read -p 'lxd-Collabora-Container-Name: ' container2
fi
password=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
read -p 'Domain (without https://): ' domain
read -p 'Split the Domain into the part before .de / .com / .net etc. without subdomain (e.g. google for cloud.google.com / microsoft for xyz.microsoft.net: ' fqn
read -p 'Now what is the ending? e.g. de / com / net (without a .):' tdl
read -p 'Where is your reverse-proxy? (You need an apache2 and certbot installed) Tell me the container name or if on the host leave blank and just press enter:' revproxy
read -p 'Admin-Username: ' adminuser
read -p 'Admin-Password: ' adminpassword
lxc init images:debian/11 $container
lxc start $container
if [ $diff = "Y" ]
then
lxc init images:debian/11 $container2
lxc start $container2
fi
ContainerIP=$(lxc list "$container" -c 4 | awk '!/IPV4/{ if ( $2 != "" ) print $2}')
while [ $ContainerIP = '|' ]
do
echo "Waiting for container IP"
sleep 8
ContainerIP=$(lxc list "$container" -c 4 | awk '!/IPV4/{ if ( $2 != "" ) print $2}')
done
lxc file push vhost.conf $container/root/vhost.conf
lxc file push collaboraonline.sources $container2/root/collaboraonline.sources
lxc exec $container -- sh -c 'apt-get -qq install -y wget && \
 apt-get -qq -y install mariadb-server mariadb-client nano curl unzip php php-cli php-xml php-zip php-curl php-gd php-cgi php-mysql php-mbstring php-intl php-bcmath php-gmp php-imagick apache2 libapache2-mod-php sed && \
mysql --user="root" --execute="CREATE USER \"nextcloud\"@\"localhost\" IDENTIFIED BY \"'"$password"'\"; CREATE DATABASE nextcloud; GRANT ALL PRIVILEGES ON nextcloud.* TO \"nextcloud\"@\"localhost\"; FLUSH PRIVILEGES;" && \
a2enmod headers && \
a2dissite 000-default.conf && \
sed -i -r "s/memory_limit = .*/memory_limit = 512M/" /etc/php/*/apache2/php.ini && \
sed -i -r "s/upload_max_filesize = .*/upload_max_filesize = 500M/" /etc/php/*/apache2/php.ini && \
sed -i -r "s/post_max_size = .*/post_max_size = 500M/" /etc/php/*/apache2/php.ini && \
sed -i -r "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/*/apache2/php.ini && \
curl -o nextcloud-23.zip https://download.nextcloud.com/server/releases/latest-23.zip && \
unzip -qq nextcloud-23.zip && \
mv nextcloud /var/www/ && \
chown -R www-data:www-data /var/www/nextcloud && \
chmod -R 755 /var/www/nextcloud && \
rm -r nextcloud-23.zip && \
mv /root/vhost.conf /etc/apache2/sites-available/000-nextcloud.conf && \
sed -i -r "s/replacewithdomain/'"$domain"'/g" /etc/apache2/sites-available/000-nextcloud.conf && \
a2ensite 000-nextcloud.conf && \
systemctl restart apache2'
if [ $diff = "Y" ]
then
ContainerIP2=$(lxc list "$container2" -c 4 | awk '!/IPV4/{ if ( $2 != "" ) print $2}')
while [ $ContainerIP2 = '|' ]
do
echo "Waiting for collabora-container IP"
sleep 2
ContainerIP=$(lxc list "$container" -c 4 | awk '!/IPV4/{ if ( $2 != "" ) print $2}')
done
fi
lxc exec $container2 -- sh -c 'apt-get -qq install -y wget && \
wget https://collaboraoffice.com/downloads/gpg/collaboraonline-release-keyring.gpg -P /usr/share/keyrings && \
mv /root/collaboraonline.sources /etc/apt/sources.list.d/collaboraonline.sources && \
apt-get -qq update && \
apt-get -qq install -y nano curl unzip coolwsd code-brand sed && \
sed -i -r "s/<termination desc=\"Connection via proxy where coolwsd acts as working via https, but actually uses http.\" type=\"bool\" default=\"true\">false<\/termination>/<termination desc=\"Connection via proxy where coolwsd acts as working via https, but actually uses http.\" type=\"bool\" default=\"true\">true<\/termination>/" /etc/coolwsd/coolwsd.xml && \
sed -i -r "s/SSL support to enable.\" default=\"true\">true<\/enable>/SSL support to enable.\" default=\"true\">false<\/enable>/" /etc/coolwsd/coolwsd.xml && \
sed -i -r "s/<wopi desc=\"Allow\\/deny wopi storage.\" allow=\"true\">/<wopi desc=\"Allow\\/deny wopi storage.\" allow=\"true\">\n<host desc=\"Regex pattern of hostname to allow or deny.\" allow=\"true\">(?:.*\\\.)?'"$fqn"'\\\.'"$tdl"'<\/host>/" /etc/coolwsd/coolwsd.xml && \
systemctl restart coolwsd'
if [ $revproxy != "" ]
then
lxc file push vhost-reverse-proxy.conf $revproxy/root/vhost-reverse-proxy.conf
lxc exec $revproxy -- sh -c 'mv /root/vhost-reverse-proxy.conf /etc/apache2/sites-available/000-nextcloud-container.conf && \
sed -i -r "s/replacewithdomain/'"$domain"'/g" /etc/apache2/sites-available/000-nextcloud-container.conf && \
sed -i -r "s/replacewithcontainer/'"$container"'/g" /etc/apache2/sites-available/000-nextcloud-container.conf && \
sed -i -r "s/replacewithcollaboracontainer/'"$container2"'/g" /etc/apache2/sites-available/000-nextcloud-container.conf && \
certbot certonly -d $domain --apache && \
a2ensite 000-nextcloud-container.conf && \
systemctl reload apache2'
else
cp vhost-reverse-proxy.conf /etc/apache2/sites-available/000-nextcloud-container.conf && \
sed -i -r 's/replacewithdomain/'"$domain"'/g' /etc/apache2/sites-available/000-nextcloud-container.conf && \
sed -i -r 's/replacewithcontainer/'"$ContainerIP"'/g' /etc/apache2/sites-available/000-nextcloud-container.conf && \
sed -i -r 's/replacewithcollaboracontainer/'"$ContainerIP2"'/g' /etc/apache2/sites-available/000-nextcloud-container.conf && \
certbot certonly -d $domain --apache && \
a2ensite 000-nextcloud-container.conf && \
systemctl reload apache2
fi
lxc exec $container -- sh -c 'sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name "nextcloud" --database-user "nextcloud" --database-pass "'"$password"'" --admin-user "'"$adminuser"'" --admin-pass "'"$adminpassword"'" && \
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 1 --value='$domain' && \
sudo -u www-data php /var/www/nextcloud/occ app:install richdocuments && \
sudo -u www-data php /var/www/nextcloud/occ config:app:set --value "https://"'$domain'"" richdocuments wopi_url'
echo "Done. Got to https://$domain and set up your nextcloud with an admin user. Collabora Office is already set up and running."
