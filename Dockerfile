FROM debian:11 AS build-nginx

ENV NGX_DEVEL_KIT_VERSION=0.3.2
ENV LUAJIT_VERSION=2.0.5
ENV LUA_NGINX_MODULE_VERSION=0.10.24
ENV LUA_RESTY_CORE_VERSION=0.1.26
ENV LUA_RESTY_LRUCACHE_VERSION=0.13
ENV NGINX_VERSION=1.24.0

RUN apt update && apt -yq install wget gcc make libpcre3-dev zlib1g-dev

RUN wget https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v${NGX_DEVEL_KIT_VERSION}.tar.gz && \
    tar xvfz v${NGX_DEVEL_KIT_VERSION}.tar.gz

RUN wget https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v${LUAJIT_VERSION}.tar.gz && \
    tar xvfz v${LUAJIT_VERSION}.tar.gz && \
    cd LuaJIT-${LUAJIT_VERSION} && \
    make && \
    make install

ENV LUAJIT_LIB=/usr/local/lib
ENV LUAJIT_INC=/usr/local/include/luajit-2.0/

RUN wget https://github.com/openresty/lua-nginx-module/archive/refs/tags/v${LUA_NGINX_MODULE_VERSION}.tar.gz && \
    tar xvfz v${LUA_NGINX_MODULE_VERSION}.tar.gz

RUN wget https://github.com/openresty/lua-resty-core/archive/refs/tags/v${LUA_RESTY_CORE_VERSION}.tar.gz && \
    tar xvfz v${LUA_RESTY_CORE_VERSION}.tar.gz && \
    cd lua-resty-core-${LUA_RESTY_CORE_VERSION} && \
    make install PREFIX=/opt/nginx

RUN wget https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v${LUA_RESTY_LRUCACHE_VERSION}.tar.gz && \
    tar xvfz v${LUA_RESTY_LRUCACHE_VERSION}.tar.gz && \
    cd lua-resty-lrucache-${LUA_RESTY_LRUCACHE_VERSION} && \
    make install PREFIX=/opt/nginx

RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xvfz nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
        --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" \
        --add-module=/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} \
        --add-module=/lua-nginx-module-${LUA_NGINX_MODULE_VERSION} && \
    make && \
    make install

FROM debian:11

ENV NGINX_PATH=/usr/local/nginx/sbin
ENV PATH=${NGINX_PATH}:$PATH

WORKDIR ${NGINX_PATH}

RUN useradd -r -s /bin/false www

COPY --from=build-nginx /usr/local/lib /usr/local/lib
COPY --from=build-nginx /opt/nginx /opt/nginx
COPY --from=build-nginx ${NGINX_PATH}/nginx .

RUN mkdir  ../logs && mkdir ../conf

COPY nginx.conf ../conf/.

RUN chmod +x nginx

CMD ["nginx", "-g", "daemon off;"]
