#!/bin/bash

# args: source

set -e

sed -i "s/env\[SCS_REQUIRES_MYSQL\] = \(.*\)/env[SCS_REQUIRES_MYSQL] = $SCS_REQUIRES_MYSQL/" /scs/etc/php-fpm/php-fpm.ini

if [ "run" != "$1" ]; then
    supervisorctl -c /scs/etc/supervisor.conf restart php-fpm
fi
