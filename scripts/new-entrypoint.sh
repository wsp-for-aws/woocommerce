#!/bin/bash

/usr/local/bin/docker-entrypoint.sh php-fpm|| su www-data -c '/configure.sh' -s /bin/bash

exec "$@"