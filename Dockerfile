# -- BASE
FROM php:8.2.9-fpm-bullseye AS base

# Arguments defined in docker-compose.yml
ARG user
ARG uid

WORKDIR /usr/src/app

#  Update and install dependencies and clean up
RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends git curl zip unzip libpng-dev libonig-dev libxml2-dev && \
    apt-get install -y --no-install-recommends build-essential python3 libfontconfig1 dumb-init && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u ${uid} -d /home/${user} ${user}
RUN mkdir -p /home/${user}/.composer && \
    chown -R ${user}:${user} /home/${user}

# Change current user to ${user}
RUN chown -R ${user}:${user} /usr/src/app/

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Copy package and composer files
COPY --chown=${user}:${user} composer.json ./
COPY --chown=${user}:${user} composer.lock ./
COPY --chown=${user}:${user} package.json ./
COPY  --chown=${user}:${user} vite.config.js ./
COPY --chown=${user}:${user} artisan ./

ENTRYPOINT ["dumb-init", "--"]

# -- BUILD
FROM base AS build

# Copy source files
COPY --chown=${user}:${user} . .

# Install dependencies
RUN composer install

# -- PRODUCTION
FROM base AS production

ENV APP_ENV=production

# Copy production dependencies
COPY --chown=${user}:${user} --from=build /usr/src/app/vendor ./vendor

# Copy production files
COPY --chown=${user}:${user} --from=build /usr/src/app/app ./app
COPY --chown=${user}:${user} --from=build /usr/src/app/bootstrap ./bootstrap
COPY --chown=${user}:${user} --from=build /usr/src/app/config ./config
COPY --chown=${user}:${user} --from=build /usr/src/app/database ./database
COPY --chown=${user}:${user} --from=build /usr/src/app/public ./public
COPY --chown=${user}:${user} --from=build /usr/src/app/resources ./resources
COPY --chown=${user}:${user} --from=build /usr/src/app/routes ./routes
COPY --chown=${user}:${user} --from=build /usr/src/app/storage ./storage
COPY --chown=${user}:${user} --from=build /usr/src/app/.env ./.env
COPY --chown=${user}:${user} --from=build /usr/src/app/artisan ./artisan

# Make artisan executable
RUN chmod +x ./artisan

# Expose port 3000
EXPOSE 3000

USER ${user}

# Start
CMD ["dumb-init", "php", "artisan", "serve", "--host=0.0.0.0", "--port=3000"]
