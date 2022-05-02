There is an WooCommerce docker image.  You can run it as you want, but it's better to use WSP AWS (https://wsp-aws.io).

# How to use the stress test

1. git clone this repo
1. execute `docker run -i grafana/k6 -e DOMAIN_NAME="the domain name where WooCommerce is installed" run - <stress-test-k6.js`

# Configuration variables
You can also use the following configuration variables:
1. USERS - the number of simultaneously walking users (i.e. the number of workers).  Default is 10.
1. DURATION - the active phase duration.  Default is "58m" = 58 minutes.  So the whole duration is 1 hour (58 minutes active phase, 1 minute warm up, 1 minute tear down).

Example: `docker run -i grafana/k6 -e DOMAIN_NAME="domainName" -e USERS=10 -e DURATION="58m" run - <stress-test-k6.js`