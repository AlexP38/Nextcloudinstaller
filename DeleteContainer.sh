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
read -p 'Where is your reverse-proxy? (You need an apache2 and certbot installed) Tell me the container name or if on the host leave blank and just press enter:' revproxy

if [ "$revproxy" != "" ]
then
lxc exec $revproxy -- sh -c 'a2dissite '"$container"'-'"$container2"'-container.conf && \
systemctl reload apache2 && \
rm /etc/apache2/sites-available/'"$container"'-'"$container2"'-container.conf'
else
sudo a2dissite "$container"-"$container2"-container.conf
sudo systemctl reload apache2
sudo rm /etc/apache2/sites-available/"$container"-"$container2"-container.conf
fi
lxc stop $container && lxc delete $container
if [ $diff = "Y" ]
then
lxc stop $container2 && lxc delete $container2
fi
