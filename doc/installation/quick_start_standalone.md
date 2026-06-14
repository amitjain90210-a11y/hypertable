# Standalone

For applications that need the performance characteristics and data model that Hypertable has to offer, but don't require horizontal scalability, Hypertable can be setup to run on a single machine over its native filesystem. For better performance, this machine can be configured with an SSD drive. This document describes how to get Hypertable up and running on a single standalone machine.

## Table of Contents

### Prerequisites

Before you get started with the installation, there are some general system requirements that need to be satisfied before proceeding. These requirements are described as follows:

  * **root access** \- If you plan to install Hypertable in the standard location (`/opt/hypertable`) you will need root access to create and populate that directory. You can either carry out the steps below while logged in as the _root_ user or you can run each of the commands with `sudo`. If you do not have root access, you can install the `.tar.bz2` package anywhere you like.

  * **open file limit** \- Most operating systems have a limit on the total number of files that a process can have open at any one time. If you plan to load a large amount of data into Hypertable, you will likely need to increase this limit. See [Open File Limit](../misc/how_to_increase_open_file_limit.md) for details on how to increase this limit.

  * **firewall** \- The Hypertable processes use TCP and UDP to communicate with one another and with client applications. Firewalls can block this traffic and prevent Hypertable from operating properly. Any firewall that blocks traffic to or from specific ports should be disabled or the appropriate ports should be opened up to allow Hypertable communication. See [Hypertable Firewall Requirements](../misc/firewall_requirements.md) for instructions on how to do this.

  * **Linux Kernel Tuning** \- The Linux kernel exposes some configuration parameters that can be tuned to optimize the behavior of the kernel for the specific workload which the operating system will be handling. To tune these parameters for optimum performance of the Hypertable server processes, see [Linux Kernel Configuration](../misc/linux_kernel_configuration.md).

### Step 1 - Install Hypertable Package

