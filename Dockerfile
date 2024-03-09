## Dockerfile
FROM ubuntu:24.04

LABEL maintainer "29ygq@sina.com"

# /var/fdfs 存的是client上传的数据 /opt/fdfs 好像没什么用
ENV FASTDFS_PATH=/opt/fdfs \
  FASTDFS_BASE_PATH=/var/fdfs \
  LIBFASTCOMMON_VERSION="V1.0.72" \
  LIBSERVERFRAME_VERSION="V1.2.2" \
  FASTDFS_NGINX_MODULE_VERSION="V1.24" \
  FASTDFS_VERSION="V6.12.0" \
  FREENGINX_VERSION="1.25.4" \
  TENGINE_VERSION="3.1.0" \
  PORT= \
  GROUP_NAME= \
  TRACKER_SERVER= \
  CUSTOM_CONFIG="false"

# get all the dependences
RUN  set -x; buildDeps='git gcc make wget libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev' \
  && apt-get update \
  && apt-get install -y ${buildDeps}\
  && rm -rf /var/lib/apt/lists/*

# create the dirs to store the files downloaded from internet
RUN mkdir -p ${FASTDFS_PATH}/libfastcommon \
  && mkdir -p ${FASTDFS_PATH}/fastdfs \
  && mkdir -p ${FASTDFS_PATH}/fastdfs-nginx-module \
  && mkdir ${FASTDFS_BASE_PATH} \
  && mkdir -p /usr/local/nginx/conf/conf.d

WORKDIR ${FASTDFS_PATH}

## compile the libfastcommon
RUN git clone -b $LIBFASTCOMMON_VERSION https://github.com/happyfish100/libfastcommon.git libfastcommon \
  && cd libfastcommon \
  && ./make.sh \
  && ./make.sh install \
  && cd .. \
  && rm -rf ${FASTDFS_PATH}/libfastcommon \
## compile the libserverframe
  && git clone -b $LIBSERVERFRAME_VERSION https://github.com/happyfish100/libserverframe.git libserverframe \
  && cd libserverframe \
  && ./make.sh \
  && ./make.sh install \
  && cd .. \
  && rm -rf ${FASTDFS_PATH}/libserverframe \
## compile the fastdfs
  && git clone -b $FASTDFS_VERSION https://github.com/happyfish100/fastdfs.git fastdfs \
  && cd fastdfs \
  && ./make.sh \
  && ./make.sh install \
  && cd .. \
  && rm -rf ${FASTDFS_PATH}/fastdfs \
# user  image hosting service 
  && useradd -m -s /bin/bash ihService 

## compile nginx
# nginx url: https://freenginx.org/download/freenginx-${NGINX_VERSION}.tar.gz
# tengine url: http://tengine.taobao.org/download/tengine-${TENGINE_VERSION}.tar.gz
RUN git clone -b $FASTDFS_NGINX_MODULE_VERSION https://github.com/happyfish100/fastdfs-nginx-module.git fastdfs-nginx-module \
  && wget https://freenginx.org/download/freenginx-${FREENGINX_VERSION}.tar.gz \
  && tar -zxf freenginx-${FREENGINX_VERSION}.tar.gz \
  && cd freenginx-${FREENGINX_VERSION} \
  && ./configure --prefix=/usr/local/nginx \
      --user=ihService \
      --add-module=${FASTDFS_PATH}/fastdfs-nginx-module/src/ \
      --with-stream=dynamic \
  && make \
  && make install \
  && cd .. \
  && ln -s /usr/local/nginx/sbin/nginx /usr/bin/ \
  && rm -rf ${FASTDFS_PATH}/freenginx-* \
  && rm -rf ${FASTDFS_PATH}/fastdfs-nginx-module \
  # purge all the dependent software
  && apt purge -y --auto-remove ${buildDeps}

EXPOSE 22122 23000 8080 8888 80
VOLUME ["$FASTDFS_BASE_PATH","/etc/fdfs","/usr/local/nginx/conf/conf.d"]

COPY conf/*.* /etc/fdfs/
# COPY nginx_conf/ /nginx_conf/
COPY nginx_conf/nginx.conf /usr/local/nginx/conf/
COPY entrypoint.sh /

RUN chmod a+x /entrypoint.sh

WORKDIR ${FASTDFS_PATH}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tracker"]
