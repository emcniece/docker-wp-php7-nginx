#!/bin/bash
if [ ! -f /var/www/wordpress/wp-config.php ]; then
  # Set timezone
  echo $TIMEZONE > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata

  REDIS_PASS=$([ "$REDIS_PASS" ] && echo $REDIS_PASS || echo $(pwgen -c -n -1 12))

  echo "Downloading WordPress..."
  cd /var/www/wordpress
  wp core download --allow-root --path=/var/www/wordpress

  echo "Editing wp-config..."
  cp wp-config-sample.php wp-config.php
  sed -e "s/database_name_here/$MYSQL_DATABASE/
  s/localhost/$MYSQL_HOST/
  s/username_here/$MYSQL_USER/
  s/password_here/$MYSQL_PASSWORD/
  /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /var/www/wordpress/wp-config-sample.php > /var/www/wordpress/wp-config.php
  echo "done config"

  echo "Installing plugins..."
  cd /var/www/wordpress/wp-content/plugins
  curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^\"]+"`
  curl -O `curl -i -s https://wordpress.org/plugins/redis-cache/ | egrep -o "https://downloads.wordpress.org/plugin/[^\"]+"`
  curl -O `curl -i -s https://wordpress.org/plugins/mailgun/ | egrep -o "https://downloads.wordpress.org/plugin/[^\"]+"`
  curl -O `curl -i -s https://wordpress.org/plugins/wordpress-seo/ | egrep -o "https://downloads.wordpress.org/plugin/[^\"]+"`
  unzip -q '*.zip'
  rm *.zip
  echo "done plugin install"

  # WP Environment Config
  cd /var/www/wordpress
  echo -e "define('DISABLE_WP_CRON', true);\n?>\n$(cat wp-config.php)" > wp-config.php
  echo -e "define('RT_WP_NGINX_HELPER_CACHE_PATH', '/var/www/wordpress/cache/');\n$(cat wp-config.php)" > wp-config.php
  echo -e "define('WP_REDIS_DATABASE', 1);\n$(cat wp-config.php)" > wp-config.php
  echo -e "<?php\ndefine('WP_REDIS_PASSWORD', '$REDIS_PASS');\n$(cat wp-config.php)" > wp-config.php

  # Import files eventually?

  chown -R wordpress:wordpress /var/www/wordpress
fi

# start all the services
/usr/bin/supervisord -c /etc/supervisord.conf -n