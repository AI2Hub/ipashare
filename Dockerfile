FROM golang:1.16 AS builder-server
COPY server/. /root/togettoyou/
WORKDIR /root/togettoyou/
RUN make

FROM node:16.17.1-alpine AS builder-web
WORKDIR /app
COPY web/package*.json ./
RUN yarn install
COPY web/. .
RUN yarn run build:prod

FROM togettoyou/zsign:latest AS zsign

FROM centos:7
WORKDIR /root/togettoyou/
COPY --from=builder-server /root/togettoyou/ipashare ./
COPY --from=builder-server /root/togettoyou/conf/ ./conf/
COPY --from=builder-web /app/dist/ ./dist/
COPY --from=zsign /zsign/zsign /bin/zsign
RUN sed -i 's|mirrorlist=http://mirrorlist.centos.org|#mirrorlist=http://mirrorlist.centos.org|' /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://mirrors.aliyun.com|' /etc/yum.repos.d/CentOS-Base.repo && \
    yum clean all && \
    yum makecache
RUN yum install -y openssl openssl-devel unzip zip
ENTRYPOINT ["./ipashare"]
