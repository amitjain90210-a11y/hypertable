# Hadoop

Hadoop is an open source implementation of the Google Filesystem and MapReduce parallel computation framework. The Hadoop filesystem (HDFS) is the filesystem that most people run Hypertable on top of as it contains all of the architectural features required to efficiently support Hypertable. This document describes how to get Hypertable up and running on top of the Hadoop filesystem.

## Table of Contents

### Prerequisites

Before you get started with the installation, there are some general system requirements that need to be satisfied before proceeding. These requirements are described in the following list.

  * **admin machine** \- You should designate one of the machines in your Hypertable cluster as the admin machine (admin1 in examples below). This is the machine from which you will be administering the cluster. It can be the same machine as the master or any machine of your choosing. There are no special hardware requirements for this machine, but it needs to have Internet access (at least temporarily) to get the recommended cluster management tool, Capistrano, installed on it. It is possible to install Capistrano without Internet access, but it's challenging and could take you half a day to get it working.

  * **password-less ssh** \- For ease of administration, we recommend using [Capistrano](https://github.com/capistrano/capistrano/wiki/Documentation-v2.x), which requires password-less ssh login access from the admin machine to all other machines in the cluster (masters, hyperspace replicas, range servers, etc). See [Password-less SSH Login](../misc/password_less_ssh_login.md) for details on how to set this up.

  * **ssh MaxStartups** \- sshd on the admin machine needs to be configured to allow simultaneous connections from all of the machines in the Hypertable cluster. The default simultaneous connection limit, _MaxStartups_ , defaults to 10. See [SSH Connection Limit](../misc/ssh_maxstartups.md) for details on how to increase this limit.

  * **firewall** \- The Hypertable processes use TCP and UDP to communicate with one another and with client applications. Firewalls can block this traffic and prevent Hypertable from operating properly. Any firewall that blocks traffic between the Hypertable machines should be disabled or the appropriate ports should be opened up to allow Hypertable communication. See [Hypertable Firewall Requirements](../misc/firewall_requirements.md) for instructions on how to do this.

  * **open file limit** \- Most operating systems have a limit on the total number of files that a process can have open at any one time. This limit is usually set too low for Hypertable, since it can create a very large number of files. See [Open File Limit](../misc/how_to_increase_open_file_limit.md) for details on how to increase this limit.

### Step 1 - Install HDFS

The first step in getting Hypertable up and running on top of Hadoop is to install HDFS. Hypertable currently builds against Cloudera's CDH3 distribution of Hadoop (see [CDH3 Installation](https://ccp.cloudera.com/display/CDHDOC/CDH3+Installation) for installation instructions). Each RangeServer process should run on a machine that is also running an HDFS DataNode. It's best not to run the HDFS NameNode on the same machine as a RangeServer since both of those processes tend to consume a lot of RAM.

To accommodate Bigtable-style workload, HDFS needs to be specially configured. The `dfs.datanode.max.xcievers` property, which controls the number of files that a DataNode can service concurrently, should be increased to at least 4096 and the `dfs.namenode.handler.count`, which controls the number of NameNode threads available to handle RPCs, should be increased to at least 20. This can be accomplished by adding the following lines to the `conf/hdfs-site.xml` file.

    <property>
      <name>dfs.namenode.handler.count
      <value>20</value>
    </name></property>
    <property>
      <name>dfs.datanode.max.xcievers</name>
      <value>4096</value>
    </property>

Once the filesystem is installed, create a `/hypertable` directory that is readable and writable by the user account in which hypertable will run. For example:

    sudo -u hdfs hadoop fs -mkdir /hypertable
    sudo -u hdfs hadoop fs -chmod 777 /hypertable

### Step 2 - Install Capistrano

The Hypertable distribution comes with a number of scripts to start and stop the various servers that make up a Hypertable cluster. You can use your own cluster management tool to launch these scripts and deploy new binaries. However, if you're not already using a cluster management tool, we recommend [Capistrano](https://github.com/capistrano/capistrano/wiki/Documentation-v2.x). The distribution comes with a Capistrano config file (`conf/Capfile.cluster`) that makes deploying and launching Hypertable a breeze.

Capistrano is a simple tool for automating the remote execution of tasks. It uses ssh to do the remote execution. To ease deployment, you should have password-less ssh access (i.e. public key) to all of the machines in your cluster. Installing Capistrano is pretty simple. On most systems you just need to execute the following commands (Internet access required):

    $ sudo gem update
    $ sudo gem install capistrano

After this installation step you should now have the cap program in your path:

    $ cap --version
    Capistrano v2.9.0

### Step 3 - Edit Capistrano Capfile

Once you have Capistrano installed, copy the `conf/Capfile.cluster` that comes with the Hypertable distribution to your working directory (e.g. home directory) on admin1, rename it to Capfile, and tailor it for your environment. The cap command reads the file Capfile in the current working directory by default. There are some variables that are set at the top that you need to modify for your particular environment. The following shows the variables at the top of the Capfile that need modification:

    set :source_machine,     "admin1"
    set :install_dir,        "/opt/hypertable"
    set :hypertable_version, "0.9.5.5"
    set :default_pkg,        "/tmp/hypertable-0.9.5.5-linux-x86_64.rpm"
    set :default_dfs,        "hadoop"
    set :default_config,     "/root/hypertable.cfg"

Here's a brief description of each variable:

**Table 2. Hypertable Capistrano Variables**

Variable | Description
---|---
`source_machine` |  machine from which you will build the binaries, distribute them to the other machines, and launch the service.
`install_dir` |  directory on source_machine where you have installed Hypertable. It is also the directory on the remote machines where the installation will get rsync'ed to.
`hypertable_version` |  version of Hypertable you are deploying
`default_pkg` |  Path to binary package file (.dmg, .rpm, or .tar.bz2) on source machine
`default_dfs` |  distributed file system you are running Hypertable on top of. Valid values are "local", "hadoop", "kfs", or "ceph"
`default_config` |  location of the default Hypertable configuration file that you plan to use

In addition to the above variables, you also need to define three roles, one for the machine that will run the master processes, one for the machines that will run the Hyperspace replicas, and one for the machines that will run the RangeServers. Edit the following lines:

    role :source, "admin1"
    role :master, "master"
    role :hyperspace, "hyperspace001", "hyperspace002", "hyperspace003"
    role :slave,  "slave001", "slave002", "slave003", "slave004", "slave005", "slave006", "slave007", "slave008"
    role :localhost, "admin1"
    role :thriftbroker
    role :spare

The following table describes each role.

**Table 3. Hypertable Capistrano Roles**

Role | Description
---|---
`source` |  The machine from which you will be distributing the binaries (admin1 in this example).
`master` |  The machine that will run the Hypertable master process as well as a DFS broker. Ideally this machine is high quality and somewhat lightly loaded (e.g. not running a RangeServer). Typically you would have a high quality machine running the Hypertable master, a Hyperspace replica, and the HDFS NameNode
`hyperspace` |  The machines that will run Hyperspace replicas. There should be at least one machine defined for this role. The machines that take on this role should be somewhat lightly loaded (e.g. not running a RangeServer)
`slave` |  The machines that will run RangeServers. Hypertable is designed to run on a filesystem like HDFS. In fact, the system works best from a performance standpoint when the RangeServers are run on the same machines as the HDFS DataNodes. This role will also launch a DFS broker and a ThriftBroker.
`localhost` |  The name of the machine that you're administering the cluster from (admin1 in this example).
`thriftbroker` |  Additional machines that will be running a ThriftBroker (e.g. web servers). NOTE: You do not have to add the slave machines to this role, since a ThriftBroker is automatically started on each slave machine to support MapReduce.
`spare` |  Machines that will act as standbys. They will be kept current with the latest binaries.

### Step 4 - Install Hypertable Binaries

The Hypertable binaries can either be downloaded prepackaged, or you can compile them from source code. To install the prepackaged version, [download](http://hypertable.com/download/) the Hypertable package (.dmg, .rpm, or .tar.bz2) that you want to install and put it somewhere accessible on the source machine (admin1 in this example). Modify the _hypertable_version_ and _default_pkg_ variables at the top of the Capfile to contain the version of Hypertable you are installing and the absolute path to the package file on the source machine, respectively. For example, if you're upgrading to version 0.9.5.5 and using the RPM package, set the variables as follows.

    set :hypertable_version, "0.9.5.5"
    set :default_pkg,        "/tmp/hypertable-0.9.5.5-linux-x86_64.rpm"

To distribute and install the binary package on all necessary machines, issue the following command. This command will cause the package to get rsync'ed to all participating machines and installed with the appropriate package manager (`rpm`, `dpkg`, or `tar`) depending on the package type.

    $ cap install_package

If you prefer compiling the binaries from source, you can use Capistrano to distribute the binaries with rsync. On admin1 be sure Hypertable is installed in the location specified by the _install_dir_ variable at the top of the Capfile and that the _hypertable_version_ variable at the top of the Capfile matches the version you are installing (`/opt/hypertable` and `0.9.5.5` in this example). Then distribute the binaries with the following command.

    $ cap dist

### Step 5 - FHS-ize Installation

See [Filesystem Hierarchy Standard](../misc/filesystem_hierarchy_standard_fhs.md) for an introduction to FHS. If you're running as a user other than root, first create the directories `/etc/opt/hypertable` and `/var/opt/hypertable` on all machines in the cluster and change ownership to the user account under which the binaries will be run. For example:

    $ sudo cap shell
    cap> mkdir /etc/opt/hypertable /var/opt/hypertable
    cap> chown chris:staff /etc/opt/hypertable /var/opt/hypertable

Then FHS-ize the installation with the following command:

    $ cap fhsize

### Step 6 - Create and Distribute hypertable.cfg

The next step is to create a `hypertable.cfg` file that is specific to your deployment. A basic `hypertable.cfg` file can be found in the `conf/` subdirectory of your hypertable installation which can be copied and modified as needed. The following table shows the minimum set of required and recommended properties that you need to modify.

**Table 1. Recommended and Required Properties**

Property | Description
---|---
`HdfsBroker.fs.default.name` |  URL of the HDFS NameNode. Should match `fs.default.name` property of Hadoop configuration file hdfs-site.xml
`Hyperspace.Replica.Host` |  Hostname of Hyperspace replica
`Hypertable.RangeServer.Monitoring.DataDirectories` |  This property is optional, but recommended. It contains a list of directories that are the mount points of the HDFS data node storage volumes. By setting this property appropriately, the Hypertable monitoring system will be able to provide accurate disk usage information.

You can leave all other properties at their default values. Hypertable is designed to adapt to the hardware on which it runs and to dynamically adapt to changes in workload, so no special configuration is needed beyond the basic properties listed in the above table. For example, the following shows the changes we made to the hypertable.cfg file for our test cluster.

    HdfsBroker.fs.default.name=hdfs://master:9000

    Hyperspace.Replica.Host=hyperspace001
    Hyperspace.Replica.Host=hyperspace002
    Hyperspace.Replica.Host=hyperspace003

    Hypertable.RangeServer.Monitoring.DataDirectories="/data/1,/data/2,/data/3,/data/4"

See [hypertable-example.cfg](http://www.hypertable.org/pub/hypertable-example-cfg.txt)

Once you've created the hypertable.cfg file for your cluster, put it on the source machine (admin1) and set the absolute pathname referenced in the _default_config_ Capfile variable to point to this file (e.g. /etc/opt/hypertable/hypertable.cfg). Then distribute the custom config files with the following command.

    $ cap push_config

If you ever need to make changes to the config file, make the changes, re-run `cap push_config`, and then restart Hypertable (see sections 9 and 11, below).

### Step 7 - Set "current" link

To make the latest version of Hypertable referenceable from a well-known location, create a "current" link to point to the latest installation. This can be accomplished with the following command.

    $ cap set_current

### Step 8 - Synchronize Clocks

The system cannot operate correctly unless the clocks on all machines are synchronized. Use the [Network Time Protocol (ntp)](http://www.ntp.org/) to ensure that the clocks get synchronized and remain in sync. Run the 'date' command on all machines to make sure they are in sync. The following Capistrano shell session show the output of a cluster with properly synchronized clocks.

    cap> date
    [establishing connection(s) to master, hyperspace001, hyperspace002, hyperspace003, slave001, slave002, slave003, slave004, slave005, slave006, slave007, slave008]
     ** [out :: master] Sat Jan  3 18:05:33 PST 2009
     ** [out :: hyperspace001] Sat Jan  3 18:05:33 PST 2009
     ** [out :: hyperspace002] Sat Jan  3 18:05:33 PST 2009
     ** [out :: hyperspace003] Sat Jan  3 18:05:33 PST 2009
     ** [out :: slave001] Sat Jan  3 18:05:33 PST 2009
     ** [out :: slave002] Sat Jan  3 18:05:33 PST 2009
     ** [out :: slave003] Sat Jan  3 18:05:33 PST 2009
     ** [out :: slave004] Sat Jan  3 18:05:33 PST 2009
     ** [out :: slave005] Sat Jan  3 18:05:33 PST 2009
     ** [out :: slave007] Sat Jan  3 18:05:33 PST 2009
     ** [out :: slave008] Sat Jan  3 18:05:33 PST 2009

### Step 9 - Start Hypertable

The following commands should be run from the directory containing the Capfile. To start all of the Hypertable servers:

    $ cap start

If you want to launch the service using a different config file than the default (e.g. /home/chris/alternate.cfg):

    $ cap -S config=/home/chris/alternate.cfg start

You'll need to specify the same config file when running Hypertable commands such as the command shell, for example:

    $ /opt/hypertable/current/bin/ht shell --config=/home/chris/alternate.cfg

### Step 10 - Verify Installation

Create a table.

    echo "USE '/'; CREATE TABLE foo ( c1, c2 ); GET LISTING;" \
        | /opt/hypertable/current/bin/ht shell --batch

The output of this command should look like:

    foo
    sys (namespace)

Load some data.

    echo "USE '/'; INSERT INTO foo VALUES('001', 'c1', 'very'), \
        ('000', 'c1', 'Hypertable'), ('001', 'c2', 'easy'), ('000', 'c2', 'is');" \
        | /opt/hypertable/current/bin/ht shell --batch

Dump the table.

    echo "USE '/'; SELECT * FROM foo;" \
        | /opt/hypertable/current/bin/ht shell --batch

The output of this command should look like:

    000	c1	Hypertable
    000	c2	is
    001	c1	very
    001	c2	easy

### Step 11 - Stop Hypertable

To stop the service, shutting down all servers:

    $ cap stop

If you want to wipe your database clean, removing all namespaces and tables:

    $ cap cleandb

### What Next?

Congratulations! Now that you have successfully installed Hypertable, we recommend that you walk through the [HQL Tutorial](../developer_guide/index.md) to get familiar with using the system.
