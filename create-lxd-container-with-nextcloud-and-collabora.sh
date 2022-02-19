#/bin/bash
read -p 'lxd-Container-Name: ' container
read -p 'Mysql-Password: ' password
read -p 'Domain: ' domain
read -p 'Split the Domain into the part before .de / .com / .net etc. without subdomain (e.g. google for cloud.google.com / microsoft for xyz.microsoft.net: ' fqn
read -p 'Now what is the ending? e.g. de / com / net (without a .):' tdl
read -p 'Where is your reverse-proxy? (You need an apache2 and certbot installed) Tell me the container name or if on the host say "host":' revproxy
lxc init images:debian/11 $container
lxc start $container
ContainerIP=$(lxc list "$container" -c 4 | awk '!/IPV4/{ if ( $2 != "" ) print $2}')
while [ $ContainerIP = '|' ]
do
echo "Waiting for container IP"
sleep 7
ContainerIP=$(lxc list "$container" -c 4 | awk '!/IPV4/{ if ( $2 != "" ) print $2}')
done
lxc exec $container -- sh -c 'apt-get -qq install -y wget'
lxc exec $container -- sh -c 'wget https://collaboraoffice.com/downloads/gpg/collaboraonline-release-keyring.gpg -P /usr/share/keyrings'
lxc file push vhost.conf $container/root/vhost.conf
lxc file push collaboraonline.sources $container/root/collaboraonline.sources
lxc exec $container -- sh -c 'cp /root/collaboraonline.sources /etc/apt/sources.list.d/collaboraonline.sources'
lxc exec $container -- sh -c 'apt-get -qq update && apt-get -qq -y install mariadb-server mariadb-client nano curl unzip php php-cli php-xml php-zip php-curl php-gd php-cgi php-mysql php-mbstring apache2 libapache2-mod-php coolwsd code-brand sed'
lxc exec $container -- sh -c 'mysql --user="root" --execute="CREATE USER \"nextcloud\"@\"localhost\" IDENTIFIED BY \"'"$password"'\"; CREATE DATABASE nextcloud; GRANT ALL PRIVILEGES ON nextcloud.* TO \"nextcloud\"@\"localhost\"; FLUSH PRIVILEGES;"'
lxc exec $container -- sh -c 'a2enmod headers'
lxc exec $container -- sh -c 'a2dissite 000-default.conf'
lxc exec $container -- sh -c 'sed -i -r "s/memory_limit = .*/memory_limit = 512M/" /etc/php/*/apache2/php.ini'
lxc exec $container -- sh -c 'sed -i -r "s/upload_max_filesize = .*/upload_max_filesize = 500M/" /etc/php/*/apache2/php.ini'
lxc exec $container -- sh -c 'sed -i -r "s/post_max_size = .*/post_max_size = 500M/" /etc/php/*/apache2/php.ini'
lxc exec $container -- sh -c 'sed -i -r "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/*/apache2/php.ini'
lxc exec $container -- sh -c 'curl -o nextcloud-23.zip https://download.nextcloud.com/server/releases/latest-23.zip'
lxc exec $container -- sh -c 'unzip -qq nextcloud-23.zip'
lxc exec $container -- sh -c 'mv nextcloud /var/www/'
lxc exec $container -- sh -c 'chown -R www-data:www-data /var/www/nextcloud && chmod -R 755 /var/www/nextcloud'
lxc exec $container -- sh -c 'rm -r nextcloud-23.zip'
lxc exec $container -- sh -c 'cp /root/vhost.conf /etc/apache2/sites-available/000-nextcloud.conf'
lxc exec $container -- sh -c 'sed -i -r "s/replacewithdomain/'"$domain"'/g" /etc/apache2/sites-available/000-nextcloud.conf'
lxc exec $container -- sh -c 'a2ensite 000-nextcloud.conf'
lxc exec $container -- sh -c 'systemctl restart apache2'
lxc exec $container -- sh -c 'sed -i -r "s/<termination desc=\"Connection via proxy where coolwsd acts as working via https, but actually uses http.\" type=\"bool\" default=\"true\">false<\/termination>/<termination desc=\"Connection via proxy where coolwsd acts as working via https, but actually uses http.\" type=\"bool\" default=\"true\">true<\/termination>/" /etc/coolwsd/coolwsd.xml'
lxc exec $container -- sh -c 'sed -i -r s/SSL support to enable.\" default=\"true\">true<\/enable>/SSL support to enable.\" default=\"true\">false<\/enable>/" /etc/coolwsd/coolwsd.xml'
lxc exec Test -- sh -c 'sed -i -r "s/<wopi desc=\"Allow\\/deny wopi storage.\" allow=\"true\">/<wopi desc=\"Allow\\/deny wopi storage.\" allow=\"true\">\n<host desc=\"Regex pattern of hostname to allow or deny.\" allow=\"true\">(?:.*\\\.)?'"$fqn"'\\\.'"$tdl"'<\/host>/" /etc/coolwsd/coolwsd.xml'
lxc exec $container -- sh -c 'systemctl restart coolwsd'
if [ $revproxy != 'host' ]
then
lxc file push vhost-reverse-proxy.conf $revproxy/root/vhost-reverse-proxy.conf
lxc exec $revproxy -- sh -c 'cp /root/vhost-reverse-proxy.conf /etc/apache2/sites-available/000-nextcloud-container.conf'
lxc exec $revproxy -- sh -c 'sed -i -r "s/replacewithdomain/'"$domain"'/g" /etc/apache2/sites-available/000-nextcloud-container.conf'
lxc exec $revproxy -- sh -c 'sed -i -r "s/replacewithcontainer/'"$container"'/g" /etc/apache2/sites-available/000-nextcloud-container.conf'
lxc exec $revproxy -- sh -c 'certbot certonly -d $domain --apache'
lxc exec $revproxy -- sh -c 'a2ensite 000-nextcloud-container.conf'
lxc exec $revproxy -- sh -c 'systemctl reload apache2'
else
cp vhost-reverse-proxy.conf /etc/apache2/sites-available/000-nextcloud-container.conf
sed -i -r 's/replacewithdomain/'"$domain"'/g' /etc/apache2/sites-available/000-nextcloud-container.conf
sed -i -r 's/replacewithcontainer/'"$ContainerIP"'/g' /etc/apache2/sites-available/000-nextcloud-container.conf
certbot certonly -d $domain --apache
a2ensite 000-nextcloud-container.conf
systemctl reload apache2
fi
echo "Done. Got to https://$domain and set up your nextcloud with a admin user and the database credentials user: nextcloud, password: $password and database-name: nextcloud."
