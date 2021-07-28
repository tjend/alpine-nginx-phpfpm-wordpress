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
  # disable core wordpress updates as filesytem isn't writable
  echo "define('WP_AUTO_UPDATE_CORE', false);" >> /var/www/localhost/htdocs/wp-config.php && \
  # disable health check for background updates(wordpress core)
  echo "function remove_core_update_check(\$tests) {" >> /var/www/localhost/htdocs/wp-config.php && \
  echo "	unset(\$tests['async']['background_updates']);" >> /var/www/localhost/htdocs/wp-config.php && \
  echo "	return \$tests;" >> /var/www/localhost/htdocs/wp-config.php && \
  echo "}" >> /var/www/localhost/htdocs/wp-config.php && \
  echo "add_filter('site_status_tests', 'remove_core_update_check');" >> /var/www/localhost/htdocs/wp-config.php && \
  # enable wordpress advanced cache(only when wp-content/advanced-cache.php exists)
  echo "define('WP_CACHE', true);" >> /var/www/localhost/htdocs/wp-config.php && \
  # chown and make wp-content writable
  chown -R www-data:www-data /var/www/localhost/htdocs/wp-content && \
  find /var/www/localhost/htdocs/wp-content -type f -exec chmod 664 {} \; && \
  find /var/www/localhost/htdocs/wp-content -type d -exec chmod 775 {} \;

# set phpfpm opcache validate timestamps to off for performance reasons
# wordpress will clear opcache after plugin/theme updates
ENV PHPFPM_OPCACHE_VALIDATE_TIMESTAMPS off

VOLUME [ "/var/www/localhost/htdocs/wp-content" ]
