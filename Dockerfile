FROM php:7.4-fpm

# version defined
ENV SWOOLE_VERSION 4.4.8
ENV PHPREDIS_VERSION 5.1.1

# set timezone
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone

# system update
RUN apt-get update \
&& apt-get install -y \  
curl \  
wget \       
zip \
libz-dev \
libssl-dev \
libnghttp2-dev \
libpcre3-dev \
libmemcached-dev \
zlib1g-dev \
vim \
&& apt-get clean \
&& apt-get autoremove -y \
&& wget https://github.com/alanxz/rabbitmq-c/releases/download/v0.11.0/rabbitmq-c-0.11.0.tar.gz \
&& tar -zxvf rabbitmq-c-0.8.0.tar.gz \
&& cd rabbitmq-c-0.8.0 \
&& ./configure --prefix=/usr/local/rabbitmq-c \
&& make && make install

# phpredis
RUN pecl install redis-${PHPREDIS_VERSION} \
    && docker-php-ext-enable redis

RUN docker-php-ext-install mysqli && docker-php-ext-install pdo_mysql && docker-php-ext-enable opcache

# composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/bin/composer \
    && composer self-update --clean-backups

# use aliyun composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# swoole ext
RUN wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
    cd swoole \
    && phpize \
    && ./configure --enable-openssl --enable-http2 \
    && make -j$(nproc)\
    && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole
