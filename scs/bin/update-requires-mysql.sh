#!/bin/bash

sed -i "s/env\[SCS_REQUIRES_MYSQL\] = \(.*\)/env[SCS_REQUIRES_MYSQL] = $SCS_REQUIRES_MYSQL/" /scs/etc/php-fpm/php-fpm.ini
