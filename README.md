## CODESYS Control

Made for Raspberry Pi 3B architecture based devices and compatibles

### Docker repository

https://hub.docker.com/r/hilschernetpi/netpi-codesys-basis/

### Container features

The image provided hereunder deploys a container with a basic setup of Linux tools, utilities and default user `pi` as needed for a flawless installation of the CODESYS Control for Raspberry Pi (SL and MC SL) packages with the Windows® based [CODESYS Development System V3](https://store.codesys.com/codesys.html)(free).

Base of this image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with enabled [SSH](https://en.wikipedia.org/wiki/Secure_Shell) and created default user 'pi'(sudo). This setup is equivalent to a stripped down Raspbian OS with least capabilities.

Once the container is deployed it needs an upgrade with the following packages you can download from the CODESYS store

* [CODESYS Control for Raspberry Pi SL](https://store.codesys.com/codesys-control-for-raspberry-pi-sl.html) or [CODESYS Control for Raspberry Pi MC SL](https://store.codesys.com/codesys-control-for-raspberry-pi-mc-sl.html)
* [CODESYS Edge Gateway](https://store.codesys.com/codesys-edge-gateway.html) (needed at later versions of CODESYS runtime)

### Container hosts

The container has been successfully tested on the following Docker hosts

* netPI, model RTE 3, product name NIOT-E-NPI3-51-EN-RE
* netPI, model CORE 3, product name NIOT-E-NPI3-EN
* netIOT Connect, product name NIOT-E-TPI51-EN-RE
* netFIELD Connect, product name NIOT-E-TPI51-EN-RE/NFLD
* Raspberry Pi, model 3B

netPI devices specifically feature a restricted Docker protecting the Docker host system software's integrity by maximum. The restrictions are

* privileged mode is not automatically adding all host devices `/dev/` to a container
* volume bind mounts to rootfs is not supported
* the devices `/dev`,`/dev/mem`,`/dev/sd*`,`/dev/dm*`,`/dev/mapper`,`/dev/mmcblk*` cannot be added to a container

### Container licensing

If not licensed the "CODESYS Control for Raspberry Pi" SoftPLC runtime operates 1 hour and then stops. A [Licensing](https://www.codesys.com/the-system/licensing.html) is needed to make it run an unlimited time.

A license purchase follows an email with a ticket number (e.g A78HY-TBVMD-8SVC7-P8BHX-4LED6) granting you the license. The `Tools->License Manager` in the CODESYS Development System (internet needed) transforms the ticket number in a deployed license. The ticket number can be used only one time and gets invalid during the licensing procedure.

It is possible to deploy a license to either a CODESYS Runtime Key (USB dongle) or to a software container. 

**IMPORTANT NOTE**: A software container needs special care cause the license is stored in container. If this container is lost or destroyed by any reason or is deleted your license copy is **gone forever!!!**. This is why a license backup is obligatory in this case.

To backup the license file "3SLicenseInfo.tar" follow this [FAQ information](https://forum.codesys.com/viewtopic.php?f=22&t=5641&start=15#p10689).
To restore the license file "3SLicenseInfo.tar" follow this [FAQ information](https://forum.codesys.com/viewtopic.php?f=22&t=5641&p=10690#p10690).

### Container setup

#### Environment variable (optional)

The container binds the SSH server port to `22` by default.

For an alternative port use the variable **SSHPORT** with the desired port number as value.

#### Host network

The container needs to run in `host` network mode.

Using this mode makes port mapping unnecessary since all the used container ports (like 22) are exposed to the host automatically.

#### Privileged mode

The privileged mode option needs to be activated to lift the standard Docker enforced container limitations. With this setting the container and the applications inside are the getting (almost) all capabilities as if running on the Host directly

#### Host devices

The CODESYS runtime perfoms a license check across the Docker host VideoCore GPU when started. To grant access to the GPU chip the `/dev/vcio` Docker host device is mandatory to add to the container.

In case an external USB CODESYS Runtime Key Dongle is used for licensing the Docker host device `/dev/hidraw0` needs to be added to the container. The device `/dev/hidraw0` is only available on the Docker host if such a USB dongle physically has been connected to one of the USB sockets.

##### Additional Ethernet ports on netPI RTE 3 or netFIELD/netIOT connect (optional)

The container configures the double RJ45 socket driven by netX controller to operate as standard LAN interface (single MAC address, switched always) with a device name `cifx0` if the following devices found added to the container

* Docker host device `/dev/spidev0.0` granting access to the network controller netX driving the RTE ports
* Docker host device `/dev/net/tun` granting access to network interface registering logic

Cause the container runs in `host` network mode the interface is instantiated on the Docker host as a standard LAN interface. This is why the `cifx0` IP settings have to be configured in the Docker host's web UI network setup dialog (as "eth0" interface) and not in the container. Any change on the IP settings needs a container restart to accept the new IP parameters.

The netX controller was designed to support all kind of Industrial Networks as device in the first place. Its performance is high when exchanging IO data with a network master across IO buffers. It was not designed to support high performance message oriented exchange of data as used in Ethernet communications. This is why the provided `cifx0` interface is a low to mid-range performer but is still a good compromise if another Ethernet interface is needed.

Measurements have shown that around 700 to 800KByte/s throughput can be reached across `cifx0` only whereas with netPI's primary Ethernet port `eth0` 10MByte/s can be reached. The reasons are:

* 25MHz SPI clock frequency between netX and Raspberry Pi CPU only
* User space driver instead of a kernel driver
* 8 messages deep message receive queue only for incoming Ethernet frames
* SPI handshake protocol with additional overhead between netX and Raspberry Pi during message based communications

The `cifx0` LAN interface will drop Ethernet frames in case its message queue is being overun at high LAN network traffic. The TCP/IP network protocol embeds a recovery procedure for packet loss due to retransmissions. This is why you usually do not recognize a problem when this happens. Single frame communications using non TCP/IP based traffic like the ping command may recognize lost frames.

The `cifx0` LAN interface DOES NOT support Ethernet package reception of type multicast.

### Container deployment

Pulling the image may take 10 minutes.

#### netPI example

STEP 1. Open netPI's web UI in your browser (https).

STEP 2. Click the Docker tile to open the [Portainer.io](http://portainer.io/) Docker management user interface.

STEP 3. Enter the following parameters under *Containers > + Add Container*

Parameter | Value | Remark
:---------|:------ |:------
*Image* | **hilschernetpi/netpi-codesys-basis** | a :tag may be added as well
*Network > Network* | **host** |
*Restart policy* | **always** |
*Adv.con.set. > Env > +add env.var.* | *name* **SSHPORT** -> *value* **any number value** | optional for different SSH port
*Adv.con.set. > Devices > +add device* | *Host path* **/dev/vcio** -> *Container path* **/dev/vcio** |
*Adv.con.set. > Devices > +add device* | *Host path* **/dev/hidraw0** -> *Container path* **/dev/hidraw0** | for CODESYS Runtime Key Dongle
*Adv.con.set. > Devices > +add device* | *Host path* **/dev/spidev0.0** -> *Container path* **/dev/spidev0.0** | for `cifx0` LAN
*Adv.con.set. > Devices > +add device* | *Host path* **/dev/net/tun** -> *Container path* **/dev/net/tun** | for `cifx0` LAN
*Adv.con.set. > Privileged mode* | **On** |

STEP 4. Press the button *Actions > Start/Deploy container*

#### Docker command line example

`docker run -d --privileged --network=host --restart=always -e SSHPORT=22 --device=/dev/vcio0:/dev/vcio --device=/dev/hidraw0:/dev/hidraw0 --device=/dev/spidev0.0:/dev/spidev0.0 --device=/dev/net/tun:/dev/net-tun -p 22:22/tcp hilschernetpi/netpi-codesys-basis`

#### Docker compose example

A `docker-compose.yml` file could look like this

    version: "2"

    services:
     nodered:
       image: hilschernetpi/netpi-codesys-basis
       restart: always
       privileged: true
       network_mode: host
       ports:
         - 22:22
       devices:
         - "/dev/vcio:/dev/vcio"
         - "/dev/hidraw0:/dev/hidraw0"
         - "/dev/spidev0.0:/dev/spidev0.0"
         - "/dev/net/tun:/dev/net/tun"
       environment:
         - SSHPORT=22

### Container access

The container starts the SSH server automatically when deployed. 

For an SSH terminal session as used by the CODESYS development system to communicate with a target hardware use the Docker host IP address with the port number `22` or the configured **SSHPORT**.

A fresh container can immediately be upgraded with your downloaded packages from the CODESYS store. Here is how to proceed

STEP 1: Upgrade your Windows CODESYS development system first with support for Raspberry Pi/Linux compatible platforms using the function `Tools->Package Manager->Install`. Choose your packages "CODESYS Control for Raspberry Pi 3.5.xx.xx.package" and "CODESYS Edge Gateway for Linux 3.5.x.x.package" and click `Install`.

STEP 2: Restart the development system to activate the installed packages extending the top menu bar `Tools` by two new functions.

STEP 3: Use the new function `Tools->Update Raspberry Pi` to deploy your "CODESYS Control for Raspberry Pi" package to the container. Enter the user `pi` and the password `raspberry` as `Login credentials`. Enter your Docker host IP address in `Select target->IP address` with the :port as extension , choose the version under `Package` you want to install and press `Install`. The installation may take up to 1 minute. Choose `Standard` or `Multicore` runtime mode during installation.

STEP 4: Use the new function `Tools->Update Edge Gateway` to deploy your "CODESYS Edge Gateway for Linux" package to the container. Enter the user `pi` and the password `raspberry` as `Login credentials`. Enter your Dcoker host IP address in `Select target->IP address` with the :port as extension, choose the version `V3.5.x.x.(armhf)` under `Package` you want to install and press `Install`. The installation may take up to 1 minute. The container is now well prepared and ready to receive a project.

STEP 5: Create a CODESYS new project. Choose `Standard Project` and as `Device` "CODESYS Control for Raspberry Pi xx" and then `ok`. After project creation double click the topmost `Device(CODESYS Control for Raspberry Pi)` in the project tree.

STEP 6: Setup a communication from the CODESYS development system to the container Edge Gateway. Use the function `Gateway->Add New Gateway` in the dialog `Device`. As gateway `IP-address` use the Docker host IP address at port 1217 and click `ok`. Use the option `Device->Scan Network...` option and click the found device found. e.g. NTB827EBEA02D0 [0000.0539] and `ok`.

### Container test

The container has been successfully tested against the [CODESYS Development System V3](https://store.codesys.com/codesys.html) in the version V3.5.15.40(64Bit) and the [CODESYS Control for Raspberry Pi SL](https://store.codesys.com/codesys-control-for-raspberry-pi-sl.html) and [CODESYS Control for Raspberry Pi MC SL](https://store.codesys.com/codesys-control-for-raspberry-pi-mc-sl.html) both in the version V3.5.16.0

### License

Copyright (c) Hilscher Gesellschaft fuer Systemautomation mbH. All rights reserved.
Licensed under the LISENSE.txt file information stored in the project's source code repository.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com
