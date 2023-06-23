#!/bin/sh
set -e

if [ -f ~/.runonce ]
then
    echo "Gazelle setup already run, skipping..."
    exit
fi
touch ~/.runonce

echo mariadb-server mariadb-server/root_password password em%G9Lrey4^N | sudo debconf-set-selections
echo mariadb-server mariadb-server/root_password_again password em%G9Lrey4^N | sudo debconf-set-selections

sudo apt-get update
sudo apt-get install -y mariadb-server mariadb-client
sudo apt-get install -y php7.3 php7.3-mysql php7.3-fpm php-memcached php-mcrypt
sudo apt-get install -y git nginx memcached sphinxsearch

sudo cp /vagrant/nginx.conf /etc/nginx/sites-available/default
sudo cp /vagrant/php.ini /etc/php/7.3/fpm/php.ini

echo "START=yes" | sudo tee /etc/default/sphinxsearch > /dev/null

sudo mkdir -p /var/www/tmp
sudo git clone https://github.com/WhatCD/Gazelle.git /var/www/tmp
sudo rsync -a /var/www/tmp/ /var/www/
sudo rm -rf /var/www/tmp

mysql -u root -p'em%G9Lrey4^N' -e "CREATE DATABASE gazelle;"
mysql -u root -p'em%G9Lrey4^N' gazelle < /var/www/gazelle.sql

sudo cp /vagrant/sphinx.conf /var/www/
sudo mkdir -p /var/data/sphinx
sudo mkdir -p /var/log/searchd
sudo ln -s /var/www/sphinx.conf /etc/sphinxsearch/sphinx.conf
sudo indexer -c /etc/sphinxsearch/sphinx.conf --all
sudo chown -R sphinxsearch /var/data/sphinx
sudo chown -R sphinxsearch /var/log/searchd

sudo systemctl start memcached

sudo cp /vagrant/config.php /var/www/classes/config.php

sudo cp /vagrant/crontab /etc/cron.d/

sudo systemctl restart php7.3-fpm
sudo systemctl restart nginx
