## CODESYS Control

[![](https://images.microbadger.com/badges/image/hilschernetpi/netpi-codesys-basis.svg)](https://microbadger.com/images/hilschernetpi/netpi-codesys-basis "CODESYS Control")
[![](https://images.microbadger.com/badges/commit/hilschernetpi/netpi-codesys-basis.svg)](https://microbadger.com/images/hilschernetpi/netpi-codesys-basis "CODESYS Control")
[![Docker Registry](https://img.shields.io/docker/pulls/hilschernetpi/netpi-codesys-basis.svg)](https://registry.hub.docker.com/u/hilschernetpi/netpi-codesys-basis/)&nbsp;
[![Image last updated](https://img.shields.io/badge/dynamic/json.svg?url=https://api.microbadger.com/v1/images/hilschernetpi/netpi-codesys-basis&label=Image%20last%20updated&query=$.LastUpdated&colorB=007ec6)](http://microbadger.com/images/hilschernetpi/netpi-codesys-basis "Image last updated")&nbsp;

Made for [netPI](https://www.netiot.com/netpi/), the Raspberry Pi 3B Architecture based industrial suited Open Edge Connectivity Ecosystem

### Secured netPI Docker

netPI features a restricted Docker protecting the system software's integrity by maximum. The restrictions are 

* privileged mode is not automatically adding all host devices `/dev/` to a container
* volume bind mounts to rootfs is not supported
* the devices `/dev`,`/dev/mem`,`/dev/sd*`,`/dev/dm*`,`/dev/mapper`,`/dev/mmcblk*` cannot be added to a container

### Container features

The image provided hereunder deploys a container with a basic setup of Linux tools, utilities and default user needed for a flawless installation of the CODESYS Control for Raspberry Pi (SL and MC SL) packages with the Windows® based [CODESYS Development System V3](https://store.codesys.com/codesys.html)(free).

Base of this image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with enabled [SSH](https://en.wikipedia.org/wiki/Secure_Shell) and created default user 'pi'(sudo). This setup is equivalent to a stripped down Raspbian OS with least capabilities.

Once the container is deployed it needs an upgrade with the following packages you can download from the CODESYS store

* [CODESYS Control for Raspberry Pi SL](https://store.codesys.com/codesys-control-for-raspberry-pi-sl.html) or [CODESYS Control for Raspberry Pi MC SL](https://store.codesys.com/codesys-control-for-raspberry-pi-mc-sl.html)
* [CODESYS Edge Gateway](https://store.codesys.com/codesys-edge-gateway.html) (needed since version V3.5.15.x)

### Container licensing

If not licensed the "CODESYS Control for Raspberry Pi" SoftPLC runtime operates 1 hour and then stops. A [Licensing](https://www.codesys.com/the-system/licensing.html) is needed to make it run an unlimited time.

A license purchase follows an email with a ticket number (e.g A78HY-TBVMD-8SVC7-P8BHX-4LED6) granting you the license. The `Tools->License Manager` in the CODESYS Development System (internet needed) transforms the ticket number in a deployed license. The ticket number can be used only one time and gets invalid during the licensing procedure.

It is possible to deploy a license to either a CODESYS Runtime Key (USB dongle) or to a software container. 

**IMPORTANT NOTE**: A software container needs special care since the license is stored on the device itself in the Docker container. If this container is lost or destroyed by any reason or is deleted your license copy is **gone forever!!!**. This is why a license backup is obligatory in this case.

To backup the license file "3SLicenseInfo.tar" follow this [FAQ information](https://forum.codesys.com/viewtopic.php?f=22&t=5641&start=15#p10689).
To restore the license file "3SLicenseInfo.tar" follow this [FAQ information](https://forum.codesys.com/viewtopic.php?f=22&t=5641&p=10690#p10690).

### Container setup

#### Host network

The container needs to run in `host` network mode.

Using this mode makes port mapping unnecessary since all the used container ports (like 22) are exposed to the host automatically.

#### Privileged mode

The privileged mode option needs to be activated to lift the standard Docker enforced container limitations. With this setting the container and the applications inside are the getting (almost) all capabilities as if running on the Host directly

#### Host devices

The CODESYS runtime perfoms a license versus serial number check across the device VideoCore GPU when started. To grant access to the GPU chip the `/dev/vcio` host device is mandatory to add to the container.

In case a CODESYS Runtime Key Dongle is used for licensing the host device `/dev/hidraw0` needs to be added to the container. 

On netPI RTE 3 target only (optional):

The container configures the two RJ45 Industrial Ethernet ports (RTE) as standard LAN interface (single MAC address, but switched) named `cifx0` automatically if the following devices found added to the container

* host device `/dev/spidev0.0` granting access to the network controller netX driving the RTE ports
* host device `/dev/net/tun` granting access to network interface registering logic

#### Environment variables (optional)

On netPI RTE 3 target only (optional):

The configuration of the LAN interface `cifx0` is done with the following variables

* IP_ADDRESS with a value in the format `x.x.x.x` e.g. 192.168.0.1 configures the interface IP address. A value `dhcp` instead enables the dhcp mode and the interface waits to receive its IP address through a DCHP server.
* SUBNET_MASK with a value in the format `x.x.x.x` e.g. 255.255.255.0 configures the interface subnet mask. Not necessary to configure in dhcp mode.
* GATEWAY with a value in the format `x.x.x.x` e.g. 192.168.0.10 configures the interface gateway address. A gateway is optional. Not necessary to configure in dhcp mode.

### Container deployment

STEP 1. Open netPI's website in your browser (https).

STEP 2. Click the Docker tile to open the [Portainer.io](http://portainer.io/) Docker management user interface.

STEP 3. Enter the following parameters under *Containers > + Add Container*

Parameter | Value | Remark
:---------|:------ |:------
*Image* | **hilschernetpi/netpi-codesys-basis**
*Network > Network* | **host** |
*Restart policy* | **always** |
*Runtime > Devices > +add device* | *Host path* **/dev/vcio** -> *Container path* **/dev/vcio** |
*Runtime > Devices > +add device* | *Host path* **/dev/hidraw0** -> *Container path* **/dev/hidraw0** | for CODESYS Runtime Key Dongle
*Runtime > Devices > +add device* | *Host path* **/dev/spidev0.0** -> *Container path* **/dev/spidev0.0** | for `cifx0` LAN
*Runtime > Devices > +add device* | *Host path* **/dev/net/tun** -> *Container path* **/dev/net/tun** | for `cifx0` LAN
*Runtime > Env* | *name* **IP_ADDRESS** -> *value* **e.g.192.168.0.1** or **dhcp** | for `cifx0` LAN
*Runtime > Env* | *name* **SUBNET_MASK** -> *value* **e.g.255.255.255.0** | for `cifx0` LAN, no need for `dhcp`
*Runtime > Env* | *name* **GATEWAY** -> *value* **e.g.192.168.0.10** | optional for `cifx0` LAN, no need for `dhcp`
*Runtime > Privileged mode* | **On** |

STEP 4. Press the button *Actions > Start/Deploy container*

Pulling the image may take a while (5-10mins). Sometimes it may take too long and a time out is indicated. In this case repeat STEP 4.

### Container access

A fresh container can immediately be upgraded with your downloaded packages from the CODESYS store. Here is how to proceed

STEP 1: Upgrade your CODESYS development system first with support for Raspberry Pi/Linux compatible platforms using the function `Tools->Package Manager->Install`. Choose your packages "CODESYS Control for Raspberry Pi 3.5.xx.xx.package" and "CODESYS Edge Gateway for Linux 3.5.x.x.package" and click `Install`.

STEP 2: Restart the development system to activate the installed packages extending the top menu bar `Tools` by two new functions.

STEP 3: Use the new function `Tools->Update Raspberry Pi` to deploy your "CODESYS Control for Raspberry Pi" package to the container. Enter the user `pi` and the password `raspberry` as `Login credentials`. Enter your netPI's IP address in `Select target->IP address` , choose the version under `Package` you want to install and press `Install`. The installation may take up to 1 minute. Choose `Standard` or `Multicore` runtime mode during installation.

STEP 4: Use the new function `Tools->Update Edge Gateway` to deploy your "CODESYS Edge Gateway for Linux" package to the container. Enter the user `pi` and the password `raspberry` as `Login credentials`. Enter your netPI's IP address in `Select target->IP address` , choose the version `V3.5.x.x.(armhf)` under `Package` you want to install and press `Install`. The installation may take up to 1 minute. The container is now well prepared and ready to receive a project.

STEP 5: Create a CODESYS new project. Choose `Standard Project` and as `Device` "CODESYS Control for Raspberry Pi xx" and then `ok`. After project creation double click the topmost `Device(CODESYS Control for Raspberry Pi)` in the project tree.

STEP 6: Setup a communication from the CODESYS development system to the container Edge Gateway. Use the function `Gateway->Add New Gateway` in the dialog `Device`. As gateway `IP-address` use the netPI IP address at port 1217 and click `ok`. Use the option `Device->Scan Network...` option and click the found device found. e.g. NTB827EBEA02D0 [0000.0539] and `ok`.

### Container test

The container has been successfully tested against the [CODESYS Development System V3](https://store.codesys.com/codesys.html) in the version V3.5.15.10 and the [CODESYS Control for Raspberry Pi SL](https://store.codesys.com/codesys-control-for-raspberry-pi-sl.html) and [CODESYS Control for Raspberry Pi MC SL](https://store.codesys.com/codesys-control-for-raspberry-pi-mc-sl.html) both in the version V3.5.15.10

### Youtube

HINT: The software version shown in the video may differ from yours and screens/options/windows may look different meanwhile. The video also doesn't show the mapping of the `/dev/vcio` and `/dev/spidev0.0` host devices when the container is deplyed and no installation of the Edge Gateway package.

[![Tutorial](https://img.youtube.com/vi/cXIHu3-4-eg/0.jpg)](https://youtu.be/cXIHu3-4-eg)

### Container automated build

The project complies with the scripting based [Dockerfile](https://docs.docker.com/engine/reference/builder/) method to build the image output file. Using this method is a precondition for an [automated](https://docs.docker.com/docker-hub/builds/) web based build process on DockerHub platform.

DockerHub web platform is x86 CPU based, but an ARM CPU coded output file is needed for Raspberry systems. This is why the Dockerfile includes the [balena.io](https://balena.io/blog/building-arm-containers-on-any-x86-machine-even-dockerhub/) steps.

### License

View the license information for the software in the project. As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com
