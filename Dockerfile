FROM ubuntu:16.04
MAINTAINER Eric McNiece <hello@emc2innovation.com>

EXPOSE 80

VOLUME ["/var/www/wordpress", "/var/www/import"]

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl \
 && ln -sf /bin/true /sbin/initctl \
 && sh -c "echo 'deb http://download.opensuse.org/repositories/home:/rtCamp:/EasyEngine/xUbuntu_16.04/ /' > /etc/apt/sources.list.d/nginx.list" \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --allow-unauthenticated \
  supervisor \
  curl \
  pwgen \
  git \
  unzip \
  redis-server \
  python-pip \
  php-memcache \
  php-apcu \
  php-redis \
  nginx-custom \
  nginx-ee \
  php7.0-fpm \
  php7.0-mysql \
  php7.0-curl \
  php7.0-gd \
  php7.0-mcrypt \
  php7.0-xmlrpc \
  php7.0-mbstring

RUN \
 # Python Pip for supervisor
 pip install --upgrade pip \
 && pip install supervisor-stdout \
 # WP user
 && useradd --comment "WordPress" --home /home/wordpress -G sudo wordpress \
 && mkdir -p /home/wordpress \
 && chown wordpress:wordpress /home/wordpress \
 # WP CLI
 && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x wp-cli.phar \
 && mv wp-cli.phar /usr/local/bin/wp \
 # Redis config
 && echo 'session.save_handler = redis' >> /etc/php/7.0/mods-available/redis.ini \
 && echo 'session.save_path = "tcp://127.0.0.1:6379"' >> /etc/php/7.0/mods-available/redis.ini \
 && echo 'maxmemory 64mb' >> /etc/redis/redis.conf && service redis-server restart \

# Config files
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
ADD ./config/nginx.conf /etc/nginx
ADD ./config/nginx-site.conf /etc/nginx/sites-available/default
ADD ./config/wordpress-fpm.conf /etc/php/7.0/fpm/pool.d
ADD ./config/supervisord.conf /etc/supervisord.conf
ADD ./start.sh /start.sh

RUN \
 # nginx site conf
 ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log \
 && mkdir -p /var/www/cache \
 && mkdir -p /var/www/import \
 # PHP-FPM
 && rm /etc/php/7.0/fpm/pool.d/www.conf \
 && mkdir -p /run/php && touch /run/php/php7.0-fpm.sock \
 && mkdir -p /var/www/log && touch /var/www/log/php7.0-fpm.log \
 && echo "fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_script_name;" >> /etc/nginx/fastcgi_params \
 && sed -i -E "s:/var/log/php7.0-fpm.log:/var/www/log/php7.0-fpm.log:g" /etc/php/7.0/fpm/php-fpm.conf \
 && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf \
 && sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/fpm/php.ini \
 && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini \
 && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini \
 # Wordpress Initialization and Startup Script
 && chown -R wordpress:wordpress /var/www \
 && chmod 755 /start.sh

WORKDIR /var/www/wordpress
CMD ["/bin/bash", "/start.sh"]
