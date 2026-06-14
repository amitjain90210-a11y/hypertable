# Ganglia Monitoring

[Ganglia](http://ganglia.info/) is one of the most popular open source, scalable moniotoring system for large compute clusters. It has an efficient design that optionally leverages IP multicast to minimize network impact and has been successfully scaled to clusters as large as 2000 nodes. It was originally developed to aggregate machine metrics (CPU usage, memory usage, load average, etc.) but as of version 3.1.0, it includes a plugin module interface that allows it to be extended to monitor any application as well. This document describes how to setup and configure Ganglias to monitor the Hypertable processes.

## Table of Contents

### Hypertable Ganglia Metrics

The Ganglia metrics extension for Hypertable provide many more system metrics that that provided by the basic Hypertable monitoring system. Use of Ganglia and the Hypertable extension is highly recommended as it provides much better insight into the behavior of all system components, including the Masters, Hyperspace, FSbrokers, ThriftBrokers, and the RangeServers. The following table shows all of the metrics provided by the Ganglia Hypertable extension module.

**ThriftBroker Metrics**

Metric | Units
---|---
Connections |  count
Requests |  requests/s
Errors |  errors/s
Virtual Memory |  GB
Resident Memory |  GB
Heap Size |  GB
Heap Slack Bytes |  GB
CPU user |  percentage
CPU system |  percentage
Version |  string

**RangeServer Metrics**

Metric | Units
---|---
Scans |  scans/s
Updates |  updates/s
Bytes Returned |  bytes/s
Bytes Scanned |  bytes/s
Byte Scan Yield |  percentage
Bytes Written |  bytes/s
Cells Returned |  cells/s
Cells Scanned |  cells/s
Cell Scan Yield |  percentage
Outstanding Scanners |  count
Request Backlog |  count
Minor Compactions |  count
Major Compactions |  count
Merging Compactions |  count
GC Compactions |  count
Ranges |  count
Cell Stores |  count
Block Cache Fill |  GB
Block Cache Hits |  percentage
Block Cache Memory |  GB
Query Cache Fill |  GB
Query Cache Hits |  percentage
Query Cache Memory |  GB
Query Cache Waiters |  count
Virtual Memory |  GB
Resident Memory |  GB
Heap Size |  GB
Heap Slack Bytes |  GB
CPU user |  percentage
CPU system |  percentage
Version |  string

**FSBroker Metrics**

Metric | Units
---|---
Read Throughput |  MB/s
Write Throughput |  MB/s
Syncs |  syncs/s
Sync Latency |  milliseconds
Errors |  count
JVM GC Time |  milliseconds
JVM GCs |  count
JVM Heap Size |  GB
Virtual Memory |  GB
Resident Memory |  GB
Heap Size |  GB
Heap Slack Bytes |  GB
CPU user |  percentage
CPU system |  percentage
Type |  string (hadoop, local, etc.)
Version |  string

**Master Metrics**

Metric | Units
---|---
Operations |  operations/s
Virtual Memory |  GB
Resident Memory |  GB
Heap Size |  GB
Heap Slack Bytes |  GB
CPU user |  percentage
CPU system |  percentage
Version |  string

**Hyperspace Metrics**

Metric | Units
---|---
Requests |  requests/s
Virtual Memory |  GB
Resident Memory |  GB
Heap Size |  GB
Heap Slack Bytes |  GB
CPU user |  percentage
CPU system |  percentage
Version |  string

### Installing the Hypertable Ganglia Extension

The Ganglia system consists of three primary components, _gmond_ , _gmetad_ , and _gweb_. The gmond daemon runs on all nodes and collects node-specific metrics and sends them over to gmetad for aggregation. gweb is the web UI that runs on the same machines as gmetad and provides and interface for viewing the metrics.

The Hypertable Ganglia extension module requires Ganglia 3.1.0 or greater. If the version of Ganglia provided by your system is older than that, you'll need to remove the existing packages and build the Ganglia from scratch.

Hypertable metrics are introduced to the Ganglia system through the [Hypertable Ganglia python module](http://cdn.hypertable.com/pub/ganglia/hypertable.py). To install it, on each machine in which gmond is installed, make sure the python module extension directory exists and then copy the Hypertable Ganglia python module into that directory. For example:

    LIBDIR=lib
    if [ -d /usr/lib64 ] && [ `uname -m` == "x86_64" ] ; then
      LIBDIR=lib64
    fi

    sudo mkdir /usr/$LIBDIR/ganglia/python_modules
    cd /usr/$LIBDIR/ganglia/python_modules

    # If Ganglia was built from source and installed under /usr/local
    # then replace the above commands with the following:
    sudo mkdir /usr/local/$LIBDIR/ganglia/python_modules
    cd /usr/local/$LIBDIR/ganglia/python_modules

    sudo wget [http://cdn.hypertable.com/pub/ganglia/hypertable.py](http://cdn.hypertable.com/pub/ganglia/hypertable.py)

The next step is to configure the Hypertable Ganglia python module by copying the [Hypertable Ganglia python module configuration file](http://cdn.hypertable.com/pub/ganglia/hypertable.pyconf) into the ganglia configuration directory. For example, on a 64-bit CentOS 6 based system, you would do the following on each machine in which you instlaled the extension module:

    cd /usr/local/etc/conf.d/
    sudo wget [http://cdn.hypertable.com/pub/ganglia/hypertable.pyconf](http://cdn.hypertable.com/pub/ganglia/hypertable.pyconf)

The last step is to edit the configuration file (`/usr/local/etc/conf.d/hypertable.pyconf`) on each node and comment out the `Enable` parameters at the top of the file for the metrics that are not required for the node.

_RangeServer node_

    modules {
      module {
        name = "hypertable"
        language = "python"
        param FSBroker { value = "hadoop" }
        param EnableFSBroker { value = 1 }
    #    param EnableHyperspace { value = 1 }
    #    param EnableMaster { value = 1 }
        param EnableRangeServer { value = 1 }
        param EnableThriftBroker { value = 1 }
      }
    }
    ...

_Master & Hyperspace node_

    modules {
      module {
        name = "hypertable"
        language = "python"
        param FSBroker { value = "hadoop" }
        param EnableFSBroker { value = 1 }
        param EnableHyperspace { value = 1 }
        param EnableMaster { value = 1 }
    #    param EnableRangeServer { value = 1 }
        param EnableThriftBroker { value = 1 }
      }
    }

_ThriftBroker-only node_

    modules {
      module {
        name = "hypertable"
        language = "python"
        param FSBroker { value = "hadoop" }
        param EnableFSBroker { value = 1 }
    #    param EnableHyperspace { value = 1 }
    #    param EnableMaster { value = 1 }
    #    param EnableRangeServer { value = 1 }
        param EnableThriftBroker { value = 1 }
      }
    }

After making the configuration changes it is recommended that you stop any running instance of gmond and gmetad and then clear out the rrd databases by running the following command on each gmetad machine:

    rm -rf /var/lib/ganglia/rrds/*

Now start the gmond daemon on each node with:

    /etc/init.d/gmond start

and then start the gmetad on the gmetad nodes with:

    /etc/init.d/gmetad start

And that's it. Hypertable metrics will now start appearing in the Ganglia web interface. If you run into trouble or have any questions regarding Hypertable Ganglia metrics, don't hesitate to post questions to the [Hypertable User mailing list](http://groups.google.com/group/hypertable-user).

### Installing Ganglia

On modern Linux systems the Ganglia `gmond` and `gmetad` can be installed with the package manager. The `gmetad` program should be installed on all master machines along with rrdtool. The `gmond` along with the `modpython.so` extension module should be installed on machines in the cluster.

_RedHat/CentOS:_

    $ sudo ht cluster
    cluster> with master yum -y install ganglia-gmetad rrdtool
    cluster> yum -y install ganglia-gmond ganglia-gmond-python

_Debian/Ubuntu:_

    $ sudo ht cluster
    cluster> with master apt-get -y install gmetad rrdtool
    cluster> apt-get -y install ganglia-monitor

Now verify that the version of Ganglia installed is 3.1.0 or greater:

    $ gmond --version
    gmond 3.6.0

If the output of the above command shows a version less than 3.1.0, then skip to the section _Building Ganglia from source_ below.

**Verify` modpython.so` was built with Python 2.6**

The Hypertable Ganglia extension is implemented as a python extension that is loaded by gmond's `modpython.so` plugin module. It requires that `modpython.so` be compiled with Python 2.6 or greater. If it is compiled with an older version of Python, `gmond` will silently fail to load the Hypertable extension module and no Hypertable metrics will be collected. To verify that `modpython.so` was built with Python 2.6 or greater, execute the following command:

    $ ldd /usr/lib*/ganglia/modpython.so /usr/local/lib*/ganglia/modpython.so 2>1 \
          | grep libpython
      libpython2.6.so.1.0 => /usr/lib64/libpython2.6.so.1.0 (0x00007f5969421000)

If the above commands show that `modpython.so` was compiled with an older version of python such as `libpython2.4.so`, then you'll need to uninstall `gmond` and `gmetad` from all machines and build from source as described in the next section.

**Building Ganglia from source**

Uninstall gmond and gmetad from all machines in the cluster and make sure Python 2.6 and the associated development package is installed:

_RedHat/CentOS:_

    $ sudo ht cluster
    cluster> yum -y erase ganglia-gmetad ganglia-gmond ganglia-gmond-python
    cluster> yum -y install python26 python26-devel

_Debian/Ubuntu:_

    $ sudo ht cluster
    cluster> apt-get -y remove gmetad ganglia-monitor
    cluster> apt-get -y install python26 python26-dev

On every master and slave machine, download the latest Ganglia source tarball (3.6.0 as of this writing) and untar it somewhere. Then `cd` into the source directory, configure, build, and install it as follows.

    $ ./configure --with-gmetad --with-python=/usr/bin/python2.6
    $ make
    $ make install

Replace `/usr/bin/python2.6` with the absolute path to the Python 2.6 interpreter as it is installed on your system.

At this point, `gmetad` and `gmond` are ready to be configured. Consult the Ganglia documentation for how to configure these services. Be sure to configure `gmond` to run on every machine in the cluster and configure `gmetad` to run on all master machines. Also make sure that the `gmond` service is configured to load `modpython.so` (it typically is by default).

### Installing Ganglia Web Frontend

We recommend that you install the latest version of the Ganglia web front since it typically offers the most power to navigate and visualize the metrics. To do that, first download the latest Ganglia web frontend from the [Ganglia Sourceforge](http://ganglia.sourceforge.net/) website. Once it's donwloaded, untar it in `/usr/share` and create a symbolic link `ganglia-webfrontend` pointing to it. For example (assuming you downloaded the Ganglia web frontend tarball to `/tmp/``ganglia-web-3.6.2.tar.gz`):

    cd /usr/share
    tar xzvf /tmp/ganglia-web-3.6.2.tar.gz
    ln -sf ganglia-web-3.6.2 ganglia-webfrontend

### Troubleshooting

**1\. Ganglia is running but no Hypertable metrics are reported**

First make sure that the hypertable extension to gmond is being loaded properly. To do that, stop Ganglia and then try starting gmond with the debugging option -d1 to get details on module loading, for example:

    $ gmond -d1

If the output of the above command produces and error message that looks something like the following:

    [PYTHON] Can't import the metric module [hypertable].

      File "/usr/local/lib64/ganglia/python_modules/hypertable.py", line 39
        except socket_error as serr:
                             ^
    SyntaxError: invalid syntax
    Unable to find the metric information for 'ht.hyperspace.version'. Possible that the module has not been loaded.

    Unable to find the metric information for 'ht.fsbroker.version'. Possible that the module has not been loaded.

    Unable to find the metric information for 'ht.fsbroker.type'. Possible that the module has not been loaded.
    ...

That means that the `modpython.so` gmond plugin module was built with a version of Python that is older than 2.6, so you'll need to uninstall ganglia and build from source.
