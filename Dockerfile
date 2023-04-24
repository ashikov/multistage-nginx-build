FROM debian:11 AS build-nginx

RUN apt update && apt -yq install wget gcc make libpcre3-dev zlib1g-dev

RUN wget https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v0.3.2.tar.gz && \
    tar xvfz v0.3.2.tar.gz

RUN wget https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.0.5.tar.gz && \
    tar xvfz v2.0.5.tar.gz && \
    cd LuaJIT-2.0.5 && \
    make && \
    make install

ENV LUAJIT_LIB=/usr/local/lib
ENV LUAJIT_INC=/usr/local/include/luajit-2.0/

RUN wget https://github.com/openresty/lua-nginx-module/archive/refs/tags/v0.10.24.tar.gz && \
    tar xvfz v0.10.24.tar.gz

RUN wget http://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar xvfz nginx-1.24.0.tar.gz && \
    cd nginx-1.24.0 && \
    ./configure \
        --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" \
        --add-module=/ngx_devel_kit-0.3.2 \
        --add-module=/lua-nginx-module-0.10.24  && \
    make && \
    make install


FROM debian:11

RUN apt update && apt -yq install libluajit-5.1-2 wget gcc make

RUN wget https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.0.5.tar.gz && \
    tar xvfz v2.0.5.tar.gz && \
    cd LuaJIT-2.0.5 && \
    make && \
    make install

RUN wget https://github.com/openresty/lua-resty-core/archive/refs/tags/v0.1.26.tar.gz && \
    tar xvfz v0.1.26.tar.gz && \
    cd lua-resty-core-0.1.26 && \
    make install PREFIX=/opt/nginx

RUN wget https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v0.13.tar.gz && \
    tar xvfz v0.13.tar.gz && \
    cd lua-resty-lrucache-0.13 && \
    make install PREFIX=/opt/nginx

ENV NGINX_PATH=/usr/local/nginx/sbin
ENV PATH=${NGINX_PATH}:$PATH

WORKDIR ${NGINX_PATH}

RUN useradd -r -s /bin/false www

COPY --from=build-nginx ${NGINX_PATH}/nginx .

RUN mkdir  ../logs && mkdir ../conf

COPY nginx.conf ../conf/.

RUN chmod +x nginx

CMD ["nginx", "-g", "daemon off;"]
