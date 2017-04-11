# docker-wordpress-nginx

A full-featured Docker image that contains Wordpress, Nginx, Op and PHP-FPM, Redis, and more.

Based on [docker-wordpress-nginx](https://github.com/eugeneware/docker-wordpress-nginx) by [Eugene Ware](http://www.noblesamurai.com/) and a [WordPress setup tutorial](https://deliciousbrains.com/hosting-wordpress-setup-secure-virtual-server/) by [Ashley Rich](https://ashleyrich.com/).

## Software

- fail2ban
- Nginx
- PHP-FPM
- MySQL
- WP-CLI
- SSH/SFTP
- Opcache
- Redis
- Email (Mailgun)
- Backups (Amazon S3)


TODO:

- Ensure Supervisord starts fail2ban properly
- add S3 cli & backups


## Installation

The easiest way to get this docker image installed is to pull the latest version
from the Docker registry:

```bash
$ docker pull emcniece/wp-php7-nginx
```

If you'd like to build the image yourself then:

```bash
$ git clone https://github.com/emcniece/docker-wp-php7-nginx.git
$ cd docker-wp-php7-nginx
$ make image
```

## Usage

To spawn a new instance of wordpress on port 80.  The -p 80:80 maps the internal docker port 80 to the outside port 80 of the host machine.

```bash
$ sudo docker run -p 80:80 --name docker-wordpress-nginx -d emcniece/wp-php7-nginx
```

Start your newly created docker.

```
$ sudo docker start docker-wordpress-nginx
```

After starting the docker-wordpress-nginx check to see if it started and the port mapping is correct.  This will also report the port mapping between the docker container and the host machine.

```
$ sudo docker ps

0.0.0.0:80 -> 80/tcp docker-wordpress-nginx
```

You can the visit the following URL in a browser on your host machine to get started:

```
http://127.0.0.1:80
```