#!/bin/bash

# moodle installation script on ubuntu 20.04 lts

MOODLE_DB=dbmoodle
MOODLE_DB_USER=moodledbadmin
MOODLE_DB_PASSWORD=abcd1234

clear

echo ""
echo "---- HELP DESK ONLINE - MOODLE 3.37 INSTALLATION ----"
echo ""

if [[ $SUDO_USER ]] ; then
    echo "Just use 'bash ${THISFILE}'"
    exit 1
fi

if [ $(getent group www-data) ]; then
    echo "Add $USER to group www-data."
    sudo usermod -a -G www-data $USER
    source ~/.bashrc
else
    echo "group www-data does not exist."
    exit 1
fi

INPUTS="x"
echo -n "Instalar moodle 3.37? [y/n] : "
read INPUTS
if [[ ${INPUTS} != "y" ]] ; then
    exit 1
fi

echo ""
echo "---- INICIANDO INSTALAÇÃO ----"
echo ""

cd ~

# ------------------------------
# Essential packages
# ------------------------------
sudo apt -y install curl git unzip unrar mlocate curl apt-transport-https software-properties-common lsb-release ca-certificates gnupg2

# ------------------------------
# for Brazilian Fortaleza Timezone
# ------------------------------
echo -e $"\nSetting Timezone\n"

sudo timedatectl set-timezone 'America/Fortaleza'

sudo apt update
sudo apt -y upgrade

# ------------------------------
# apache
# ------------------------------
echo -e $"\ninstalling apache2\n"

sudo apt install -y apache2
sudo ufw allow 'Apache Full'
sudo systemctl enable apache2
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
sudo systemctl stop apache2
sudo rm /etc/apache2/sites-available/000-default.conf

# ------------------------------
# apache logs directory
# ------------------------------
echo -e $"\ncreate apache logs directory\n"

sudo sh -c 'mkdir /var/log/moodle/'
sudo sh -c 'touch /var/log/moodle/error.log'
sudo sh -c 'touch /var/log/moodle/access.log'

# ------------------------------
# create virtual host rules file
# ------------------------------
echo -e $"\ncreate virtual host rules file\n"

if ! sudo sh -c 'echo "<VirtualHost *:80>
  ServerAdmin admin@example.com
  DocumentRoot /var/www/moodle/
  ServerName localhost

  <Directory /var/www/moodle/>
    Options +FollowSymlinks
    AllowOverride All
    Require all granted
  </Directory>

  ErrorLog /var/log/moodle/error.log
  CustomLog /var/log/moodle/access.log combined
</VirtualHost>" > /etc/apache2/sites-available/moodle.conf'
then
    echo -e $"There is an ERROR create virtualhost file for Moodle"
    exit;
else
    echo -e $"\nNew Virtual Host Created\n"
fi

sudo systemctl reload apache2
sudo systemctl restart apache2

# ------------------------------
# mariadb 10.5
# ------------------------------
echo -e $"\nInstalling MariaDB 10.5\n"

curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
sudo bash mariadb_repo_setup --mariadb-server-version=10.5
sudo apt update
sudo apt install -y mariadb-server mariadb-client

sudo mysql -uroot -e "SET GLOBAL innodb_file_per_table = ON;"
sudo mysql -uroot -e "SET GLOBAL innodb_default_row_format = dynamic;"
sudo mysql -uroot -e "SET GLOBAL innodb_strict_mode = ON;"

sudo systemctl restart mariadb

echo -e $"\nCreate database\n"
sudo mysql -uroot -e "create database $MOODLE_DB default character set utf8mb4 collate utf8mb4_unicode_ci"
echo -e $"\nCreate database user\n"
sudo mysql -uroot -e "CREATE USER $MOODLE_DB_USER@localhost IDENTIFIED BY '$MOODLE_DB_PASSWORD'"
echo -e $"\nGrant privileges\n"
sudo mysql -uroot -e "grant all privileges on $MOODLE_DB.* to 'root'@'localhost' with grant option"
sudo mysql -uroot -e "grant all privileges on $MOODLE_DB.* to $MOODLE_DB_USER@localhost with grant option"

