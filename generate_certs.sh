
#!/bin/bash
echo "use the script : $0 www.mywebsite.com"
domaine=$1
cd /etc/ssl
mkdir $domaine
cd $domaine
#  On crée la clé privée avec l'algorithme RSA 2048 bits.
openssl genrsa -out $domaine.key 2048
#  Ensuite il faut générer un fichier de « demande de signature de certificat », en anglais CSR
openssl req -new -key $domaine.key -out $domaine.csr
#  Ensuite, on génére le certificat signé au format x509 (ici pour 365jours auto-signé)
openssl x509 -req -days 365 -in $domaine.csr -signkey $domaine.key -out $domaine.crt
echo "certificate generate for $domaine"
ls
echo "Now creating the vhost"
echo "content of /var/www : "
ls -al /var/www
echo "what is the folder of the website ? (full path)"
read full_path
echo "       <VirtualHost _default_:443>
                ServerAdmin webmaster@localhost
                ServerName $domaine
                DocumentRoot $full_path
                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined
                SSLEngine on
                SSLCertificateFile      /etc/ssl/$domaine/$domaine.crt
                SSLCertificateKeyFile /etc/ssl/$domaine/$domaine.key
                <FilesMatch \"\.(cgi|shtml|phtml|php)$\">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
        </VirtualHost>
" > /etc/apache2/sites-available/$domaine-ssl.conf
cd /etc/apache2/sites-available/
echo "enabling the https vhost for $domaine"
a2ensite $domaine-ssl.conf
systemctl reload apache2
exit 0
