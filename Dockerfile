# Build stage
FROM composer as builder
# Set working directory
WORKDIR /app
# Copy app to working directory
COPY . .
# Install the dependencies
RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction

# Run stage
FROM php:8.1-buster AS production
# Install system dependencies and clear cache
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    unzip \
    nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Set working directory
WORKDIR /var/www/html/
# Get latest Composer

COPY --from=builder /app /var/www/html/

COPY --from=builder /usr/bin/composer /usr/bin/composer

ARG user=sail
ARG uid=1337

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user && \
    mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user && \
    chown -R $user:$user /var/www/html/ && \
    cp .env.example .env && \
    php artisan key:generate && \
    php artisan config:cache

USER $user

EXPOSE 80

CMD [ "php", "artisan", "serve", "--port=80", "--host=0.0.0.0" ]