Hypertable can be installed via binary packages which can be downloaded as described on the Hypertable [Download](https://hypertable.com/download) page. The packages come bundled with nearly all of the dependent shared libraries. The nice thing about this approach is that only a single package is needed for all flavors of Linux for each supported architecture (32-bit and 64-bit). The only requirement is that your system be built with glibc 2.4+ (released on March 6th 2006). Hypertable comes with a program launch script, `ht`, that sets up `LD_LIBRARY_PATH` (or `DYLD_LIBRARY_PATH`) to point to the `lib/` directory of the installation so that the dependent libraries can be found by the dynamic linker.

To begin the package installation, switch to the directory containing the package file and then issue the command listed below for your operating system.

**Redhat, CentOS, or SUSE Installation**

    $ sudo rpm -ivh --replacepkgs --nomd5 --nodeps --oldpackage _package_.rpm

**Debian or Ubuntu Installation**

    $ sudo dpkg --install _package_.deb

**Bzipped Archive Installation**

    sudo mkdir /opt/hypertable
    tar xjvf _package_.tar.bz2
    sudo mv hypertable-*/opt/hypertable/* /opt/hypertable/

**Mac installation**

Double-click the _package_`.dmg` file and follow the instructions

The Redhat, Debian, and Mac packages will install Hypertable under a directory by the name of /opt/hypertable/$VERSION by default. You will need to change the ownership of the installation files and directories to the owner that you plan to launch the services as. For example:

    sudo chown -R john:staff /opt/hypertable/0.9.8.5

### Step 2 - FHS-ize Installation

See [Filesystem Hierarchy Standard](../misc/filesystem_hierarchy_standard_fhs.md) for an introduction to FHS. Create the directories `/etc/opt/hypertable` and `/var/opt/hypertable` on all machines in the cluster and change ownership to the user account under which the binaries will be run. For example:

    $ sudo mkdir /etc/opt/hypertable /var/opt/hypertable
    $ sudo chown john:staff /etc/opt/hypertable /var/opt/hypertable

Then FHS-ize the installation with the following command:

    $ /opt/hypertable/0.9.8.5/bin/ht-fhsize.sh

### Step 3 - Set "current" link

To make the latest version of Hypertable referenceable from a well-known location, we recommend setting a "current" link to point to the latest installation. After installation, make a symlink from `/opt/hypertable/current` to point to the latest installed version, for example:

    $ cd /opt/hypertable
    $ ln -s 0.9.8.5 current

So that you don't have to specify absolute paths when running Hypertable commands, we recommend that you add the Hypertable `bin/` directory to the program search path for your shell. If you're running the bash shell, this can be accomplished by adding the following line to your `.bashrc` file:

    export PATH=$PATH:/opt/hypertable/current/bin

You'll need to log out and log back in to pick up the `PATH` change. If you're running a shell other than bash, consult the documentation for your shell for instructions on how to modify the program search path. Once the search path is setup, the hypertable CLI (command shell) can be run as follows:

    $ ht shell

### Step 4 - Setup data volume

To configure the Hypertable installation to write to the correct data volume, make sure the volume is formatted and mounted somewhere, for example `/data`. Then create a directory on that data volume to serve as the toplevel directory for the Hypertable data files. For example:

    $ sudo mkdir -p /data/hypertable/fs

Then make sure this directory is readable and writeable by the user account from which you will be running the Hypertable service. For example:

    $ sudo chown -R john:staff /data/hypertable

Finally, create a symbolic link called "fs" inside the Hypertable installation pointing to the directory you just created on the data volume. For example:

    $ cd /opt/hypertable/current
    $ rm -f fs
    $ ln -s /data/hypertable/fs

### Step 5 - Edit hypertable.cfg

Open the file `/opt/hypertable/current/conf/hypertable.cfg` file in an editor and modify the `Hyperspace.Replica.Host` , `Hypertable.Cluster.Name`, and `Hypertable.RangeServer.Monitoring.DataDirectories` properties for your cluster. For example:

    Hyperspace.Replica.Host=yourmachine

    Hypertable.Cluster.Name="Your Cluster Name"

    Hypertable.RangeServer.Monitoring.DataDirectories="/data"

Be sure to use the public DNS name of the machine for the `Hyperspace.Replica.Host` property. By doing so, it will allow other machines in your network to access this local Hypertable instance by simply copying this modified configuration file into the `conf/` directory of their Hypertable installation:

    othermachine$ scp yourmachine:/opt/hypertable/current/conf/hypertable.cfg /opt/hypertable/current/conf
    othermachine$ ht shell

### Step 6 - Install monitoring system dependencies

The Monitoring UI is written in Ruby with the Sinatra web framework and uses RRDTool to create databases for storing metric data. Ruby 1.8.7 or greater is required. The first step in getting the dependencies set up is to install Ruby, RubyGems, and RRDTool:

**Redhat (CentOS)**

    $ yum -y install rrdtool ruby rubygems ruby-devel ruby-rdoc

**Debian (Ubuntu)**

    $ apt-get -y install rrdtool ruby rubygems ruby-dev rdoc

**Mac OSX**

Ruby is installed by default on OSX, so nothing needs to be done to install it. For RRDTool, you can install it with either [MacPorts](http://www.macports.org/) or [Homebrew](http://brew.sh/). To install it with MacPorts, issue the following command:

    $ port install rrdtool

To install it with Homebrew, issue the following command:

    $ brew install rrdtool

After successfully installing Ruby, RubyGems, and RRDTool, the next step is to verify that you have Ruby 1.8.7 or greater installed:

    $ ruby --version
    ruby 1.8.7 (2011-06-30 patchlevel 352) [x86_64-linux]

If your version of ruby is older than 1.8.7, you'll need to consult your operating system documentation (i.e. the Internet) to figure out how to install a newer version of Ruby and RubyGems (the packages may be called `ruby19`, `rubygems19`, ...).

Once you have the correct version of Ruby and RubyGems installed, install the required gems as follows:

    $ gem install sinatra rack thin json titleize syck

**NOTE** : the `syck` gem is only required for ruby >= 2.0

### Step 7 - Install Notification Script

The Hypertable Master will invoke a notification script (`conf/notification-hook.sh`) to inform the Hypertable administrator of certain events such as machine failure or any problems that may have been encountered during machine failure recovery. The script accepts two arguments, a subject string and a message body string. The prefix of the subject line string can be examined to determine the type of notification, "NOTICE" indicating a notification of abnormal condition, and "ERROR" indicating a hard error that requires intervention. The following is an example notification script (`/opt/hypertable/current/conf/notification-hook.sh`) that can be used to email notificaiton to a list of administrators:

    #!/usr/bin/env bash

    recipients="root"
    subject=$1
    message=$2
    echo -e $message | mail -s "$subject" ${recipients}

Modify the _recipients_ variable to contain the the list of recipients to whom notificaiton messages are to be sent. Verify that the script works properly by testing it manually:

    /opt/hypertable/current/conf/notification-hook.sh "Test Message" "This is a test."

### Step 8 - [optional] Edit cluster.def

Hypertable clusters are administered with the `ht_cluster` task automation tool. The tool requires a configuration file called `cluster.def` which is located in the `conf/` directory of the installation. Configuring `cluster.def` for your standalone instance allows you to administer Hypertable in the exact same way you would administer a full-blown Hypertable cluster.

The first thing to do is to get your machine set up so that you can ssh into localhost without a password. See [Password-less SSL Login](../misc/password_less_ssh_login.md) for details on how to do this.

Hypertable comes with an example cluster configuration file called `cluster.def-EXAMPLE`. Copy or rename this file to `cluster.def`, for example:

    cd /opt/hypertable/0.9.8.5/conf
    cp cluster.def-EXAMPLE cluster.def

There are some variables at the top of this file that you need to modify for your particular environment. These variables are shown below.

    INSTALL_PREFIX=/opt/hypertable
    HYPERTABLE_VERSION=0.9.8.5
    PACKAGE_FILE=/root/packages/hypertable-0.9.8.5-linux-x86_64.tar.gz
    FS=local
    ORIGIN_CONFIG_FILE=/root/hypertable.cfg

The main difference between how `cluster.def` is configured for a standalone instance and how one is configured for a Hadoop cluster is that the `FS` variable is set to _local_ instead of _hadoop_ and the `HADOOP_DISTRO` variable is not used.

In addition to setting the variables, the roles must also be configured. For a standalone Hypertable instance, all of the roles are assigned to _localhost_ , for example:

    role: source localhost
    role: master localhost
    role: hyperspace localhost
    role: slave localhost
    role: thriftbroker
    role: spare

For a complete description of the variables and roles, see _Step 3 - Edit cluster.def_ section of the [Hadoop Installation](quick_start_cluster_installation.md#step-3---edit-clusterdef) guide.

### Give it a try

The programs and shell scripts for administering Hypertable can be found in the `bin/` directory of the Hypertable installation. It is **strongly** recommended that you add this directory to your `PATH` environment variable so that you can run the programs without having to specify full paths. For example, to add the Hypertable `bin/` directory to the `PATH` environment variable in Bash, add the following line to your `.bashrc` file:

    export PATH=$PATH:/opt/hypertable/current/bin

For instructions on how to do this with other shells, please refer to their documentation.

####  Start Hypertable

To start all of the Hypertable processes:

    $ ht start-all-servers local

It should generate output that looks something like this:

    FsBroker (local) Started
    Hyperspace Started
    Master Started
    RangeServer Started
    ThriftBroker Started

Alternatively, if you configured `cluster.def` as described in Step 8, you can start all of the Hypertable processes with the following command:

    $ ht cluster start

####  Verify that it works

Create a table.

    echo "CREATE TABLE foo ( c1, c2 ); GET LISTING;" | ht shell --batch

The output of this command should look like:

    foo
    sys (namespace)
    tmp (namespace)

Load some data.

    echo "INSERT INTO foo VALUES('001', 'c1', 'very'), \
        ('000', 'c1', 'Hypertable'), ('001', 'c2', 'easy'), ('000', 'c2', 'is');" \
        | ht shell --batch

Dump the table.

    echo "SELECT * FROM foo;" | ht shell --batch

The output of this command should look like:

    000	c1	Hypertable
    000	c2	is
    001	c1	very
    001	c2	easy

####  View Monitoring UI

The Hypertable monitoring UI is accessible on HTTP port 15860. It takes about a minute after Hypertable comes up for the monitoring system to gather information and start populating the metric databases. You can access the monitoring system in a web browser by visiting the address formulated with the machine name and port 15860 (e.g. [http://your-hypertable-machine:15860](http://your-hypertable-machine:15860)). If you get an error message in the browser, wait a minute, then hit refresh and it should come up.

####  Stop Hypertable

To stop all of the Hypertable processes:

    $ ht stop-servers

Alternatively, if you configured `cluster.def` as described in Step 8, you can stop Hypertable with the following command:

    $ ht cluster stop

To wipe Hypertable clean, removing all namespaces and tables:

    $ ht destroy-database

or

    $ ht cluster destroy

### What Next?

Congratulations! Now that you have successfully installed Hypertable, we recommend that you walk through the [HQL Tutorial](../user_guide.md) to get familiar with using the system.
