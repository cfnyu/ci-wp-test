FROM ubuntu:16.04

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
       apache2 \
       curl \
       php7.0 \
       php7.0-cli \
       libapache2-mod-php \
       php7.0-gd \
       php7.0-json \
       php7.0-ldap \
       php7.0-mbstring \
       php7.0-mcrypt \
       php7.0-mysql \
       php7.0-opcache \
       php7.0-pgsql \
       php7.0-sqlite3 \
       php7.0-xml \
       php7.0-xsl \
       php7.0-zip \
       php7.0-soap \
       supervisor \
       composer

LABEL description="WordPress container based on NYU PHP using ROOTS"

ENV PROJECT_NAME=default
ENV DB_HOST=localhost

RUN apt-get update; apt-get install -y mysql-client php-curl

WORKDIR /tmp

RUN curl -o /usr/local/bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x /usr/local/bin/wp-cli.phar && \
    mv /usr/local/bin/wp-cli.phar /usr/local/bin/wp && \
    chown www-data:www-data /usr/local/bin/wp && \
    sed -i 's/\/var\/www/\/var\/www\/web/g' /etc/apache2/sites-available/000-default.conf && \
    chown -R www-data:www-data /var/www/ && \
    phpenmod curl && \
    a2enmod rewrite

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

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-entrypoint.sh /usr/local/bin/

RUN echo "SetEnvIf x-forwarded-proto https HTTPS=on" >> /etc/apache2/apache2.conf && \
    chown -R www-data:www-data /var/www && \
    rm -rf html/

ENTRYPOINT ["docker-entrypoint.sh"]
