There is an WooCommerce docker image.  You can run it as you want, but it's better to use WSP AWS (https://wsp-aws.io).
# How image works

Image consists of two logical parts, a Wordpress installer and a web server serving the installed website. 
When the container starts, it checks for the presence of the installed website on an external volume. If the website is not installed, the flag is captured. At this time, other containers running in parallel are in a waiting mode, and only one container performs the installation. 
The process of installing WordPress require a real-time database connection, the site starts immediately after installation and demo data is populated, and then the installed site is copied to an external volume (AWS EFS) which takes 150-180 seconds. 
The temporary Apache is stopped and the second flag of successful installation is set. The container then switches to site display mode by changing the site directory from internal to external volume. Other containers, if running in parallel, can switch from wait mode to display mode once they see the successful installation flag. 
The same will happen with all newly launched containers, they will bypass the installation and immediately start serving the site from the external volume.

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

