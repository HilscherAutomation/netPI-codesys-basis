#!/bin/bash +e

#check if container is running in host mode
if [[ -z `grep "docker0" /proc/net/dev` ]]; then
  echo "Container not running in host mode. Sure you configured host network mode? Container stopped."
  exit 143
fi

#check if container is running in privileged mode
ip link add dummy0 type dummy >/dev/null 2>&1
if [[ -z `grep "dummy0" /proc/net/dev` ]]; then
  echo "Container not running in privileged mode. Sure you configured privileged mode? Container stopped."
  exit 143
else
  # clean the dummy0 link
  ip link delete dummy0 >/dev/null 2>&1
fi

if [[ ! -e "/dev/vcio" ]]; then
  #reset BCM chip possible
  echo "Container access to VideCore GPU not possible. Device /dev/vcio/ is not mapped. Container stopped."
  exit 143
fi

# catch signals as PID 1 in a container

# SIGNAL-handler
term_handler() {
 
  if [ -f /etc/init.d/edgegateway ]
  then
    echo "Terminating CODESYS Edge Gateway ..."
    /etc/init.d/codesysedge stop
  fi

  if [ -f /etc/init.d/codesyscontrol ]
  then
    echo "Terminating CODESYS Runtime ..."
    /etc/init.d/codesyscontrol stop
  fi

  
  echo "Terminating ssh ..."
  /etc/init.d/ssh stop

  exit 143; # 128 + 15 -- SIGTERM
}

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP

#resolve HOST just in case
if ! ( grep -q "127.0.0.1 localhost localhost.localdomain ${HOSTNAME}" /etc/hosts > /dev/null);
then
  echo "127.0.0.1 localhost localhost.localdomain ${HOSTNAME}" >> /etc/hosts
fi

#check presence of device spi0.0 and net device register
if [[ -e "/dev/spidev0.0" ]]&& [[ -e "/dev/net/tun" ]]; then

  echo "cifx0 hardware support (TCP/IP over RTE LAN ports) configured." 

  # create netx "cifx0" ethernet network interface 
  /opt/cifx/cifx0daemon

  #interface needs a little time to start
  sleep 5

  # bring interface up first of all
  ip link set cifx0 up

  # ip address configured as environment variable?
  if [ -z "$IP_ADDRESS" ]
  then
    echo "No cifx0 IP address configured as environment variable $IP_ADDRESS. Falling back to 192.168.253.1"
    # set alternative
    IP_ADDRESS="192.168.253.1"
  fi

  # subnet mask configured as environment variable?
  if [ -z "${SUBNET_MASK}" ]
  then
    echo "No cifx0 subnet mask configured as environment variable $SUBNET_MASK. Falling back to 255.255.255.0"
   # set alternative
    SUBNET_MASK="255.255.255.0"
  fi

  if [ "$IP_ADDRESS" == "dhcp" ]
  then
    echo "cifx0 configured to dhcp"
    # set dhcp mode
    dhclient cifx0
  else
    #split given parameters in factors
    IFS=. read -r i1 i2 i3 i4 <<< "$IP_ADDRESS"
    IFS=. read -r m1 m2 m3 m4 <<< "$SUBNET_MASK"

    #calculate the broadcast address
    BROADCAST=$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$((i4 & m4 | 255-m4))

    # set ip address and subnet mask
    ip addr add $IP_ADDRESS/$SUBNET_MASK broadcast $BROADCAST dev cifx0

    echo "cifx0 ip address/subnet mask set to" $IP_ADDRESS"/"$SUBNET_MASK
  
    #is a gateway set?
    if [ -n "${GATEWAY}" ]
    then
      echo "gateway set to" $GATEWAY
    
      # flush default routes
      ip route flush dev cifx0
    
      # make gateway known
      ip route add $GATEWAY dev cifx0
  
      # set route via gateway
      NETWORK=$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))
      ip route add $NETWORK/$SUBNET_MASK via $GATEWAY src $IP_ADDRESS dev cifx0
    else 
      echo "No cifx0 gateway address configured as environment variable $GATEWAY"
    fi
  fi
else
  echo "cifx0 hardware support (TCP/IP over RTE LAN ports) not configured." 
fi

# run applications in the background
echo "starting ssh ..."
/etc/init.d/ssh start &

if [ -f /etc/init.d/codesyscontrol ]
then
  echo "Starting CODESYS Runtime ..."
  /etc/init.d/codesyscontrol start &
else
  echo "CODESYS runtime not installed. Download from here https://store.codesys.com/codesys-control-for-raspberry-pi-sl.html and install via CODESYS Development System."
fi

if [ -f /etc/init.d/codesysedge ]
then
  echo "Starting CODESYS Edge Gateway ..."
  /etc/init.d/codesysedge start >/dev/null &
else
  echo "CODESYS Edge Gateway not installed. Download from here https://store.codesys.com/codesys-edge-gateway.html and install via CODESYS Development System."
fi

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