# ------------------------------
# php
# ------------------------------
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update
sudo apt install -y php7.0 php7.0-cli php7.0-common
sudo apt install -y php7.1 php7.1-cli php7.1-common
sudo apt install -y php7.2 php7.2-cli php7.2-common
sudo apt install -y php7.3 php7.3-cli php7.3-common
sudo apt install -y php7.4 php7.4-cli php7.4-common
sudo apt install -y php8.0 php8.0-cli php8.0-common

sudo apt install -y php7.0-fpm  php7.0-mbstring php7.0-xmlrpc php7.0-soap php7.0-gd php7.0-xml php7.0-intl php7.0-mysql php7.0-zip php7.0-curl php7.0-json libapache2-mod-php7.0
sudo apt install -y php7.1-fpm  php7.1-mbstring php7.1-xmlrpc php7.1-soap php7.1-gd php7.1-xml php7.1-intl php7.1-mysql php7.1-zip php7.1-curl php7.1-json libapache2-mod-php7.1
sudo apt install -y php7.2-fpm  php7.2-mbstring php7.2-xmlrpc php7.2-soap php7.2-gd php7.2-xml php7.2-intl php7.2-mysql php7.2-zip php7.2-curl php7.2-json libapache2-mod-php7.2
sudo apt install -y php7.3-fpm  php7.3-mbstring php7.3-xmlrpc php7.3-soap php7.3-gd php7.3-xml php7.3-intl php7.3-mysql php7.3-zip php7.3-curl php7.3-json libapache2-mod-php7.3
sudo apt install -y php7.4-fpm  php7.4-mbstring php7.4-xmlrpc php7.4-soap php7.4-gd php7.4-xml php7.4-intl php7.4-mysql php7.4-zip php7.4-curl php7.4-json libapache2-mod-php7.4
sudo apt install -y php8.0-fpm php8.0-mbstring php8.0-xmlrpc php8.0-soap php8.0-gd php8.0-xml php8.0-intl php8.0-mysql php8.0-zip php8.0-curl libapache2-mod-php8.0

sudo a2dismod php7.1
sudo a2dismod php7.2
sudo a2dismod php7.3
sudo a2dismod php7.4
sudo a2dismod php8.0
sudo a2enmod php7.0

FILE=/etc/php/7.0/fpm/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange fpm/php.ini(7.0) parameters\n"
    sudo sed -i "s:memory_limit = 128M:memory_limit = 512M:g" /etc/php/7.0/fpm/php.ini
    sudo sed -i "s:upload_max_filesize = 2M:upload_max_filesize = 256M:g" /etc/php/7.0/fpm/php.ini
    sudo sed -i "s:;opcache.enable=1:opcache.enable=1:g" /etc/php/7.0/fpm/php.ini
fi

FILE=/etc/php/7.1/fpm/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange fpm/php.ini(7.1) parameters\n"
    sudo sed -i "s:memory_limit = 128M:memory_limit = 512M:g" /etc/php/7.1/fpm/php.ini
    sudo sed -i "s:upload_max_filesize = 2M:upload_max_filesize = 256M:g" /etc/php/7.1/fpm/php.ini
    sudo sed -i "s:;opcache.enable=1:opcache.enable=1:g" /etc/php/7.1/fpm/php.ini
fi

FILE=/etc/php/7.2/fpm/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange fpm/php.ini(7.2) parameters\n"
    sudo sed -i "s:memory_limit = 128M:memory_limit = 512M:g" /etc/php/7.2/fpm/php.ini
    sudo sed -i "s:upload_max_filesize = 2M:upload_max_filesize = 256M:g" /etc/php/7.2/fpm/php.ini
    sudo sed -i "s:;opcache.enable=1:opcache.enable=1:g" /etc/php/7.2/fpm/php.ini
fi

