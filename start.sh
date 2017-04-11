#!/bin/bash
if [ ! -f /var/www/wordpress/wp-config.php ]; then
  # Set timezone
  echo $TIMEZONE > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata

  #mysql has to be started this way as it doesn't work to call from /etc/init.d
  /usr/bin/mysqld_safe &
  sleep 10s

  # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
  WORDPRESS_DB=$([ "$WORDPRESS_DB" ] && echo $WORDPRESS_DB || echo "wordpress")
  MYSQL_PASS=$([ "$MYSQL_PASS" ] && echo $MYSQL_PASS || echo $(pwgen -c -n -1 12))
  WORDPRESS_PASS=$([ "$WORDPRESS_PASS" ] && echo $WORDPRESS_PASS || echo $(pwgen -c -n -1 12))
  REDIS_PASS=$([ "$REDIS_PASS" ] && echo $REDIS_PASS || echo $(pwgen -c -n -1 12))

  #This is so the passwords show up in logs.
  echo mysql root password: $MYSQL_PASS
  echo wordpress database: $WORDPRESS_DB
  echo wordpress password: $WORDPRESS_PASS

  echo mysql root password: $MYSQL_PASS >> /dbcreds.txt
  echo wordpress db user: $WORDPRESS_DB >> /dbcreds.txt
  echo wordpress db pass: $WORDPRESS_PASS >> /dbcreds.txt

  # MySQL Config
  mysqladmin -u root password $MYSQL_PASS
  mysql -uroot -p$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASS' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  mysql -uroot -p$MYSQL_PASS -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY '$WORDPRESS_PASS'; FLUSH PRIVILEGES;"

  echo "Downloading WordPress..."
  cd /var/www/wordpress
  wp core download --allow-root --path=/var/www/wordpress
  wp core config --dbname=$WORDPRESS_DB --dbuser=$WORDPRESS_DB --dbpass=$WORDPRESS_PASS --allow-root

  echo "Installing plugins..."
  cd /var/www/wordpress/wp-content/plugins
  curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^\"]+"`
  curl -O `curl -i -s https://wordpress.org/plugins/redis-cache/ | egrep -o "https://downloads.wordpress.org/plugin/[^\"]+"`
  curl -O `curl -i -s https://wordpress.org/plugins/mailgun/ | egrep -o "https://downloads.wordpress.org/plugin/[^\"]+"`
  curl -O `curl -i -s https://wordpress.org/plugins/wordpress-seo/ | egrep -o "https://downloads.wordpress.org/plugin/[^\"]+"`
  unzip '*.zip'
  rm *.zip
  echo "done plugin install"

  # WP Environment Config
  cd /var/www/wordpress
  echo -e "define('DISABLE_WP_CRON', true);\n?>\n$(cat wp-config.php)" > wp-config.php
  echo -e "define('RT_WP_NGINX_HELPER_CACHE_PATH', '/var/www/wordpress/cache/');\n$(cat wp-config.php)" > wp-config.php
  echo -e "define('WP_REDIS_DATABASE', 1);\n$(cat wp-config.php)" > wp-config.php
  echo -e "<?php\ndefine('WP_REDIS_PASSWORD', '$REDIS_PASS');\n$(cat wp-config.php)" > wp-config.php

  # Import steps!
  # Import db
  # Import files

  # Cleanup & supervisord prep
  pidof /bin/sh /usr/bin/mysqld_safe | xargs kill -9
  killall mysqld
  chown -R wordpress:wordpress /var/www/wordpress
fi

# start all the services
/usr/bin/supervisord -c /etc/supervisord.conf -n