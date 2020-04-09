#!/bin/bash
echo "#####################################"
echo "installing dependencies"
echo "#####################################"
apt-get install apache2 php libapache2-mod-php -y
apt-get install php-imap php-ldap php-curl php-xmlrpc php-gd php-mysql php-cas -y
apt-get install mariadb-server -y
apt-get install apcupsd php-apcu -y
apt-get install php-mbstring -y
apt-get install php-xml -y
echo "
<Directory /var/www/html/glpi>
        Options Indexes FollowSymLinks
        AllowOverride limit
        Require all granted
</Directory>
" >> /etc/apache2/apache2.conf
#
# DO NOT WORK
#
#apt-get install phpmyadmin -y
echo "#####################################"
echo "securising mariadb-server"
echo "#####################################"
# you can try to add this : https://gist.github.com/Mins/4602864 
apt install expect -y
MYSQL_ROOT_PASSWORD=root
SECURE_MYSQL=$(expect -c "

set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"$MYSQL\r\"

expect \"Change the root password?\"
send \"n\r\"

expect \"Remove anonymous users?\"
send \"y\r\"

expect \"Disallow root login remotely?\"
send \"y\r\"

expect \"Remove test database and access to it?\"
send \"y\r\"

expect \"Reload privilege tables now?\"
send \"y\r\"

expect eof
")
echo "$SECURE_MYSQL"
apt purge expect -y
echo "#####################################"
echo "restarting servies"
echo "#####################################"
/etc/init.d/apache2 restart
/etc/init.d/mysql restart
# create database 
mysql -uroot <<MYSQL_SCRIPT
create database glpidb;
grant all privileges on glpidb.* to glpiuser@localhost identified by "glpipassword";
quit
MYSQL_SCRIPT
echo "#####################################"

echo "database name : glpidb "

echo "database user : glpiuser and password : glpipassword"

echo "#####################################"

echo "#####################################"
echo "setup web server"
echo "#####################################"
# https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
cd /usr/src/
wget https://github.com/glpi-project/glpi/releases/download/9.4.5/glpi-9.4.5.tgz
tar -xvzf glpi-9.4.5.tgz -C /var/www/html
chown -R www-data:www-data /var/www/html/glpi/
echo "plase no open http://127.0.0.1/glpi/ in you borwser and finish the installation"
echo "
     glpi/glpi pour le compte administrateur
    tech/tech pour le compte technicien
    normal/normal pour le compte normal
    post-only/postonly pour le compte postonly

"