FILE=/etc/php/7.3/fpm/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange fpm/php.ini(7.3) parameters\n"
    sudo sed -i "s:memory_limit = 128M:memory_limit = 512M:g" /etc/php/7.3/fpm/php.ini
    sudo sed -i "s:upload_max_filesize = 2M:upload_max_filesize = 256M:g" /etc/php/7.3/fpm/php.ini
    sudo sed -i "s:;opcache.enable=1:opcache.enable=1:g" /etc/php/7.3/fpm/php.ini
fi

FILE=/etc/php/7.4/fpm/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange fpm/php.ini(7.4) parameters\n"
    sudo sed -i "s:memory_limit = 128M:memory_limit = 512M:g" /etc/php/7.4/fpm/php.ini
    sudo sed -i "s:upload_max_filesize = 2M:upload_max_filesize = 256M:g" /etc/php/7.4/fpm/php.ini
    sudo sed -i "s:;opcache.enable=1:opcache.enable=1:g" /etc/php/7.4/fpm/php.ini
fi

FILE=/etc/php/8.0/fpm/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange fpm/php.ini(8.0) parameters\n"
    sudo sed -i "s:memory_limit = 128M:memory_limit = 512M:g" /etc/php/8.0/fpm/php.ini
    sudo sed -i "s:upload_max_filesize = 2M:upload_max_filesize = 256M:g" /etc/php/8.0/fpm/php.ini
    sudo sed -i "s:;opcache.enable=1:opcache.enable=1:g" /etc/php/8.0/fpm/php.ini
fi

FILE=/etc/php/7.0/apache2/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange apache2/php.ini(7.0) parameters\n"    
    sudo sed -i "s:;extension=php_mysqli.dll:extension=php_mysqli.dll:g" /etc/php/7.0/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_mysql.dll:extension=php_pdo_mysql.dll:g" /etc/php/7.0/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_sqlite.dll:extension=php_pdo_sqlite.dll:g" /etc/php/7.0/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_pgsql.dlll:extension=php_pdo_pgsql.dll:g" /etc/php/7.0/apache2/php.ini
fi

FILE=/etc/php/7.1/apache2/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange apache2/php.ini(7.1) parameters\n"    
    sudo sed -i "s:;extension=php_mysqli.dll:extension=php_mysqli.dll:g" /etc/php/7.1/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_mysql.dll:extension=php_pdo_mysql.dll:g" /etc/php/7.1/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_sqlite.dll:extension=php_pdo_sqlite.dll:g" /etc/php/7.1/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_pgsql.dlll:extension=php_pdo_pgsql.dll:g" /etc/php/7.1/apache2/php.ini
fi

FILE=/etc/php/7.2/apache2/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange apache2/php.ini(7.2) parameters\n"    
    sudo sed -i "s:;extension=php_mysqli.dll:extension=php_mysqli.dll:g" /etc/php/7.2/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_mysql.dll:extension=php_pdo_mysql.dll:g" /etc/php/7.2/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_sqlite.dll:extension=php_pdo_sqlite.dll:g" /etc/php/7.2/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_pgsql.dlll:extension=php_pdo_pgsql.dll:g" /etc/php/7.2/apache2/php.ini
fi

FILE=/etc/php/7.3/apache2/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange apache2/php.ini(7.3) parameters\n"    
    sudo sed -i "s:;extension=php_mysqli.dll:extension=php_mysqli.dll:g" /etc/php/7.3/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_mysql.dll:extension=php_pdo_mysql.dll:g" /etc/php/7.3/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_sqlite.dll:extension=php_pdo_sqlite.dll:g" /etc/php/7.3/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_pgsql.dlll:extension=php_pdo_pgsql.dll:g" /etc/php/7.3/apache2/php.ini
fi

FILE=/etc/php/7.4/apache2/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange apache2/php.ini(7.4) parameters\n"    
    sudo sed -i "s:;extension=php_mysqli.dll:extension=php_mysqli.dll:g" /etc/php/7.4/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_mysql.dll:extension=php_pdo_mysql.dll:g" /etc/php/7.4/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_sqlite.dll:extension=php_pdo_sqlite.dll:g" /etc/php/7.4/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_pgsql.dlll:extension=php_pdo_pgsql.dll:g" /etc/php/7.4/apache2/php.ini
