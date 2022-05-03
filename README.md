There is an WooCommerce docker image.  You can run it as you want, but it's better to use WSP AWS (https://wsp-aws.io).

# How to use the stress test

Execute `docker run -i grafana/k6 -e DOMAIN_NAME="<WooCommerceDomainName>" run github.com/wspaws/woocommerce/stress-test-k6.js`.  Note: git clone is not required.

## Configuration variables
You can also use the following configuration variables:
1. USERS - the number of simultaneously walking users (i.e. the number of workers).  Default is 10.
1. DURATION - the active phase duration.  Default is "58m" = 58 minutes.  So the whole duration is 1 hour (58 minutes active phase, 1 minute warm up, 1 minute tear down).

Example: `docker run -i grafana/k6 -e DOMAIN_NAME="my-woo-commerce.example.com" -e USERS=10 -e DURATION="58m" run github.com/wspaws/woocommerce/stress-test-k6.js`