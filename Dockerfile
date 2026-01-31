FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libxslt-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    libsodium-dev \
    unzip \
    vim \
    wget \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by Magento 2
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    gd \
    intl \
    mbstring \
    mysqli \
    pdo_mysql \
    soap \
    xsl \
    zip \
    sockets \
    sodium \
    opcache

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Set up cron for Magento (will be configured after installation)
RUN touch /var/log/cron.log

# Copy custom entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
