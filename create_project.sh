#!/bin/bash
echo "Créer un projet web"
echo ""
echo "Nom du projet (FQDN) : "
read fqdn
echo "Le nom du projet est $fqdn"
# création du dossier et de l'index du site
mkdir /var/www/$fqdn
echo "<p>$fqdn</p>" >> /var/www/$fqdn/index.html
# creation du vhost 
read -s -p "Saisir le domaine : " DOMAIN; echo
echo ""
read -s -p "Saisir l'Alias :  " ALIAS; echo
echo ""
read -s -p "Saisir le mail de contact : " CONTACT; echo
echo ""
echo "vous avez saisie : $DOMAIN, $ALIAS, $CONTACT"
echo "
<VirtualHost *:80>
    ServerAdmin $CONTACT
    ServerName $DOMAIN
    ServerAlias $ALIAS
    DocumentRoot /var/www/$fqdn
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/$fqdn.conf
cd /etc/apache2/sites-available/
a2ensite $fqdn.conf
systemctl reload apache2
# création du vhost https
cd /etc/ssl
mkdir $fqdn
cd $fqdn
#  On crée la clé privée avec l'algorithme RSA 2048 bits.
openssl genrsa -out $fqdn.key 2048
#  Ensuite il faut générer un fichier de « demande de signature de certificat », en anglais CSR
openssl req -new -key $fqdn.key -out $fqdn.csr
#  Ensuite, on génére le certificat signé au format x509 (ici pour 365jours auto-signé)
openssl x509 -req -days 365 -in $fqdn.csr -signkey $fqdn.key -out $fqdn.crt
echo "       <VirtualHost _default_:443>
                ServerAdmin $CONTACT
                ServerName $DOMAIN
                DocumentRoot /var/www/$fqdn
                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined
                SSLEngine on
                SSLCertificateFile      /etc/ssl/$fqdn/$fqdn.crt
                SSLCertificateKeyFile /etc/ssl/$fqdn/$fqdn.key
                <FilesMatch \"\.(cgi|shtml|phtml|php)$\">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
        </VirtualHost>
" > /etc/apache2/sites-available/$fqdn-ssl.conf
cd /etc/apache2/sites-available/
a2ensite $fqdn-ssl.conf
systemctl reload apache2
echo "done !"
echo "testing http : "
curl http://$fqdn
echo "testing https : "
curl https://$fqdn
exit 0
