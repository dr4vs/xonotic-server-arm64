FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV XONOTIC_DOWNLOAD_URL=http://dl.xonotic.org/xonotic-0.8.6.zip

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl unzip build-essential automake libtool libgmp-dev libjpeg-dev zlib1g-dev pkg-config && \
    mkdir -p /opt && \
    curl -sSL "$XONOTIC_DOWNLOAD_URL" -o /opt/xonotic.zip && \
    unzip /opt/xonotic.zip -d /opt && \
    cp /opt/Xonotic/server/server.cfg /opt/Xonotic/data/ && \
    cd /opt/Xonotic && make server

RUN cd /opt/Xonotic && \
    rm -rf source bin64 bin32 Xonotic.app \
           xonotic-linux64-sdl xonotic-linux64-glx xonotic-linux64-dedicated \
           xonotic.exe xonotic-x86.exe xonotic-wgl.exe xonotic-x86-wgl.exe \
           xonotic-dedicated.exe xonotic-x86-dedicated.exe xonotic-osx-dedicated \
           xonotic-linux-sdl.sh xonotic-linux-glx.sh xonotic-linux-dedicated.sh && \
    rm -f /opt/xonotic.zip

FROM ubuntu:24.04

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y libstdc++6 libgmp10 libpng16-16 libjpeg-turbo8 zlib1g curl netcat-openbsd && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /opt/Xonotic /opt/Xonotic

RUN groupadd -r xonotic && \
    useradd -r -g xonotic -d /opt/Xonotic -s /sbin/nologin xonotic && \
    chown -R xonotic:xonotic /opt/Xonotic

WORKDIR /opt/Xonotic

USER xonotic

EXPOSE 26000/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD nc -z -u 127.0.0.1 26000 || exit 1

CMD ["/opt/Xonotic/xonotic-local-dedicated", "+serverconfig", "server.cfg"]
