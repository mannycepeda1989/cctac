FROM php:8.3-apache

# 🔹 Instalar dependencias incluyendo libaio1 desde Bookworm
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libxml2-dev \
    wget \
    unzip \
    libaio-dev \
    libncurses6 \
    && wget http://deb.debian.org/debian/pool/main/liba/libaio/libaio1_0.3.113-4_amd64.deb \
    && apt-get install -y ./libaio1_0.3.113-4_amd64.deb \
    && rm libaio1_0.3.113-4_amd64.deb \
    && docker-php-ext-install -j "$(nproc)" \
    soap \
    pdo_mysql \
    zip \
    opcache \
    bcmath
    
# 🔹 Aplicar parches de seguridad (Apache & GnuTLS)
RUN apt-get update && apt-get install -y --only-upgrade apache2 libgnutls30t64

# 🔹 Instalar composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 🔹 Instalar Oracle Instant Client
RUN mkdir /opt/oracle
RUN wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-basic-linux.x64-21.6.0.0.0dbru.zip \
 && wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-sdk-linux.x64-21.6.0.0.0dbru.zip \
 && wget https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-sqlplus-linux.x64-21.6.0.0.0dbru.zip \
 && unzip -o instantclient-basic-linux.x64-21.6.0.0.0dbru.zip -d /opt/oracle \
 && unzip -o instantclient-sdk-linux.x64-21.6.0.0.0dbru.zip -d /opt/oracle \
 && unzip -o instantclient-sqlplus-linux.x64-21.6.0.0.0dbru.zip -d /opt/oracle \
 && rm -rf *.zip \
 && mv /opt/oracle/instantclient_21_6 /opt/oracle/instantclient

ENV LD_LIBRARY_PATH /opt/oracle/instantclient/
RUN ldconfig

# 🔹 Configuración de extensiones PHP para Oracle
RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient,21.1 \
 && echo 'instantclient,/opt/oracle/instantclient/' | pecl install oci8-3.2.1 \
 && docker-php-ext-install pdo_oci \
 && docker-php-ext-enable oci8

# 🔹 Configuración PHP recomendada para Cloud Run
RUN set -ex; \
    { \
        echo "; Cloud Run enforces memory & timeouts"; \
        echo "memory_limit = 256M"; \
        echo "max_execution_time = 60"; \
        echo "; File upload at Cloud Run network limit"; \
        echo "upload_max_filesize = 32M"; \
        echo "post_max_size = 32M"; \
        echo "; Configure Opcache for Containers"; \
        echo "opcache.enable = On"; \
        echo "opcache.validate_timestamps = Off"; \
        echo "; Configure Opcache Memory (Application-specific)"; \
        echo "opcache.memory_consumption = 128"; \
    } > "$PHP_INI_DIR/conf.d/cloud-run.ini"

WORKDIR /var/www/html
COPY . ./

# 🔹 Instalar dependencias de Laravel
RUN composer install --no-dev --optimize-autoloader

# 🔹 Permisos
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# 🔹 Apache configuración
RUN sed -i 's/80/8080/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf
RUN a2enmod rewrite
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

EXPOSE 8080
CMD ["apache2-foreground"]
