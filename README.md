There is an WooCommerce docker image.  You can run it as you want, but it's better to use WSP AWS (https://wsp-aws.io).

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