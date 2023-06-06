# use latest nginx-phpfpm image
ARG BASE_IMAGE=docker.io/tjend/alpine-nginx-phpfpm:latest
FROM ${BASE_IMAGE}

RUN \
  # download wordpress to /var/www
  curl -S https://wordpress.org/latest.tar.gz | \
    tar zx -C /var/www --strip-component 1 && \
  # get docker config file
  curl -L -o /var/www/wp-config.php https://github.com/docker-library/wordpress/raw/master/wp-config-docker.php && \
  # convert docker config file to unix line endings
  dos2unix /var/www/wp-config.php && \
  # add custom require to wp-config.php
  sed -i "/That's all, stop editing/i require_once ABSPATH . 'wp-config-docker.php';" /var/www/wp-config.php && \
  # create wp-config-docker.php for our custom config
  echo "<?php" > /var/www/wp-config-docker.php && \
  # use FS_METHOD direct so that updates to wp-content work(due to only wp-content being writable)
  echo "define('FS_METHOD', 'direct');" >> /var/www/wp-config-docker.php && \
  # disable core wordpress updates as filesytem isn't writable
  echo "define('WP_AUTO_UPDATE_CORE', false);" >> /var/www/wp-config-docker.php && \
  # disable health check for background updates(wordpress core) - after wp-settings.php
  echo "function remove_core_update_check(\$tests) {" >> /var/www/wp-config.php && \
  echo "	unset(\$tests['async']['background_updates']);" >> /var/www/wp-config.php && \
  echo "	return \$tests;" >> /var/www/wp-config.php && \
  echo "}" >> /var/www/wp-config.php && \
  echo "add_filter('site_status_tests', 'remove_core_update_check');" >> /var/www/wp-config.php && \
  # enable wordpress advanced cache(only when wp-content/advanced-cache.php exists)
  echo "define('WP_CACHE', true);" >> /var/www/wp-config-docker.php && \
  # chown and make wp-content writable
  chown -R www-data:www-data /var/www/wp-content && \
  find /var/www/wp-content -type f -exec chmod 664 {} \; && \
  find /var/www/wp-content -type d -exec chmod 775 {} \; && \
  # setup wp-cron
  echo "define('DISABLE_WP_CRON', true);" >> /var/www/wp-config-docker.php && \
  echo "*/15 * * * * curl -s localhost/wp-cron.php" > /etc/crontabs/nobody && \
  rm -f /etc/crontabs/root && \
  mkdir /etc/services.d/crond && \
  echo "#!/usr/bin/execlineb -P" > /etc/services.d/crond/run && \
  echo "# run in foreground" >> /etc/services.d/crond/run && \
  echo "crond -f" >> /etc/services.d/crond/run

# set phpfpm opcache validate timestamps to off for performance reasons
# wordpress will clear opcache after plugin/theme updates
ENV PHPFPM_OPCACHE_VALIDATE_TIMESTAMPS off

VOLUME [ "/var/www/wp-content" ]
