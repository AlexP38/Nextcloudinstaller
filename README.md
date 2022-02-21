<h1>Automatically set up a Nextcloud with working Collabora Office inside lxd-Containers.</h1>

<h2>You need a Linux-Server with lxd installed and running.</h2>

1. Clone the Repro:
```
git clone https://github.com/AlexP38/Nextcloudinstaller
cd Nextcloudinstaller
```
 2. If you need a reverse Proxy and haven't already installed one, run the following script first: <br>(Otherwise you need either a lxd container with running apache, certbot and python3-certbot-apache (also dont forget to forward http and https ports to this reverse-Proxy) or apache, certbot and python3-certbot-apache running on the host as proxy. The script will insert automatically a vhost into apache to activate the proxy and also request a certificate for https using certbot. 
```
sh create-reverse-proxy-container.sh 
```
3. To create a new Nextcloud with Collabora run this script: (The script will ask you about Setup-Details.)
```
sh create-lxd-container-with-nextcloud-and-collabora.sh
```
After this script your Nextcloud is ready to use. No more action is required.<br>
Only if you use special firewall-Rules make sure to allow using Port 443 for the containers.

<br><br>
To automatically delete the Container(s) and Apache-Config run this (CAN'T BE UNDONE!!!):
```
sh DeleteContainer.sh
```