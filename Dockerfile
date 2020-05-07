#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:buster-20191223

#dynamic build arguments coming from the /hook/build file
ARG BUILD_DATE
ARG VCS_REF

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/HilscherAutomation/netPI-codesys-basis" \
      org.label-schema.vcs-ref=$VCS_REF

#version
ENV HILSCHERNETPI_CODESYS_BASIS_VERSION 1.3.4

#execute all commands as root
USER root

#labeling
LABEL maintainer="netpi@hilscher.com" \
      version=$HILSCHERNETPI_CODESYS_BASIS_VERSION \
      description="CODESYS Control"

#environment variables
ENV USER=pi
ENV PASSWD=raspberry

COPY "./driver/*" "./driver/includes/" "./firmware/*" /tmp/

#install ssh, create user "pi" and make him sudo
RUN apt-get update  \
    && apt-get install -y openssh-server net-tools psmisc build-essential ifupdown isc-dhcp-client \
    && mkdir /var/run/sshd \
    && useradd --create-home --shell /bin/bash pi \
    && echo $USER:$PASSWD | chpasswd \
    && adduser $USER sudo \
    && echo $USER " ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_pi-nopasswd \
# create some necessary files for CODESYS
    && touch /usr/bin/modprobe \
    && chmod +x /usr/bin/modprobe \
    && mkdir /etc/modprobe.d \
    && touch /etc/modprobe.d/blacklist.conf \
    && touch /etc/modules \
#install netX driver and netX ethernet supporting firmware
    && dpkg -i /tmp/netx-docker-pi-drv-2.0.1-r0.deb \
    && dpkg -i /tmp/netx-docker-pi-pns-eth-3.12.0.8.deb \
#compile netX network daemon that creates the cifx0 ethernet interface
    && echo "Irq=/sys/class/gpio/gpio24/value" >> /opt/cifx/plugins/netx-spm/config0 \
    && cp /tmp/*.h /usr/include/cifx \
    && cp /tmp/cifx0daemon.c /opt/cifx/cifx0daemon.c \
    && gcc /opt/cifx/cifx0daemon.c -o /opt/cifx/cifx0daemon -I/usr/include/cifx -Iincludes/ -lcifx -pthread \
#clean up
    && rm -rf /tmp/* \
    && apt-get remove build-essential \
    && apt-get -yqq autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

#do ports
EXPOSE 22 1217

#do entrypoint
COPY "./init.d/*" /etc/init.d/ 
ENTRYPOINT ["/etc/init.d/entrypoint.sh"]

#set STOPSGINAL
STOPSIGNAL SIGTERM

