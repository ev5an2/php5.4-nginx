FROM centos:7
MAINTAINER tang
RUN yum -y update
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone
#1.依赖
RUN yum install -y libstdc++-devel gcc gcc-c++ zlib-devel make pcre-devel gd-devel libxml2 libxml2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel openssl openssl-devel postgresql-devel \
 bzip2 bzip2-devel freetype freetype-devel gmp gmp-devel readline readline-devel libxslt libxslt-devel libtool

#2.nginx
ADD nginx/nginx-1.12.1.tar.gz /tmp
RUN cd /tmp/nginx-1.12.1 && \
    ./configure --prefix=/usr/local/nginx && \
    make -j 2 && \
    make install

RUN rm -rf /tmp/nginx-1.12.1* && yum clean all
COPY nginx/nginx.conf /usr/local/nginx/conf

#3.php-fpm
ADD php/php-5.4.31.tar.gz php/rabbitmq-c-0.8.0.tar.gz php/amqp-1.9.3.tgz php/gearman-1.1.2.tgz php/gearmand-1.1.2.tar.gz php/phpredis-2.2.4.tar.gz /tmp/

RUN cd /tmp/php-5.4.31 && \
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-mysql --with-mysqli \
    --with-openssl --with-zlib --with-curl --with-gd \
    --with-jpeg-dir --with-png-dir --with-iconv \
    --with-pdo-mysql --with-pdo-pgsql --with-pgsql \
    --enable-fpm --enable-mysqlnd --enable-zip --enable-mbstring \
    --enable-bcmath  --enable-pdo --enable-ftp --enable-gd-native-ttf && \
    make -j 4 && \
    make install && \
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && \
    sed -i "s/127.0.0.1/0.0.0.0/" /usr/local/php/etc/php-fpm.conf && \
    sed -i "21a \daemonize = no" /usr/local/php/etc/php-fpm.conf
COPY php/php.ini /usr/local/php/etc

#4.redis拓展
RUN yum install -y autoconf && \
    cd /tmp/phpredis-2.2.4 && \
    /usr/local/php/bin/phpize && \
    ./configure --with-php-config=/usr/local/php/bin/php-config &&\
    make && \
    make install

#5.ampq拓展（rabbitmq-c和amqp）
RUN yum install -y autotools-dev automake m4 perl aptitude &&\
    cd /tmp/rabbitmq-c-0.8.0 && \
    autoreconf -ivf &&\
    ./configure --prefix=/usr/local/rabbitmq-c-0.8.0 &&\
    make && \
    make install && \
    cd /tmp/amqp-1.9.3 && \
    /usr/local/php/bin/phpize && \
    ./configure --with-php-config=/usr/local/php/bin/php-config --with-amqp --with-librabbitmq-dir=/usr/local/rabbitmq-c-0.8.0 &&\
    make && \
    make install

#6.gearman拓展(gearmand和gearman)
RUN yum install -y boost boost-devel* boost-doc  gperf* libevent-devel* libuuid-devel && \
    cd /tmp/gearmand-1.1.2 && \
    ./configure && \
    make && \
    make install && \
    cd /tmp/gearman-1.1.2 && \
    /usr/local/php/bin/phpize && \
    ./configure --with-php-config=/usr/local/php/bin/php-config --with-gearman=/usr/local/gearmand-1.1.2/ &&\
    make && \
    make install

#7.Install-Composer
RUN curl -sS https://getcomposer.org/installer | \
    /usr/local/php/bin/php -- --install-dir=/usr/local/bin/ --filename=composer

#8删除临时文件
RUN rm -rf /tmp/php-5.4.31* /tmp/amqp-1.9.3* /tmp/gearman-1.1.2* /tmp/phpredis-2.2.4* /tmp/rabbitmq-c-0.8.0* /tmp/gearmand-1.1.2* && yum clean all

EXPOSE 80 9000
ADD start.sh /
RUN chmod +x /start.sh
ENTRYPOINT ["/start.sh" ]


