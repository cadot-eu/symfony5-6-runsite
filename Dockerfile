FROM php:8.1.33-apache

RUN a2enmod rewrite

# Set environment variables
ENV SYMFONY_VERSION=6 \
    COMPOSER_ALLOW_SUPERUSER=1 \
    PATH=/var/www/html/vendor/bin:$PATH

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    libicu-dev \
    libpng-dev \
    libzip-dev \
    nano \
    unzip \
    zip

# Install PHP extensions
RUN docker-php-ext-install \
    bcmath \
    intl \
    opcache \
    zip \
    exif

RUN apt-get install -y ca-certificates curl gnupg; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
     | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    NODE_MAJOR=18; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
     > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install nodejs -y;

# Install Yarn (via Corepack to avoid npm dependency)
RUN corepack enable && corepack prepare yarn@1.22.22 --activate

RUN apt-get update && apt-get install -y \
    libmagickwand-dev --no-install-recommends \
    && pecl install imagick \
	&& docker-php-ext-enable imagick



# Install AMQP extension
RUN apt-get install -y librabbitmq-dev && \
    pecl install amqp && \
    docker-php-ext-enable amqp

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


ENV SYMFONY_DEPRECATIONS_HELPER=weak 

# RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo    
# Chromium and ChromeDriver
ENV PANTHER_NO_SANDBOX 1
# Not mandatory, but recommended
ENV PANTHER_CHROME_ARGUMENTS='--disable-dev-shm-usage'

RUN LC_ALL=fr_FR.UTF-8

COPY php.ini /php.ini
RUN cat /php.ini>>${PHP_INI_DIR}/php.ini

# Install Xdebug
# RUN pecl install xdebug && \
#    docker-php-ext-enable xdebug

#MYSQL
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd \
&& docker-php-ext-install pdo pdo_mysql

#APCU
ENV EXT_APCU_VERSION=5.1.22

RUN docker-php-source extract \
&& mkdir -p /usr/src/php/ext/apcu \
&& curl -fsSL https://github.com/krakjoe/apcu/archive/v$EXT_APCU_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/apcu --strip 1 \
&& docker-php-ext-install apcu \
&& docker-php-source delete

    
RUN wget https://github.com/dantleech/fink/releases/download/0.10.3/fink.phar
RUN chmod +x fink.phar
RUN mv fink.phar /usr/bin/fink.phar

# chromium-driver
RUN apt install memcached libmemcached-tools libnss3 chromium -y 

#GD
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ 
RUN docker-php-ext-install gd

#webp
RUN apt-get install -y webp

#cache pour apache
RUN a2enmod cache
RUN a2enmod cache_disk
RUN a2enmod headers

COPY apache.conf /etc/apache2/sites-enabled/000-default.conf
COPY . /app

WORKDIR /app
RUN echo 'alias sc="php /app/bin/console"' >> ~/.bashrc

CMD ["apache2-foreground"]
