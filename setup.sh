#!/bin/bash

WWW_DIR=/srv/www

sudo usermod -a -G adm vagrant

echo "======================================"
echo "INSTALLING DOTDEB                     "
echo "======================================"

dotdeb_sources=$(cat <<EOF
deb http://packages.dotdeb.org jessie all
deb-src http://packages.dotdeb.org jessie all
EOF
)

echo "$dotdeb_sources" | sudo tee /etc/apt/sources.list.d/dotdeb.list

wget -qO - https://www.dotdeb.org/dotdeb.gpg | sudo apt-key add -

sudo apt-get update

echo "======================================"
echo "INSTALLING PACKAGES                   "
echo "======================================"

sudo apt-get install -y nginx-full php7.0-fpm php7.0-cli php7.0-dev vim

sudo systemctl enable nginx
sudo systemctl enable php7.0-fpm

echo "======================================"
echo "INSTALLING PECL/PEAR                  "
echo "======================================"

#manually install pear since php7.0-pear is not supported by dotdeb yet
curl -Ls https://secure.php.net/get/php-7.0.0.tar.xz/from/this/mirror | tar -Jxv php-7.0.0/pear/install-pear-nozlib.phar --strip-components=2
sudo php install-pear-nozlib.phar
rm -f install-pear-nozlib.phar

echo "======================================"
echo "INSTALLING XDEBUG                     "
echo "======================================"

sudo pecl install xdebug-beta

xdebug_ext_path=$(find /usr/lib/php -name 'xdebug.so' | head -1)

xdebug_config=$(cat <<EOF
zend_extension=$xdebug_ext_path
xdebug.remote_enable=1
xdebug.remote_host=10.0.2.2
xdebug.idekey=php7play
;xdebug.remote_connect_back=1
;xdebug.force_display_errors=1
EOF
)

echo "$xdebug_config" | sudo tee /etc/php/7.0/cli/conf.d/xdebug.ini
echo "$xdebug_config" | sudo tee /etc/php/7.0/fpm/conf.d/xdebug.ini

echo "======================================"
echo "CREATING DEFAULT VHOST                "
echo "======================================"

sudo mkdir -p "$WWW_DIR"
sudo chown vagrant:vagrant "$WWW_DIR"

php_info=$(cat <<EOF
<?php
phpinfo();
EOF
)

mkdir -p "$WWW_DIR/default"
echo "$php_info" > "$WWW_DIR/default/index.php"

nginx_vhost=$(cat <<EOF
server {
    listen       80;
    server_name  php7play;
    root         /srv/www/default;
    access_log   /var/log/nginx/default-access.log;
    error_log    /var/log/nginx/default-error.log;
EOF
)

# quoted HEREDOC prevents variable substitution in text because nginx uses $ vars
nginx_vhost+=$(cat <<'EOF'


    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location / {
        index index.php;
        try_files $uri $uri/ =404;
    }

    location ~ \.php {
        include                  fastcgi_params;
        fastcgi_split_path_info  ^(.+\.php)(/.+)$;

        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }
}

EOF
)

echo "$nginx_vhost" | sudo tee /etc/nginx/sites-available/default

sudo service php7.0-fpm restart
sudo service nginx restart

echo "======================================"
echo "PROVISION COMPLETE                    "
echo "======================================"