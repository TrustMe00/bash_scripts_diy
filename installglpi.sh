#!/bin/bash
# title : installglpi.sh
# author : 
# description : this is a script to install GLPI easly (automated install of GLPI)
# the script install and configure apache and PHP and download the last GLPI
#########################################
# HOW TO USE : 
# chmod +x installglpi.sh 
# ./installglpi.sh
#########################################
echo "#####################################"
echo "Define configuration"
echo "#####################################"
dbserver='localhost'
dbname='glpidb'
dbuser='glpiuser'
dbpassword='glpipassword'
mysqlpwd='root'
# functions
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}
check_bin() {
if exists $1; then
    echo 'The program $1 exists!'
else
    echo 'Your system does not have the program'
    echo '###Installing $1..'
    apt-get install $1 -y
fi
}

# ---------------------------------------------
#
# VERIFY RUN AS ROOT
#
# ---------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "Work like a true hacker ! run the script as ROOT !"
    exit 1
fi
echo "#####################################"
echo "check required bin"
check_bin "git"
check_bin "wget"
check_bin "curl"
echo "#####################################"
echo "#####################################"
echo "installing dependencies"
echo "#####################################"
apt-get install curl wget 
apt-get install apache2 php libapache2-mod-php -y
apt-get install php-imap php-ldap php-curl php-xmlrpc php-gd php-mysql php-cas php-xml php-mbstring -y
apt-get install mariadb-server -y
apt-get install apcupsd php-apcu -y
echo "#####################################"
echo "Apache2 Configuration"
echo "#####################################"
echo "
<Directory /var/www/html/glpi>
        Options Indexes FollowSymLinks
        AllowOverride limit
        Require all granted
</Directory>
" >> /etc/apache2/apache2.conf
echo '<meta http-equiv=refresh" content="0;URL=./glpi">' > /var/www/html/index.html
echo "#####################################"	
echo "securising mariadb-server"
echo "#####################################"
echo "setup password 'root' for the root user"
apt install expect -y
MYSQL_ROOT_PASSWORD=$mysqlpwd
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
echo "#####################################"
echo "Database configuration"
echo "#####################################"
mysql -uroot <<MYSQL_SCRIPT
create database $dbname;
grant all privileges on $dbname.* to $dbuser@$dbserver identified by "$dbpassword";
quit
MYSQL_SCRIPT
echo "#####################################"
echo "Installing GLPI"
echo "#####################################"
glpiv=$(get_latest_release "glpi-project/glpi")
echo "downloading last detect version : $glpiv"
cd /usr/src/
wget https://github.com/glpi-project/glpi/releases/download/$glpiv/glpi-$glpiv.tgz
tar -xvzf glpi-$glpiv.tgz -C /var/www/html
chown -R www-data:www-data /var/www/html/glpi/
echo "Open http://127.0.0.1/glpi/ or http://myserverip/glpi/ in you borwser and finish the installation"
#    glpi/glpi pour le compte administrateur
#    tech/tech pour le compte technicien
#    normal/normal pour le compte normal
#    post-only/postonly pour le compte postonly

