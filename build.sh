#!/bin/bash
set -e

ROOT_DIR="/opt/nginx"
VERSION="release"
USING_SYS_LIB=0

echo "Usage: $0 [-v debug] (开启debug) [-p $ROOT_DIR] (指定安装运行根目录 默认: $ROOT_DIR) [-s] (依赖库openssl/zlib/pcre使用系统库)"

while getopts "v:p:sh" opt; do
    case $opt in
        v)
            VERSION="$OPTARG"
            ;;
        p)
            ROOT_DIR="$OPTARG"
            ;;
        s)
            USING_SYS_LIB=1
            ;;
	h)
            exit 0
	    ;;
    esac
done

PCRE_DIR="deps/pcre-8.39"
ZLIB_DIR="deps/zlib-1.2.11"
OPENSSL_DIR="deps/openssl-OpenSSL_1_1_0i"

if [ $USING_SYS_LIB -eq 0 ]; then
    if [ ! -d $PCRE_DIR ]; then
        tar zxf $PCRE_DIR.tar.gz -C deps/
    fi
    if [ ! -d $ZLIB_DIR ]; then
        tar zxf $ZLIB_DIR.tar.gz -C deps/
    fi
    if [ ! -d $OPENSSL_DIR ]; then
        tar zxf $OPENSSL_DIR.tar.gz -C deps/
    fi
fi

config="./auto/configure"
config="$config --prefix=$ROOT_DIR"
config="$config --with-file-aio"
config="$config --with-threads"
config="$config --with-http_slice_module"
config="$config --with-http_v2_module"
config="$config --with-http_ssl_module"
config="$config --add-module=./modules/nginx-live-module"
config="$config --add-module=./modules/ngx_req_status"
if [ $USING_SYS_LIB -eq 0 ]; then
    config="$config --with-pcre=$PCRE_DIR"
    config="$config --with-zlib=$ZLIB_DIR"
    config="$config --with-openssl=$OPENSSL_DIR"
fi

if [ "$VERSION" == "debug" ]; then
    config="$config --with-debug"
    config="$config --with-cc-opt=-O0"
fi
echo "$config"

${config}

make -j8 && make install
