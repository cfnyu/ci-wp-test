FROM 953175402367.dkr.ecr.us-east-1.amazonaws.com/php:latest

LABEL description="WordPress container based on NYU PHP using ROOTS"

ENV PROJECT_NAME=default

RUN apt-get update && \
    apt-get install -y \
        mysql-client \
        php7.0-curl

WORKDIR /tmp

RUN curl -o /usr/local/bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp-cli.phar \
    && mv /usr/local/bin/wp-cli.phar /usr/local/bin/wp \
    && chown www-data:www-data /usr/local/bin/wp && \
    sed -i 's/\/var\/www/\/var\/www\/web/g' /etc/apache2/sites-available/000-default.conf && \
    phpenmod curl && \
    chown -R www-data:www-data /var/www/

USER www-data

RUN composer create-project roots/bedrock $PROJECT_NAME && \
    mv /tmp/$PROJECT_NAME/* /var/www

WORKDIR /var/www

RUN composer install

USER root

# Apache Hardening
RUN sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf && \
    sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf && \
    sed -i 's/Options Indexes FollowSymLinks/Options -Indexes -FollowSymLinks/g' /etc/apache2/apache2.conf && \
    groupadd apache && \
    useradd -g apache apache && \
    chown -R apache:apache /etc/apache2 && \
    sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=apache/g' /etc/apache2/envvars && \
    sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=apache/g' /etc/apache2/envvars

# Project Hardening
RUN chown -R nobody:nogroup /var/www/ && \
    chown -R www-data:www-data /var/www/web/app && \
    service apache2 restart

EXPOSE 80

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]