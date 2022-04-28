#!/usr/bin/env bash
echo "Running docker-entrypoint.sh"
echo "Wordpress version is 5.3.9"
set -Eeuo pipefail
if [[ "$1" == apache2* ]] || [ "$1" = 'php-fpm' ]; then
	uid="$(id -u)"
	gid="$(id -g)"
	if [ "$uid" = '0' ]; then
		case "$1" in
			apache2*)
				user="${APACHE_RUN_USER:-www-data}"
				group="${APACHE_RUN_GROUP:-www-data}"

				# strip off any '#' symbol ('#1000' is valid syntax for Apache)
				pound='#'
				user="${user#$pound}"
				group="${group#$pound}"
				;;
			*) # php-fpm
				user='www-data'
				group='www-data'
				;;
		esac
	else
		user="$uid"
		group="$gid"
	fi
fi

#Do not fail if the environment variables are not set
set +u
#Assign the WSP DB environment variables to the WORDPRESS_ENVIRONMENT variables
if ! [ -z "$DB_HOST" ]; then
  export WORDPRESS_DB_HOST="$DB_HOST"
fi
if ! [ -z "$DB_USER" ]; then
  export WORDPRESS_DB_USER="$DB_USER"
fi
if ! [ -z "$DB_NAME" ]; then
  export WORDPRESS_DB_NAME="$DB_NAME"
fi
if ! [ -z "$DB_PASSWORD" ]; then
  export WORDPRESS_DB_PASSWORD="$DB_PASSWORD"
fi

#Support default WSP AWS domain name environment variable
if ! [ -z "$DOMAIN_NAME" ]; then
  if [ -z "$WORDPRESS_URL" ]; then
    export WORDPRESS_URL="$DOMAIN_NAME"
  fi
fi

#Assign default values to the WORDPRESS_ENVIRONMENT variables if they are not set
if [ -z "$WORDPRESS_ADMIN_USER" ]; then
  export WORDPRESS_ADMIN_USER='admin'
fi
if [ -z "$WORDPRESS_ADMIN_EMAIL" ]; then
  export WORDPRESS_ADMIN_EMAIL='wsp@local.host'
fi
if [ -z "$WORDPRESS_TITLE" ]; then
  export WORDPRESS_TITLE='WSP AWS'
fi


#Show static page with error if $WORDPRESS_URL is not set
if [ -z "$WORDPRESS_URL" ]; then
  echo '<h1>Environment variable $WORDPRESS_URL is not set. Please set it with Wordpress domain and re-deploy</h1>' > /var/www/html/index.html
  echo "DirectoryIndex index.html" >> /var/www/html/.htaccess
  echo "Running Web-server to show error that WORDPRESS_URL is not set"
  exec "$@"
else
  echo "Removing DirectoryIndex directive from .htaccess, index.php will be served"
  sed -i '/DirectoryIndex/d' /var/www/html/.htaccess
fi

set +e
export WP_CLI_CACHE_DIR="/tmp/.wp-cli/cache/"

wp core --allow-root is-installed
INSTALLED=$?
set -e
if [ $INSTALLED -eq 0 ]; then
    echo "Wordpress is already installed, skipping installation"
    runuser -u www-data -- mv /var/www/html/wp-content /var/www/html/wp-content_backup && echo "Successfully backed up wp-content" || echo "Failed to back up wp-content"
    runuser -u www-data -- ln -s /mnt/data/wp-content /var/www/html && echo "Created a symlink to wp-content" || echo "Failed to create symlink to wp-content"

    echo "Starting Apache"
    exec "$@"
else
    echo "Wordpress is not installed, going to install"
    if [ -z "$WORDPRESS_ADMIN_PASSWORD" ]; then
      runuser -u www-data -- wp core install --skip-email --title="$WORDPRESS_TITLE" \
       --url="$WORDPRESS_URL" --admin_user="$WORDPRESS_ADMIN_USER" \
       --admin_email="$WORDPRESS_ADMIN_EMAIL" --path=/var/www/html/
    else
      runuser -u www-data -- wp core install --skip-email --title="$WORDPRESS_TITLE" --url="$WORDPRESS_URL" \
      --admin_user="$WORDPRESS_ADMIN_USER" --admin_email="$WORDPRESS_ADMIN_EMAIL" \
      --admin_password="$WORDPRESS_ADMIN_PASSWORD" --path=/var/www/html/
    fi
    #Example of adding an image to use it as a product image
    export PRODUCT_IMAGE_ID=$(runuser -u www-data -- wp media import https://jx.testplesk.com/wp-content/uploads/2020/10/bg_wptoolkit.png --porcelain)
    runuser -u www-data -- wp plugin activate woocommerce
    runuser -u www-data -- wp theme activate storefront
    runuser -u www-data -- wp --user=1 wc product create --name="Example of a simple product" --type="simple" --regular_price="11.00" --images='[{"id":"'$PRODUCT_IMAGE_ID'"}]'
    runuser -u www-data -- wp --user=1 wc product create --name="Example of an variable product" --type="variable" --attributes='[ { "name":"size", "variation":"true", "options":"X|XL" } ]'
    runuser -u www-data -- wp --user=1 wc product_variation create 11 --attributes='[ { "name":"size", "option":"X" } ]' --regular_price="51.00"
    runuser -u www-data -- wp option update page_on_front 5
    runuser -u www-data -- wp option update show_on_front page
    echo "End configuring WordPress"
fi

set -u

mkdir -p /mnt/data/
chown www-data:www-data  /mnt/data
runuser -u www-data -- cp -pr /var/www/html/wp-content  /mnt/data/ &
COPY_PID=$!
echo "Start copying wp-content files, PID is $COPY_PID"
start_time=$(date +%s)

echo "Starting temporary Apache for at time of copying wp-content to EFS directory"
"$@" &
APACHE_PID=$!
while true; do
    sleep 1
    if ps -p $COPY_PID > /dev/null
    then
        echo "Copying in progress, $(($(date +%s)-start_time)) seconds elapsed"
    else
        echo "Copying is finished and take $(($(date +%s)-start_time)) seconds"
        runuser -u www-data -- mv /var/www/html/wp-content /var/www/html/wp-content_backup && echo "Successfully backed up wp-content" || echo "Failed to back up wp-content"
        runuser -u www-data -- ln -s /mnt/data/wp-content /var/www/html && echo "Created a symlink to wp-content" || echo "Failed to create symlink to wp-content"
        echo "Kill temporary Apache and wait for child process"
        kill $APACHE_PID
        echo "Wait for child process to finish"
        wait $APACHE_PID
        echo "Starting Apache to WordPress"
        exec "$@"
        break
    fi
done