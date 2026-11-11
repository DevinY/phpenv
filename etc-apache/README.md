# etc-apache

Config tree for `docker-compose-apache.yml` (Apache + PHP-FPM unix socket).

| Path | Mounted as |
| --- | --- |
| `apache/` | `/usr/local/apache2/conf/conf.d` |
| `php-fpm.d/www.conf` | `/usr/local/etc/php-fpm.d/www.conf` |

Shared with the default socket mode: `etc/php`, `etc/supervisor`, `etc/cache`.

`.htaccess` works because the vhost sets `AllowOverride All`.
If TLS is terminated in front of the container, prefer `X-Forwarded-Proto`
in rewrite rules instead of relying only on `%{HTTPS}`.
