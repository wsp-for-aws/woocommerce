There is an WooCommerce docker image.  You can run it as you want, but it's better to use WSP AWS (https://wsp-aws.io).
# How it works

This repository contains a Docker image for Wordpress, packed and ready to run. The image runs a check when launched to confirm that Wordpress has been installed. If it has not, the installation process is initiated, using file locks to prevent multiple instances of the installer from running simultaneously.

Once installed, the application is immediately accessible and ready to respond to HTTP requests, allowing for quick and easy access to Wordpress. This immediate accessibility also enables the application to pass liveness and readiness checks. In the background, the application's files are copied to an EFS (Elastic File System) for persistent storage, so that data will not be lost in case of a container restart.

After the files are copied to EFS, the application starts storing its files in the EFS and Apache is reloaded to reflect the change in directory. The setup ensures that the data is safe and available even after a restart of the container.

Additionally, this script installs and configures WordPress, the WooCommerce plugin, and the Storefront theme. It also creates two sample products (one simple, one variable) and sets the shop page as the front page. The WordPress installation, plugins, and themes are copied from a temporary (ephemeral) volume to a persistent volume on Amazon Elastic File System (EFS). The script sets several environment variables for configuration options (e.g. WORDPRESS_ADMIN_PASSWORD, WORDPRESS_TITLE, etc.). It also enables auto-updates for all plugins and themes.

# How to use the stress test

Execute `docker run -i grafana/k6 -e DOMAIN_NAME="<WooCommerceDomainName>" run github.com/wspaws/woocommerce/stress-test-k6.js`.

Notes:
* git clone is not required
* if DOMAIN_NAME is IDN please use punycode

If you'd like to modify the script and run it locally, use the following command: `docker run -i grafana/k6 -e DOMAIN_NAME="<WooCommerceDomainName>" run - <stress-test-k6.js`

If you'd like to monitor how the stress test is going, we'd recommend the following useful set of preconfigured software:
1. `git clone https://github.com/luketn/docker-k6-grafana-influxdb.git`
1. `cd docker-k6-grafana-influxdb`
1. `docker-compose up -d influxdb grafana`
1. `docker-compose run k6 -e DOMAIN_NAME="<WooCommerceDomainName>" run github.com/wspaws/woocommerce/stress-test-k6.js`
1. see results in your web browser via http://localhost:3000/d/k6/k6-load-testing-results

## Configuration variables
You can also use the following configuration variables:
1. USERS - the start number of simultaneously walking users (i.e. the number of workers).  Default is 10.  On the second phase there will be twice more users and the third phase runs triple amount of users.
1. PHASE_DURATION - the phase duration in minutes.  Default is 20, so the whole test will take up to 72 minutes (see the source code for explanation)

Example: `docker run -i grafana/k6 -e DOMAIN_NAME="my-woo-commerce.example.com" -e USERS=10 -e PHASE_DURATION=20 run github.com/wspaws/woocommerce/stress-test-k6.js`

