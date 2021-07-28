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
  # add custom require to wp-config.php
  sed -i "/That's all, stop editing/i require_once ABSPATH . 'wp-config-docker.php';" /var/www/localhost/htdocs/wp-config.php && \
  # create wp-config-docker.php for our custom config
  echo "<?php" > /var/www/localhost/htdocs/wp-config-docker.php && \
  # use FS_METHOD direct so that updates to wp-content work(due to only wp-content being writable)
  echo "define('FS_METHOD', 'direct');" >> /var/www/localhost/htdocs/wp-config-docker.php && \
  # disable core wordpress updates as filesytem isn't writable
  echo "define('WP_AUTO_UPDATE_CORE', false);" >> /var/www/localhost/htdocs/wp-config-docker.php && \
  # disable health check for background updates(wordpress core) - after wp-settings.php
  echo "function remove_core_update_check(\$tests) {" >> /var/www/localhost/htdocs/wp-config.php && \
  echo "	unset(\$tests['async']['background_updates']);" >> /var/www/localhost/htdocs/wp-config.php && \
  echo "	return \$tests;" >> /var/www/localhost/htdocs/wp-config.php && \
  echo "}" >> /var/www/localhost/htdocs/wp-config.php && \
  echo "add_filter('site_status_tests', 'remove_core_update_check');" >> /var/www/localhost/htdocs/wp-config.php && \
  # enable wordpress advanced cache(only when wp-content/advanced-cache.php exists)
  echo "define('WP_CACHE', true);" >> /var/www/localhost/htdocs/wp-config-docker.php && \
  # chown and make wp-content writable
  chown -R www-data:www-data /var/www/localhost/htdocs/wp-content && \
  find /var/www/localhost/htdocs/wp-content -type f -exec chmod 664 {} \; && \
  find /var/www/localhost/htdocs/wp-content -type d -exec chmod 775 {} \; && \
  # setup wp-cron
  echo "define('DISABLE_WP_CRON', true);" >> /var/www/localhost/htdocs/wp-config-docker.php && \
  echo "*/15 * * * * curl -v localhost/wp-cron.php" > /etc/crontabs/nobody && \
  rm -f /etc/crontabs/root && \
  mkdir /etc/services.d/crond && \
  echo "#!/usr/bin/execlineb -P" > /etc/services.d/crond/run && \
  echo "# run in foreground" >> /etc/services.d/crond/run && \
  echo "crond -f" >> /etc/services.d/crond/run

# set phpfpm opcache validate timestamps to off for performance reasons
# wordpress will clear opcache after plugin/theme updates
ENV PHPFPM_OPCACHE_VALIDATE_TIMESTAMPS off

VOLUME [ "/var/www/localhost/htdocs/wp-content" ]
