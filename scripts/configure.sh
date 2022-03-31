#!/bin/bash

export WP_CLI_CACHE_DIR="/tmp/.wp-cli/cache/"

echo "Start Wordpress configuring"
if $(wp core is-installed); then
    echo "Wordpress is already installed, stop configuring"
    exit;
fi

wp core install --skip-email --title='WSP AWS' --admin_user=WORDPRESS_ADMIN_USER --admin_password=$WORDPRESS_ADMIN_PASSWORD \
    --admin_email=$WORDPRESS_ADMIN_EMAIL  --url=$WORDPRESS_URL
wp theme install storefront --activate \
    && wp plugin install woocommerce --activate \
    && wp --user=1 wc product create --name="Example of a simple product" --type="simple" --regular_price="1.00" \
    && wp --user=1 wc product create --name="Example of an variable product" --type="variable" \
       --attributes='[ { "name":"size", "variation":"true", "options":"X|XL" } ]' \
    && wp --user=1 wc product_variation create 11 \
       --attributes='[ { "name":"size", "option":"X" } ]' --regular_price="1.00" \
    && wp --user=1 wc product_variation create 11 \
       --attributes='[ { "name":"size", "option":"XL" } ]' --regular_price="2.00"

echo >&2 "Complete! WordPress has been configured"