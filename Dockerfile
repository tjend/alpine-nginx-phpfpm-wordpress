# use latest nginx-phpfpm image
FROM tjend/alpine-nginx-phpfpm:latest

RUN \
  # download wordpress to /var/www/localhost/htdocs
  curl -S https://wordpress.org/latest.tar.gz | \
    tar zx -C /var/www/localhost/htdocs --strip-component 1 && \
  # get docker config file
  curl -L -o /var/www/localhost/htdocs/wp-config.php https://github.com/docker-library/wordpress/raw/master/wp-config-docker.php && \
  # convert docker config file to unix line endings
  dos2unix /var/www/localhost/htdocs/wp-config.php && \
  # use FS_METHOD direct so that updates to wp-content work(due to only wp-content being writable)
  echo "define('FS_METHOD', 'direct');" >> /var/www/localhost/htdocs/wp-config.php && \
  # chown and make wp-content writable
  chown -R www-data:www-data /var/www/localhost/htdocs/wp-content && \
  find /var/www/localhost/htdocs/wp-content -type f -exec chmod 664 {} \; && \
  find /var/www/localhost/htdocs/wp-content -type d -exec chmod 775 {} \;

VOLUME [ "/var/www/localhost/htdocs/wp-content" ]
