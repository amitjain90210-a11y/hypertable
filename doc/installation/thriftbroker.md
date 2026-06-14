# ThriftBroker only

# ThriftBroker only

[Thrift](http://thrift.apache.org/) is a communication framework for building cross-language services. It combines a software stack with a code generation engine that can generate service bindings for all popular high-level languages. Hypertable includes a Thrift service called the ThriftBroker which is the preferred interface to Hypertable. It provides a way for programs written in nearly any language to access a Hypertable database. The ThriftBroker should run locally on all machines running application programs that need access to Hypertable. This document describes how to install the ThriftBroker on an application server machine and configure it to point to a Hypertable cluster or standalone Hypertable instance.

## Table of Contents

### Prerequisites

Before you get started with the installation, there are some general system requirements that need to be satisfied before proceeding. These requirements are described in the following list.

  * **root access** \- If you plan to install the ThriftBroker package in the standard location (`/opt/hypertable`) you will need root access to create and populate that directory. You can either carry out the steps below while logged in as the _root_ user or you need to have sudo priveleges. If you do not have root access, you can install the `.tar.bz2` package anywhere you like.  

  * **firewall** \- The Hypertable processes (including the ThriftBroker) use TCP and UDP to communicate with one another and with client applications. Firewalls can block this traffic and prevent the ThriftBroker from operating properly. Any firewall that blocks traffic between the ThriftBroker and the Hypertable machine(s) should be disabled or the appropriate ports should be opened up to allow Hypertable communication. See [Hypertable Firewall Requirements](../misc/firewall_requirements.md) for instructions on how to do this.  

  * **VERSION** \- This document assumes that the variable $VERSION contains the version number of the ThriftBroker being installed (e.g. 0.9.5.5)

### STEP 1 - Install ThriftBroker Package

The ThriftBroker is installed via binary packages which can be found on the Hypertable [Download](http://hypertable.com/download/) page. For the ThriftBroker installation, choose one of the `thriftbroker-only` packages. The packages come bundled with nearly all of the dependent shared libraries. The nice thing about this approach is that just two packages are required for linux, a 64-bit linux package and a 32-bit linux package. The only requirement is that your system is built with glibc 2.4+ (released on March 6th 2006) which provides stack smashing protection. The ThriftBroker comes with a program launch script, `ht`, that sets up LD_LIBRARY_PATH (or DYLD_LIBRARY_PATH) to point to the `lib/` directory of the installation so that the dependent libraries can be found by the dynamic linker.

To begin the package installation, switch to the directory containing the package file and then issue the command listed below for your operating system.

**Redhat, CentOS, or SUSE Installation**
    
    
    $ sudo rpm -ivh --replacepkgs --nomd5 _package_.rpm

**Debian or Ubuntu Installation**
    
    
    $ sudo dpkg --install _package_.deb

**Bzipped Archive Installation**
    
    
    $ sudo tar xjvf _package_.tar.bz2

**Mac installation**

Double-click the _package_`.dmg` file and follow the instructions

The Redhat, Debian, and Mac packages will install the ThriftBroker under a directory by the name of /opt/hypertable/$VERSION by default. You will need to change the ownership of the installation files and directories to the owner that you plan to launch the services as. For example:
    
    
    sudo chown -R john:staff /opt/hypertable/$VERSION

### STEP 2 - FHS-ize Installation

See [Filesystem Hierarchy Standard](../misc/filesystem_hierarchy_standard_fhs.md) for an introduction to FHS. Create the directories `/etc/opt/hypertable` and `/var/opt/hypertable` and change ownership to the user account under which the binaries will be run. For example:
    
    
    $ sudo mkdir /etc/opt/hypertable /var/opt/hypertable
    $ sudo chown john:staff /etc/opt/hypertable /var/opt/hypertable

Then FHS-ize the installation with the following command:
    
    
    $ /opt/hypertable/$VERSION/bin/fhsize.sh

### STEP 3 - Set "current" Link

To make the latest version of the ThriftBroker referenceable from a well-known location, we recommend setting a "current" link to point to the latest installation. After installation, make a symlink from `/opt/hypertable/current` to point to the latest installed version.
    
    
    $ cd /opt/hypertable
    $ ln -s $VERSION current
    

### STEP 4 - Install Hypertable Configuration File

In order for the ThriftBroker to communicate with the Hypertable cluster, you will need to install the `hypertable.cfg` file that was configured for your Hypertable cluster. Assuming that you installed Hypertable on a machine called `hypertable-master` (either the standalone machine, or the cluster installation machine running a Hypertable Master), you can copy the configuration file from that machine into your ThriftBroker-only installation as follows.
    
    
    $ scp hypertable-master:/opt/hypertable/current/conf/hypertable.cfg /opt/hypertable/current/conf/

### STEP 5 - Starting and Stopping ThriftBroker

The ThriftBroker installation includes scripts that can be used to start and stop the ThriftBroker. The following example shows how to run the start-thriftbroker.sh script to launch the ThriftBroker.
    
    
    $ /opt/hypertable/current/bin/start-thriftbroker.sh 
    Started ThriftBroker
    

The following example shows how to stop the ThriftBroker.
    
    
     /opt/hypertable/current/bin/stop-servers.sh 
    Killing ThriftBroker.pid 50744
    Shutdown thrift broker complete
    

### STEP 6 - Automating ThriftBroker with Capistrano

The [Capistrano](https://github.com/capistrano/capistrano/wiki/2.x-Getting-Started) remote task automation tool can be used to administer a Hypertable cluster. Included in the Hypertable distribution is a Capistrano recipe file (Capfile) that defines tasks and roles for starting and stopping the Hypertable processes and performing other administrative operations. One of the roles defined in the default Capfile is the `thriftbroker` role. This role is intended for hosts that run ThriftBrokers only.

**NOTE:** ThriftBrokers are started automatically on all of the hosts in the `slave` role in order to support MapReduce, so it is not necessary to add the Hypertable RangeServer hosts to the `thriftbroker` role.

Once the `thriftbroker` role has been configured with the appropriate hosts, ThriftBrokers can be started on those hosts with the following command. 
    
    
    $ cap start_thriftbrokers

The ThriftBrokers running on the hosts in the `thriftbroker` role can be stopped with this command:
    
    
    $ cap stop_thriftbrokers
