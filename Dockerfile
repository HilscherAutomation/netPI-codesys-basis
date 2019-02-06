#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:stretch

#dynamic build arguments coming from the /hook/build file
ARG BUILD_DATE
ARG VCS_REF

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/HilscherAutomation/netPI-codesys-basis" \
      org.label-schema.vcs-ref=$VCS_REF

#enable building ARM container on x86 machinery on the web (comment out next line if built on Raspberry)
RUN [ "cross-build-start" ]

#version
ENV HILSCHERNETPI_CODESYS_BASIS_VERSION 1.0.1

#execute all commands as root
USER root

#labeling
LABEL maintainer="netpi@hilscher.com" \
      version=$HILSCHERNETPI_CODESYS_BASIS_VERSION \
      description="CODESYS Control"

#environment variables
ENV USER=pi
ENV PASSWD=raspberry

#install ssh, create user "pi" and make him sudo
RUN apt-get update  \
    && apt-get install -y openssh-server net-tools psmisc \
    && mkdir /var/run/sshd \
    && useradd --create-home --shell /bin/bash pi \
    && echo $USER:$PASSWD | chpasswd \
    && adduser $USER sudo \
    && echo $USER " ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_pi-nopasswd \
    && touch /usr/bin/modprobe \
    && chmod +x /usr/bin/modprobe \
    && mkdir /etc/modprobe.d \
    && touch /etc/modprobe.d/blacklist.conf \
    && touch /etc/modules \
    && apt-get -yqq autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

#do ports
EXPOSE 22 1217

#do entrypoint
COPY "entrypoint.sh" /
ENTRYPOINT ["/entrypoint.sh"]

#set STOPSGINAL
STOPSIGNAL SIGTERM

#stop processing ARM emulation (comment out next line if built on Raspberry)
RUN [ "cross-build-end" ]
