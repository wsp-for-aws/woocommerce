There is an WooCommerce docker image with automatic installation.

# How to use the stress test

1. git clone this repo
1. execute `docker run -i grafana/k6 -e DOMAIN_NAME="the domain name where WooCommerce is installed" run - <stress-test-k6.js`