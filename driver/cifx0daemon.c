/*
#
# MIT License
#
# Copyright (c) 2017 Hilscher Systemautomation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
*/

/*************************************************************************************************/
/* cifx0daemon creates a network interface named 'cifx0' from netPI's netx controller.           */
/*                                                                                               */
/* Phyiscally this interface sends/receives data through the switched two-ported netx RJ45 ports */
/*                                                                                               */
/* Treat the interface in the same manner as interface such as 'eth0', 'wan0' etc.               */ 
/*************************************************************************************************/


#include "cifxlinux.h"
#include "cifXEndianess.h"
#include "rcX_Public.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <string.h>

#include <signal.h>
#include <semaphore.h>

#define CIFX_DEV "cifX0"
#define NL_MAX_PAYLOAD 8192
#define MAX_WAIT_FOR_CIFX0_IN_SEC 30

CIFXHANDLE hDriver = NULL;
CIFXHANDLE hSysdevice = NULL;
SYSTEM_CHANNEL_SYSTEM_INFO_BLOCK tSystemInfoBlock;


/*****************************************************************************/
/*! Main entry function
*   \return 0                                                                */
/*****************************************************************************/
int main(int argc, char* argv[])
{
  int err;

  // fork the process
  pid_t pid = fork();

  if( pid == 0 ) { // child process 

    // starting the netx "cifx0" network interface

    // sempahore needed to sync signal events of child process
    static sem_t sem;

    // handler called on exceptional signals
    void semhandler(int sig) {
      // unlock semaphore
      sem_post(&sem);
    }

    struct CIFX_LINUX_INIT init =
    {
      .init_options        = CIFX_DRIVER_INIT_AUTOSCAN,
      .iCardNumber         = 0,
      .fEnableCardLocking  = 0,
      .base_dir            = NULL,
      .poll_interval       = 0,
      .poll_StackSize      = 0,
      .trace_level         = 255,
      .user_card_cnt       = 0,
      .user_cards          = NULL,
    };

    // initialize semaphore and lock it by default
    sem_init(&sem,0,0);

    // define signals that could kill the process
    signal(SIGKILL, semhandler);
    signal(SIGTERM, semhandler);
    signal(SIGINT,  semhandler);
    signal(SIGQUIT, semhandler);

    int32_t lRet = cifXDriverInit(&init);

    if(CIFX_NO_ERROR == lRet) {

      // driver sucessfully initialized

      lRet  = xDriverOpen(&hDriver);

      if(CIFX_NO_ERROR == lRet) {

        // driver successfully opened, SPI bus and netX found
  
        lRet = xSysdeviceOpen(hDriver, CIFX_DEV ,&hSysdevice);

        // System channel successfully opened

        if(CIFX_NO_ERROR == lRet) {

          // query system information block

          if( CIFX_NO_ERROR == (lRet = xSysdeviceInfo(hSysdevice, CIFX_INFO_CMD_SYSTEM_INFO_BLOCK, sizeof(SYSTEM_CHANNEL_SYSTEM_INFO_BLOCK), &tSystemInfoBlock ))) {

            if( (long unsigned int)tSystemInfoBlock.ulDeviceNumber / 100 == 76601) {

              // netPI device detected, suspend until signal

              sem_wait(&sem);

            }

          }

          // close the system channel

          xSysdeviceClose(hSysdevice);

        }

        // close the driver

        xDriverClose(hDriver);

      }

    }

    cifXDriverDeinit();

    sem_destroy(&sem);

    exit(0);

  } else { // parent process 

    // listing to kernel events via netlink socket to wait for "cifx0" network interface been created

    int nl_socket;
    struct sockaddr_nl src_addr;
    char msg[NL_MAX_PAYLOAD];
    int32_t lRet;
    char eventstr[] = "add@/devices/virtual/net/cifx0";
    int timeout = 0;

    // handler called on alarm
    void alrmhandler(int sig) {
      timeout = 1;
    }

    memset(&src_addr, 0, sizeof(src_addr));
    src_addr.nl_family = AF_NETLINK;
    src_addr.nl_pid = getpid();
    src_addr.nl_groups = -1;

    nl_socket = socket(AF_NETLINK, (SOCK_DGRAM | SOCK_CLOEXEC), NETLINK_KOBJECT_UEVENT);
    if (nl_socket < 0) {
        printf("Failed to create socket for DeviceFinder");
        exit(1);
    }

    lRet = bind(nl_socket, (struct sockaddr*) &src_addr, sizeof(src_addr));
    if (lRet) {
        printf("Failed to bind netlink socket..");
        close(nl_socket);
        return 1;
    }

    printf("Waiting for added 'cifx0' network interface ... \n");

    // define alarm signal and handler
    signal(SIGALRM, alrmhandler);

    // wait for max tim to "cifx0" becoming ready
    alarm(MAX_WAIT_FOR_CIFX0_IN_SEC);

    while (1) {

        if( timeout ) {

          // alarm timeout received

          printf("'cifx0' network interface not ready in time\n");

          // kill child process also
          kill( pid, SIGTERM);

          break;
        }

        int r = recv(nl_socket, msg, sizeof(msg), MSG_DONTWAIT);

        if (r == -1) // nothing
            continue;

        if (r < 0) { // error 
            continue;
        }

        if( memcmp((const void*)&msg,(const void*)&eventstr,sizeof(eventstr)) == 0) {

          // event matches, interface is ready

          printf("'cifx0' network interface is now ready\n");

          break;
        }

    }
  
    exit(0);

  }
}

