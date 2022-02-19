#/bin/bash
read -p 'lxd-Container-Name: ' container
read -sp 'Mysql-Password: ' password
read -p 'Domain: ' domain
read -p 'Split the Domain into the part before .de / .com / .net etc. without subdomain (e.g. google for cloud.google.com / microsoft for xyz.microsoft.net: ' fqn
read -p 'Now what is the ending? e.g. de / com / net (without a .):' tdl
read -p 'Where is your reverse-proxy? (You need an apache2 and certbot installed) Tell me the container name or if on the host say "host":' revproxy
lxc init images:debian/11 $container
lxc start $container
lxc exec $container /bin/bash
cd /usr/share/keyrings
wget https://collaboraoffice.com/downloads/gpg/collaboraonline-release-keyring.gpg
cp collaboraonline.sources > /etc/apt/sources.list.d/collaboraonline.sources
apt update && apt -y install mariadb-server mariadb-client nano wget curl unzip php php-{cli,xml,zip,curl,gd,cgi,mysql,mbstring} apache2 libapache2-mod-php coolwsd code-brand
mysql --user="root" --execute="CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$password'; CREATE DATABASE nextcloud; GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost'; FLUSH PRIVILEGES;"
a2enmod headers
a2dissite 000-default.conf
sed -i -r 's/memory_limit = .*/memory_limit = 512M/' /etc/php/*/apache2/php.ini
sed -i -r 's/upload_max_filesize = .*/upload_max_filesize = 500M/' /etc/php/*/apache2/php.ini
sed -i -r 's/post_max_size = .*/post_max_size = 500M/' /etc/php/*/apache2/php.ini
sed -i -r 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/*/apache2/php.ini
curl -o nextcloud-23.zip https://download.nextcloud.com/server/releases/latest-23.zip
unzip nextcloud-23.zip
sudo mv nextcloud /var/www/
sudo chown -R www-data:www-data /var/www/nextcloud
sudo sudo chmod -R 755 /var/www/nextcloud
rm -r nextcloud-23.zip
cp vhost.conf > /etc/apache2/sites-available/000-nextcloud.conf
sed -i -r 's/replacewithdomain/$domain/g' /etc/apache2/sites-available/000-nextcloud.conf
a2ensite 000-nextcloud.conf
systemctl restart apache2
sed -i -r 's/<termination desc="Connection via proxy where coolwsd acts as working via https, but actually uses http." type="bool" default="true">false</termination>/<termination desc="Connection via proxy where coolwsd acts as working via https, but actually uses http." type="bool" default="true">true</termination>/' /etc/coolwsd/coolwsd.xml
sed -i -r 's/SSL support to enable." default="true">ture</enable>/SSL support to enable." default="true">false</enable>/' /etc/coolwsd/coolwsd.xml
sed '/<wopi desc="Allow/deny wopi storage." allow="true">/ a <host desc="Regex pattern of hostname to allow or deny." allow="true">(?:.*\.)?$fqn\.$tdl</host>' /etc/coolwsd/coolwsd.xml
systemctl restart coolwsd
exit
if [ $revproxy != 'host' ]
then
lxc exec $revproxy /bin/bash
fi
cp vhost-reverse-proxy.conf > /etc/apache2/sites-available/000-nextcloud-container.conf
sed -i -r 's/replacewithdomain/$domain/g' /etc/apache2/sites-available/000-nextcloud-container.conf
sed -i -r 's/replacewithcontainer/$container/g' /etc/apache2/sites-available/000-nextcloud-container.conf
certbot certonly -d $domain --apache
a2ensite 000-nextcloud-container.conf
systemctl reload apache2
if [ $revproxy != 'host' ]
then
exit
fi
echo 'Done. Got to https://$domain and set up your nextcloud with a admin user and the database credentials user: nextcloud, password: $password and database-name: nextcloud.'
