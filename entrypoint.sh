#!/bin/bash +e
# catch signals as PID 1 in a container

# SIGNAL-handler
term_handler() {
 
  if [ -f /etc/init.d/codesyscontrol ]
  then
    echo "terminating CODESYS ..."
    /etc/init.d/codesyscontrol stop
  fi
  
  echo "terminating ssh ..."
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

# run applications in the background
echo "starting ssh ..."
/etc/init.d/ssh start &

if [ -f /etc/init.d/codesyscontrol ]
then
echo "starting CODESYS ..."
/etc/init.d/codesyscontrol start &
fi

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
