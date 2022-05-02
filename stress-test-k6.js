// run command: docker run -i grafana/k6 -e DOMAIN_NAME="domain" -e USERS=20 -e DURATION="58m" run - <stress-test-k6.js

import http from "k6/http";
import { check, group, sleep } from "k6";
import { Rate } from "k6/metrics";

var domainName; // domain name where our WooCommerce is set up
var pscheme = 'https';
var users = 10;  // how many users visits our website simultaneously
var minPause = 2; // a random pause between http requests (in seconds)
var maxPause = 5;
var testDuration = "58m";

// domain name is required
if (__ENV.DOMAIN_NAME) {
    domainName = __ENV.DOMAIN_NAME;
} else {
    throw new Error(`DOMAIN_NAME is "${domainName}".  Specify DOMAIN_NAME to load.`);
}

// defaults can be overwriten via env variables
users = __ENV.USERS ? __ENV.USERS : users;
testDuration = __ENV.DURATION ? __ENV.DURATION : testDuration;

// A custom metric to track failure rates
var failureRate = new Rate("check_failure_rate");

// Options
export let options = {
    stages: [
        // Linearly ramp up from 1 to 50 VUs during first minute
        { target: users, duration: "1m" },
        // Hold at ${users} VUs for the next period
        { target: users, duration: testDuration },
        // Linearly ramp down from ${users} to 0 VUs over the last minute
        { target: 0, duration: "1m" }
    ],
    thresholds: {
        // We want the 95th percentile of all HTTP request durations to be less than 2s
        "http_req_duration": ["p(95)<2000"],
        // Requests with the staticAsset tag should finish faster
        "http_req_duration{staticAsset:yes}": ["p(95)<500"],
        // Thresholds based on the custom metric we defined and use to track application failures
        "check_failure_rate": [
            // Global failure rate should be less than 1%
            "rate<0.01",
            // Abort the test early if it climbs over 80%
            { threshold: "rate<=0.8", abortOnFail: true },
        ],
    },
};

export default function () {
    let response = http.get(`${pscheme}://${domainName}/?product=example-of-an-variable-product`);

    // check() returns false if any of the specified conditions fail
    let checkRes = check(response, {
        "http2 is used": (r) => r.proto === "HTTP/2.0",
        "status is 200": (r) => r.status === 200,
        "content is present": (r) => r.body.indexOf("Description") !== -1,
    });

    // We reverse the check() result since we want to count the failures
    failureRate.add(!checkRes);

    // Load static assets, all requests
    group("Static Assets", function () {
        // Execute multiple requests in parallel like a browser, to fetch static resources
        let resps = http.batch([
            ["GET", `${pscheme}://${domainName}/wp-content/uploads/woocommerce-placeholder-324x324.png`, null, { tags: { staticAsset: "yes" } }],
            ["POST", `${pscheme}://${domainName}/?wc-ajax=get_refreshed_fragments`, null, { tags: { staticAsset: "yes" } }],
            ["GET", `${pscheme}://${domainName}/wp-content/themes/storefront/assets/js/woocommerce/header-cart.min.js?ver=4.1.`, null, { tags: { staticAsset: "yes" } }],
        ]);
        // Combine check() call with failure tracking
        failureRate.add(!check(resps, {
            "status is 200": (r) => r[0].status === 200 && r[1].status === 200,
            "reused connection": (r) => r[0].timings.connecting == 0,
        }));
    });

    sleep(Math.random() * (maxPause-minPause) + minPause); // Random sleep
}