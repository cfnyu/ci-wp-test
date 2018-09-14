#!/bin/bash
set -e

if [ ! -f /var/www/.env ]; then 
    touch /var/www/.env
fi

chown www-data:www-data /var/www/.env

if [ ! -d /var/www/.wp-cli ]; then
    mkdir /var/www/.wp-cli
fi

chown www-data:www-data /var/www/.wp-cli

/bin/su -s /bin/bash -c "wp package install aaemnnosttv/wp-cli-dotenv-command" - www-data
/bin/su -s /bin/bash -c "wp dotenv salts regenerate" - www-data

# now that we're definitely done writing configuration, 
# let's clear out the relevant envrionment variables 
# (so that stray "phpinfo()" calls don't leak secrets from our code)
for e in "${envs[@]}"; do
    unset "$e"
done

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf

exec "$@"
