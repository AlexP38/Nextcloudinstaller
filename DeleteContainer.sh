#/bin/bash
diff=""
while [ "$diff" != "Y" ] && [ "$diff" != "N" ]
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
a2dissite 000-nextcloud-container.conf
systemctl restart apache2
rm /etc/apache2/sites-available/000-nextcloud-container.conf
lxc stop $container && lxc delete $container
if [ $diff = "Y" ]
then
lxc stop $container2 && lxc delete $container2
fi
