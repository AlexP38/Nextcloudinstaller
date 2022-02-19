#/bin/bash
read -p 'Container-Name: ' container
a2dissite 000-nextcloud-container.conf
systemctl restart apache2
rm /etc/apache2/sites-available/000-nextcloud-container.conf
lxc stop $container && lxc delete $container
