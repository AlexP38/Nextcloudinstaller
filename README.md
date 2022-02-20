Automatically set up a Nextcloud with working Collabora Office inside lxd-Containers.

git clone https://github.com/AlexP38/Nextcloudinstaller
cd Nextcloudinstaller
sh create-lxd-container-with-nextcloud-and-collabora.sh   (to create a new Nextcloud)
sh DeleteContainer.sh    (to delete a Nextcloud)

After this script it is ready to use. No more action is required.

You need a Linux-Server with lxd installed and either a lxd container with running apache and certbot as reverse proxy (also dont forget to forward http and https ports to this reverse-Proxy) or apache and certbot and python3-certbot-apache running on the host as proxy. The script will insert automatically a vhost to the apache to activate the proxy and request a certificate for https.
