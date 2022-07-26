FROM php:8.1.3-apache

RUN a2enmod rewrite

# Get packages that we need in container
RUN apt-get update -q -y \
  && apt-get install -q -y --no-install-recommends \
  ca-certificates \
  curl \
  acl \
  sudo \
  ghostscript \
  # Needed for the php extensions we enable below
  libfreetype6 \
  libjpeg62-turbo \
  libxpm4 \
  libpng16-16 \
  libicu67 \
  libxslt1.1 \
  libmemcachedutil2 \
  libzip-dev \
  imagemagick \
  libonig5 \
  libpq5 \ 
  unzip \
  git \
  less \
  mariadb-client \
  vim \
  wget \
  tree \
  gdb-minimal \
  && rm -rf /var/lib/apt/lists/*

# Install and configure php plugins
RUN set -xe \
  && buildDeps=" \
  $PHP_EXTRA_BUILD_DEPS \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libxpm-dev \
  libpng-dev \
  libicu-dev \
  libxslt1-dev \
  libmemcached-dev \
  libzip-dev \
  libxml2-dev \
  libonig-dev \
  libmagickwand-dev \
  libpq-dev \
  chromium \
  firefox-esr \
  " \
  && apt-get update -q -y && apt-get install -q -y --no-install-recommends $buildDeps && rm -rf /var/lib/apt/lists/* \
  # Extract php source and install missing extensions
  && docker-php-source extract \
  && docker-php-ext-configure mysqli --with-mysqli=mysqlnd \
  && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
  && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
  && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-xpm=/usr/include/ --enable-gd-jis-conv \
  && docker-php-ext-install exif gd mbstring intl xsl zip mysqli pdo_mysql pdo_pgsql pgsql soap bcmath \
  && docker-php-ext-enable opcache \
  && cp /usr/src/php/php.ini-production ${PHP_INI_DIR}/php.ini 

# Install imagemagick
RUN pecl install -o imagick && docker-php-ext-enable imagick 

#cronbundle
RUN docker-php-ext-configure pcntl --enable-pcntl \
  && docker-php-ext-install \
    pcntl

# Install xdebug but not active TODO:àfinir
#RUN pecl install -o "xdebug" 
#COPY xdebug.ini ${PHP_INI_DIR}/conf.d/xdebug.ini.disabled
#COPY xdebug.sh /scripts/xdebug.sh
#RUN chmod +x /scripts/xdebug.sh
#RUN /scripts/xdebug.sh

# Delete source & builds deps so it does not hang around in layers taking up space
RUN pecl clear-cache \
  && rm -Rf "$(pecl config-get temp_dir)/*" \
  && docker-php-source delete \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps

COPY php.ini /php.ini
RUN cat /php.ini>>${PHP_INI_DIR}/php.ini

# RUN wget https://getcomposer.org/download/2.0.9/composer.phar \
#   && mv composer.phar /usr/bin/composer && chmod +x /usr/bin/composer

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash -
RUN apt-get install -y nodejs nano pandoc gcc g++ cmake libpng-dev libfreetype-dev libfontconfig1-dev
RUN npm install -g yarn

COPY apache.conf /etc/apache2/sites-enabled/000-default.conf
COPY . /app


RUN apt install memcached libmemcached-tools libnss3 -y # chromium-driver
RUN set -ex \
    && rm -rf /var/lib/apt/lists/* \
    && MEMCACHED="`mktemp -d`" \
    && curl -skL https://github.com/php-memcached-dev/php-memcached/archive/master.tar.gz | tar zxf - --strip-components 1 -C $MEMCACHED \
    && docker-php-ext-configure $MEMCACHED \
    && docker-php-ext-install $MEMCACHED \
    && rm -rf $MEMCACHED

ENV SYMFONY_DEPRECATIONS_HELPER=weak 

# RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo    
# Chromium and ChromeDriver
ENV PANTHER_NO_SANDBOX 1
# Not mandatory, but recommended
ENV PANTHER_CHROME_ARGUMENTS='--disable-dev-shm-usage'

RUN LC_ALL=fr_FR.UTF-8

RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN mv phpunit.phar /usr/local/bin/phpunit
RUN command -v phpunit
RUN wget https://github.com/dantleech/fink/releases/download/0.10.3/fink.phar
RUN chmod +x fink.phar
RUN mv fink.phar /usr/local/bin/fink.phar

WORKDIR /app
RUN echo 'alias sc="php /app/bin/console"' >> ~/.bashrc

CMD ["apache2-foreground"]
