#!/bin/zsh

bindir=$0:h
confs=(
    /etc/apache2/sites-available/default
    /etc/apache2/mods-available/mime.conf
)

source /etc/apache2/envvars
sudo gpasswd -a $USER $APACHE_RUN_GROUP

# sudo chown $APACHE_RUN_GROUP:$APACHE_RUN_GROUP /var/www
# sudo chmod g+s /var/www

sudo perl -i $bindir/ubuntu-enable-cgi.pl $confs
sudo a2enmod actions
sudo a2enmod mime
sudo apache2ctl restart