fi

FILE=/etc/php/8.0/apache2/php.ini
if test -f "$FILE"; then
    echo -e $"\nChange apache2/php.ini(8.0) parameters\n"    
    sudo sed -i "s:;extension=php_mysqli.dll:extension=php_mysqli.dll:g" /etc/php/8.0/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_mysql.dll:extension=php_pdo_mysql.dll:g" /etc/php/8.0/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_sqlite.dll:extension=php_pdo_sqlite.dll:g" /etc/php/8.0/apache2/php.ini
    sudo sed -i "s:;extension=php_pdo_pgsql.dlll:extension=php_pdo_pgsql.dll:g" /etc/php/8.0/apache2/php.ini
fi


# restart services
sudo systemctl restart nginx
sudo systemctl restart mariadb
sudo systemctl restart php7.0-fpm
sudo systemctl restart php7.0-fpm.service

# ------------------------------
# moodle
# ------------------------------
FILE=/var/www/
if [ ! -f "$FILE" ]; then
    sudo sh -c 'mkdir /var/www/'
fi

FILE=/var/www/moodledata
if [ ! -f "$FILE" ]; then
    sudo sh -c 'mkdir /var/www/moodledata'
fi

sudo sh -c 'usermod -aG www-data $USER'
sudo sh -c 'chown root:root /var/www'
sudo sh -c 'chmod -R 775 /var/www'
sudo sh -c 'chown -R www-data /var/www/moodledata'
sudo sh -c 'chmod -R 777 /var/www/moodledata'
cd /var/www/
sudo sh -c 'wget https://download.moodle.org/stable33/moodle-3.3.7.tgz'
FILE=/var/www/moodle-3.3.7.tgz
if test -f "$FILE"; then
    sudo sh -c 'tar -zxvf moodle-3.3.7.tgz'
    sudo sh -c 'rm -rf moodle-3.3.7.tgz'
    sudo sh -c 'chown -R $USER:www-data /var/www/moodle'
    sudo sh -c 'cp /var/www/moodle/config-dist.php /var/www/moodle/config.php'
    sudo sh -c 'chmod 775 /var/www/moodle/admin/cli/cron.php'
    sudo sh -c 'chmod -R 777 /var/www/moodle'
fi


cat <<EOF | sudo tee /var/www/moodle/config.php
<?php
  unset(\$CFG);
  global \$CFG;
  \$CFG = new stdClass();

  \$CFG->dbtype    = 'mariadb';
  \$CFG->dblibrary = 'native';
  \$CFG->dbhost    = 'localhost';
  \$CFG->dbname    = '$MOODLE_DB';
  \$CFG->dbuser    = '$MOODLE_DB_USER';
  \$CFG->dbpass    = '$MOODLE_DB_PASSWORD';
  \$CFG->prefix    = 'mdl_';
  \$CFG->dboptions = array(
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => '',
    'dbhandlesoptions' => false,
    'dbcollation' => 'utf8mb4_unicode_ci',
  );

  \$CFG->wwwroot   = 'http://localhost';
  \$CFG->dataroot  = '/var/www/moodledata';
  \$CFG->directorypermissions = 02777;
  \$CFG->admin = 'admin';

  require_once(__DIR__ . '/lib/setup.php');
EOF

# ------------------------------
# ENABLE MOODLE VIRTUALHOST
# ------------------------------
sudo a2ensite moodle
sudo systemctl reload apache2

# ------------------------------
# clear
# ------------------------------

echo ""
echo "--- MOODLE 3.3.7 installed ---"
echo ""
echo "Next : web installaion needed..."
echo ""
echo "moodle html home directory : /var/www/moodle"
echo "moodle data directory :      /var/www/moodledata"
echo ""
echo "After installation completed : "
echo "You must change mod with :"
echo "sudo chmod -R 755 /var/www/moodle"
echo ""
echo ""
