FROM php:7.4-fpm

MAINTAINER j0nnybrav079

# used to setup xdebug remote-ip
ARG remoteIp

# set timezone
RUN echo "UTC" > /etc/timezone

# install Xdebug
RUN apt-get update \
    && pecl install xdebug\
        && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_host=$remoteIp" >> /usr/local/etc/php/conf.d/xdebug.ini

RUN apt-get update \
    && apt-get install -y libmagickwand-dev \
    && apt-get install -y imagemagick \
    && pecl install imagick \
    && docker-php-ext-enable imagick

# install composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# install other libs and tools
RUN apt-get update \
    && apt-get install -y \
        curl \
        git \
        libfreetype6-dev \
        libfreetype6-dev \
        libicu-dev \
        libwebp-dev \
        libmemcached-dev \
        libmcrypt-dev \
        libonig-dev \
        libpq-dev \
        libzip-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libmagickwand-6.q16-dev \
        libssl-dev \
        libxml2-dev \
        libmcrypt-dev \
        libjpeg-dev \
        openssh-client \
        unzip \
        ghostscript \
        vim \
        libzip-dev \
        zip \
        --no-install-recommends \
    && docker-php-ext-install \
        bcmath \
        calendar \
        iconv \
        intl \
        json \
        opcache \
        pdo \
        pdo_pgsql \
        pdo_mysql \
        phar \
        mysqli \
        pgsql \
        session \
        sockets \
        soap \
        tokenizer \
        zip \
    && docker-php-ext-configure gd \
        --enable-gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install gd
#    && docker-php-ext-enable opcache \

## blackfire PHP Probe
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(uname -m) \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/$architecture/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8307\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz