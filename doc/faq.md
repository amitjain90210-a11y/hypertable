# FAQ

### Table of Contents

###  General

  * [Q: Why am I seeing this error in the DFSBroker log? `DFSClient: Could not obtain block blk_ ...`](#DFSClient_Could_not_obtain_block)
  * [Q: Why are Hypertable Servers Hanging on Ubuntu?](#why_are_hypertable_servers_hanging_on_ubuntu)
  * [Q: The RangeServer machines are swapping, how do I fix this?](#rangeserver_swapping)
  * [Q: Why is my RangeServer silently dying?](#why_is_my_rangeserver_silently_dying)
  * [Q: Why am I getting these rsync errors when running ht_cluster? `rsync: connection unexpectedly closed`](#rsync_problem)
  * [Q: Why am I seeing these errors in the log files? `Too many open files`](#too_many_open_files)
  * [Q: How can I convert log file Unix time (seconds since the Epoch) to something human readable?](#how_can_i_convert_unix_time)
  * [Q: Why is Hypertable not coming up on EC2 (e.g. RangeServer unable to connect to Hyperspace)?](#ec2_problems)
  * [Q: Why am I seeing these error messages? `RANGE SERVER clock skew detected`](#clock_skew)
  * [Q: How do I make Hypertable use a different network interface (`eth1` instead of `eth0`) ?](#change_network_interface)
  * [Q: Hypertable logs are filling my disks, how can I remedy this?](#disk_is_filling_up_how_to_remedy)
  * [Q: Firewall is blocking traffic, what ports should I open up?](#what_firewall_ports_to_open)
  * [Q: Why am I seeing this error on OpenSUSE? `ht-env.sh: line 105: 31207 Aborted (core dumped)`](#error_on_opensuse)
  * [Q: Why am I seeing this exception in ThriftBroker log? `org.apache.thrift.transport.TTransportException: Frame size (144130118) larger than max length (16384000)!`](#thriftbroker_framesize_error)
  * [Q: Why is my java application throwing `org.apache.thrift.transport.TTransportException: Read a negative frame size`](#negative_frame_size)
  * [Q: Why is my java application throwing `org.apache.thrift.TApplicationException: failed: out of sequence response`](#out_of_sequence_response)
  * [Q: Does Hypertable run on Microsoft Windows?](#windows_port)

###  Hadoop Specific

  * [Q: How do I get Hypertable to run on top of CDH5?](#switching_to_cdh5_distro)
  * [Q: How do I run Hypertable on top of Hortonworks Hadoop distro?](#switching_to_hortonworks_distro)
  * [Q: Why am I seeing this error message in the DFSBroker.hadoop.log? `mkdirs DFS directory /hypertable/servers/rs1/log/user - DFS BROKER i/o error`](#dfs_broker_io_error)
  * [java.lang.ClassNotFoundException: Class org.apache.hadoop.streaming.PipeMapRunner not found](#class_not_found_pipemaprunner)
  * [java.io.IOException: All datanodes X.X.X.X:50010 are bad. Aborting...](#all_datanodes_are_bad)
  * [java.io.IOException: Failed to add a datanode.](#failed_to_add_datanode)

### General

<a name="DFSClient_Could_not_obtain_block"></a>
**Q: Why am I seeing this error in the DFSBroker log?** `DFSClient: Could not obtain block blk_` ...

The HDFS DataNode has an limit on the number of files that it can serve concurrently. This limit is controlled by the `dfs.datanode.max.xcievers` hdfs configuration property. We recommend that you set the value to at least 4096. This can be accomplished by adding the following lines to your hdfs-site.xml file.

    <property>
      <name>dfs.datanode.max.xcievers</name>
      <value>4096</value>
    </property>

You'll need to distribute the file and restart HDFS for the change to take effect. If after making this change, you still see these error messages, try upping it to 8192.

* * *

<a name="why_are_hypertable_servers_hanging_on_ubuntu"></a>
**Q: Why are Hypertable Servers Hanging on Ubuntu?**

There appears to be a bug in the kernel (e.g. 2.6.32-308) for certain releases of Ubuntu. The processes seem to lose epoll notifications. This problem was [reported on the Hadoop mailing list](http://www.mail-archive.com/common-user@hadoop.apache.org/msg05557.html) as well. Try running an older version of Ubuntu. Here's an EC2 AMI of Ubuntu 9.10 from AppScale that seems to work - ami-3a81755 If you experience this problem with other kernel versions, please report to the mailing list. The recommended OS for Hypertable is CentOS/RedHat 5.

The following non-Redhat systems are known to work:

  * Debian GNU/Linux 5.0 \n \l (2.6.32-5-amd64)

* * *

<a name="rangeserver_swapping"></a>
**Q: The RangeServer machines are swapping, how do I fix this?**

Hypertable assumes that the RangeServer processes is the only process running on each slave machine that consumes a large amount of RAM. If you're running other processes such as MapReduce jobs that also consume a large amount of RAM, reduce the memory allocated to the RangeServer by setting either the [`Hypertable.RangeServer.MemoryLimit.Percentage`](reference_manual/configuration_properties.md#Hypertable.RangeServer.MemoryLimit.Percentage) or [`Hypertable.RangeServer.MemoryLimit`](reference_manual/configuration_properties.md#Hypertable.RangeServer.MemoryLimit) property in your `hypertable.cfg` file. For example:

    Hypertable.RangeServer.MemoryLimit.Percentage=40

If you're running Hypertable on Linux systems, you should also modify the vm.swappiness kernel parameter to control how aggressively memory pages are swapped to disk. It can be set to a value between 0-100; the higher the value, the more aggressively the kernel will seek out inactive memory pages and swap them to disk. The RangeServer startup script displays the current vm.swappiness setting, but you can also inspect it manually with the following command:

    # cat /proc/sys/vm/swappiness

On most systems, it is set to 60 by default. This is not suitable for Hypertable RangeServer nodes, since it can cause processes to get swapped out even when there is free memory available. We recommend that you set this parameter to 0; for example:

    # sysctl -w vm.swappiness=0

Another option to reduce memory pressure is to disable Hypertable's block cache and let the Linux kernel handle caching. This can be accomplished by adding the following line to your `hypertable.cfg` file:

    Hypertable.RangeServer.BlockCache.MaxMemory=0

* * *

<a name="why_is_my_rangeserver_silently_dying"></a>
**Q: Why is my RangeServer silently dying?**

When the system is undergoing intense loading activity, a RangeServer will periodically disappear, leaving no core file or error message in the log.

The RangeServer has been designed to track its memory usage. When it sees that the memory usage has exceeded 60% (default) of physical RAM, it will pause the incoming request queue and allow system maintenance activity to proceed, freeing up memory. When memory usage drops back down below the threshold, the incoming request queue is un-paused.

The RangeServer tracks memory consumption by keeping track of the amount of memory allocated. However, it does not account for any heap fragmentation which can push the memory usage above the configured limit. This can cause the system to start paging and eventually the RangeServer process can get killed by the Linux "out of memory killer". To check whether or not this is what you're experiencing, run the dmesg command and look for "Out of Memory" messages like the following.

    $ dmesg
    [...]
    Out of Memory: Kill process 4564 (start-rangeserv) score 1528534 and children.
    Out of memory: Killed process 4565 (Hypertable.Rang).
    oom-killer: gfp_mask=0x201d2, order=0

    Call Trace: {printk_ratelimit+21}
           {out_of_memory+55} {__alloc_pages+567}
           {__do_page_cache_readahead+335} {io_schedule+50}
           {__wait_on_bit_lock+104} {sync_page+0}
           {do_page_cache_readahead+97} {filemap_nopage+323}
           {__handle_mm_fault+1752} {do_page_fault+3657}
           {schedule_hrtimer+60} {hrtimer_nanosleep+96}
           {hrtimer_nanosleep+1} {error_exit+0}

To correct this problem, do one of the following

  * Move non-Hypertable memory consuming processes off of the RangeServer machines.
  * Reduce the memory consumption of the Hypertable RangeServer by reducing memory limit properties (either `Hypertable.RangeServer.MemoryLimit` or `Hypertable.RangeServer.MemoryLimit.Percentage`)

* * *

<a name="rsync_problem"></a>
**Q: Why am I getting these rsync errors when running ht_cluster?** `rsync: connection unexpectedly closed`

If when running ht_cluster commands such as `ht cluster dist` you see errors such as the following ...

    [uranos4.dq.isl.ntt.co.jp] ssh_exchange_identification:
    Connection closed by remote host
    [uranos4.dq.isl.ntt.co.jp] rsync: connection unexpectedly
    closed (0 bytes received so far) [receiver]
    [uranos4.dq.isl.ntt.co.jp]
    [uranos4.dq.isl.ntt.co.jp] rsync error: unexplained error
    (code 255) at io.c(453) [receiver=2.6.9]
    [uranos4.dq.isl.ntt.co.jp]

you are most likely encountering an sshd configuration issue that limits the number of simultaneous ssh connections to the machine from which you're running the ht_cluster commands from. See [SSH Connection Limit](misc/ssh_maxstartups.md) for instructions on how to solve this problem.

* * *

<a name="too_many_open_files"></a>
**Q: Why am I seeing these errors in the log files?** `Too many open files`

These errors can happen with any of the Hypertable processes. The following shows an example of errors in the Hypertable.Master.log file.

    1234563919 ERROR Hypertable.Master : (/usr/src/hypertable/src/cc/AsyncComm/IOHandlerAccept.cc:78) accept() failure: Too many open files
    1234563922 ERROR Hypertable.Master : (/usr/src/hypertable/src/cc/AsyncComm/IOHandlerAccept.cc:78) accept() failure: Too many open files
    1234563927 ERROR Hypertable.Master : (/usr/src/hypertable/src/cc/AsyncComm/IOHandlerAccept.cc:78) accept() failure: Too many open files

Most Unix systems have a limit on the number of open files (or sockets) allowed by a process. See [Open File Limit](misc/how_to_increase_open_file_limit.md) for instructions on how to increase this limit and eliminate these errors.

* * *

<a name="how_can_i_convert_unix_time"></a>
**Q: How can I convert log file Unix time (seconds since the Epoch) to something human readable?**

Add the following alias to your .bashrc file.

    alias lcat='perl -pe "s/^\d+/localtime($&)/e"'

After sourcing the `.bashrc` file (e.g. `source .bashrc`) or logging out and logging back in, you can see human readable timestamps on the Hypertable log files as follows.

    $ lcat Hypertable.RangeServer.log
    Wed Apr 15 00:00:14 2009 INFO Hypertable.RangeServer : (/usr/local/src/hypertable/src/cc/Hypertable/RangeServer/RangeServer.cc:2047) Memory Usage: 299447013 bytes
    Wed Apr 15 00:00:14 2009 INFO Hypertable.RangeServer : (/usr/local/src/hypertable/src/cc/Hypertable/RangeServer/RangeServer.cc:2104) Cleaning log (threshold=200000000)
    Wed Apr 15 00:00:34 2009 INFO Hypertable.RangeServer : (/usr/local/src/hypertable/src/cc/Hypertable/RangeServer/RangeServer.cc:2047) Memory Usage: 299447013 bytes
    Wed Apr 15 00:00:34 2009 INFO Hypertable.RangeServer : (/usr/local/src/hypertable/src/cc/Hypertable/RangeServer/RangeServer.cc:2104) Cleaning log (threshold=200000000)
    ...

* * *

<a name="ec2_problems"></a>
**Q: Why is Hypertable not coming up on EC2 (e.g. RangeServer unable to connect to Hyperspace)?**

If the Hypertable logs contain errors such as the following, indicating that the Hypertable processes are unable to connect to each other ...

    1248816365 ERROR Hypertable.RangeServer : (/foo/hypertable-0.9.2.4-alpha/src/cc/Hypertable/RangeServer/main.cc:82) Unable to connect to hyperspace, exiting...

you may need to open up ports on your EC2 hosts. To do this run something like the following.

    $ ec2-authorize $your-access-group -p 1-65000 -P tcp
    $ ec2-authorize $your-access-group -p 1-65000 -P udp

You can confirm your changes by examining the output of `ec2-describe-group`. Once you have confirmed this is the issue, you can tighten the port access restrictions by just opening up the ports used by hypertable (consult your config file).

* * *

<a name="clock_skew"></a>
**Q: Why am I seeing these error messages?** ` RANGE SERVER clock skew detected`

Hypertable requires that all machines participating in a Hypertable cluster have their clocks synchronized. The system uses Multi-Version Concurrency Control (MVCC) and by default will auto-assign revision numbers using a high resolution timestamp. These revision numbers are used for snapshot isolation as well as determining which portions of the commit log can be safely deleted. When clocks are significantly out-of-skew (e.g. several seconds), old results can suddenly appear in a query, or worse, when the system is brought down and back up again, data can go missing. In almost all circumstances, the system will detect clock skew and either refuse updates by throwing an exception up to the application,

    Failed: (3405054,ItemRank,9223372036854775810) - RANGE SERVER clock skew detected
    Failed: (3405054,ClickURL,9223372036854775810) - RANGE SERVER clock skew detected

or will log an error message in the range server log file:

    ** [out :: motherlode004] 1253227860 ERROR Hypertable.RangeServer : (/home/doug/src/hypertable/src/cc/Hypertable/RangeServer/RangeServer.cc:1554) RANGE SERVER clock skew detected 'Clocks skew of 20504726 microseconds exceeds maximum (3000000) range=query-log[1709153..197905]'
     ** [out :: motherlode004] 1253227867 ERROR Hypertable.RangeServer : (/home/doug/src/hypertable/src/cc/Hypertable/RangeServer/RangeServer.cc:1506) Exception caught: RANGE SERVER clock skew detected

To prevent this situation, use the [Network Time Protocol (ntp)](http://www.ntp.org/) to ensure that the clocks get synchronized and remain in sync. Run the 'date' command on all machines to make sure they are in sync. The following Capistrano shell session show the output of a cluster with properly synchronized clocks.

    cap> date
    [establishing connection(s) to motherlode000, motherlode001, motherlode002, motherlode003, motherlode004, motherlode005, motherlode006, motherlode007, motherlode008]
     ** [out :: motherlode001] Sat Jan  3 18:05:33 PST 2009
     ** [out :: motherlode002] Sat Jan  3 18:05:33 PST 2009
     ** [out :: motherlode003] Sat Jan  3 18:05:33 PST 2009
     ** [out :: motherlode004] Sat Jan  3 18:05:33 PST 2009
     ** [out :: motherlode005] Sat Jan  3 18:05:33 PST 2009
     ** [out :: motherlode007] Sat Jan  3 18:05:33 PST 2009
     ** [out :: motherlode006] Sat Jan  3 18:05:33 PST 2009
     ** [out :: motherlode000] Sat Jan  3 18:05:33 PST 2009
     ** [out :: motherlode008] Sat Jan  3 18:05:33 PST 2009

* * *

<a name="change_network_interface"></a>
**Q: How do I make Hypertable use a different network interface (`eth1` instead of `eth0`) ?**

Hypertable, by default, uses the machine's primary network interface. However, there are situations where the primary interface should not be used. For example, servers in Rackspace cloud (mosso.com) have two interfaces eth0 with public IP address and eth1 with private IP address (10.x.x.x). eth0 is the primary, but eth1 is preferred because the private network is twice as fast and traffic is not counted by billing system.

To configure Hypertable to use the interface eth1, add the following line to the config file, push it out to all nodes, and then restart Hypertable.

    Hypertable.Network.Interface=eth1

* * *

<a name="disk_is_filling_up_how_to_remedy"></a>
**Q: Hypertable logs are filling my disks, how can I remedy this?**

Add a cron job along the lines of the following.

    find /opt/hypertable/current/log/archive/* -mtime $keep_days -exec rm -rf {} +

* * *

<a name="what_firewall_ports_to_open"></a>
**Q: Firewall is blocking traffic, what ports should I open up?**

TCP: ``15863`, `15861`, `15862`, ``15864``, `15865`, `15867`, 15860`

UDP: ``15861` (in both directions)`

* * *

<a name="error_on_opensuse"></a>
**Q: Why am I seeing this error on OpenSUSE?** `ht-env.sh: line 105: 31207 Aborted (core dumped)`

When I try starting the servers on OpenSUSE, I get the error messages like the following.

    $ /opt/hypertable/current/bin/start-all-servers.sh local
    DFS broker: available file descriptors: 1024
    /opt/hypertable/current/bin/ht-env.sh: line 105: 31070 Aborted                 (core dumped) $HYPERTABLE_HOME/bin/serverup --silent "$@" &>/dev/null
    /opt/hypertable/current/bin/ht-env.sh: line 105: 31071 Aborted                 (core dumped) $HYPERTABLE_HOME/bin/serverup --silent "$@" &>/dev/null
    /opt/hypertable/current/bin/ht-env.sh: line 105: 31073 Aborted                 (core dumped) $HYPERTABLE_HOME/bin/serverup --silent "$@" &>/dev/null

On OpenSUSE, libstdc++ has a problem with regard to locale handling. In the shell in which you launch hypertable from, you'll need to execute the following command first.

    export LC_CTYPE=""

* * *

<a name="thriftbroker_framesize_error"></a>
**Q: Why am I seeing this exception in ThriftBroker log?** `org.apache.thrift.transport.TTransportException: Frame size (144130118) larger than max length (16384000)! `

This can happen when running HQL queries via Thrift over a large result set with millions of rows. In this situation use the [hql_exec](reference_manual/thrift_api.md#hqlexec) API and pass in _true_ for the 'unbuffered' argument. This will cause the API to return a scanner in the [HqlResult](reference_manual/thrift_api.md#hqlresult) return value which can be used to stream through the results.

In addition, the Java ThriftClient has an overloaded constructor which allows to specify the frame size. The default frame size is 16 MB, and the default timeout is 1600000 milliseconds. This example creates a ThriftClient with a maximum framesize of 20 MB:

`ThriftClient tc = ThriftClient.create("localhost", 38080, 1600000, true, 20 * 1024 * 1024);`

The Thrift frame size is also exposed to the MapReduce framework through the configuration setting hypertable.mapreduce.thriftclient.framesize.

* * *

<a name="negative_frame_size"></a>
**Q: Why is my java application throwing** `org.apache.thrift.transport.TTransportException: Read a negative frame size`

This error can occur when multiple threads in a java application share the same ThriftClient. This problem can be resolved by creating a dedicated ThriftClient per-thread.

* * *

<a name="out_of_sequence_response"></a>
**Q: Why is my java application throwing** `org.apache.thrift.TApplicationException: failed: out of sequence response`

This error can occur when multiple threads in a java application share the same ThriftClient. This problem can be resolved by creating a dedicated ThriftClient per-thread.

* * *

<a name="windows_port"></a>
**Q: Does Hypertable run on Microsoft Windows?**

Yes. There is a Windows port of Hypertable available at [ht4w - Hypertable for Windows](http://ht4w.softdev.ch/).

### Hadoop Specific

<a name="switching_to_cdh5_distro"></a>
**Q: How do I get Hypertable to run on top of CDH5?**

With the release of version 0.9.7.0, Hypertable can now run on most modern distributions of Hadoop. Cloudera CDH4 is the distribution that is configured by default. To switch to the CDH5 distribution, edit the HADOOP_DISTRO variable at the top of your cluster.def:

    HADOOP_DISTRO=cdh5

and then run the following command:

    ht cluster set_hadoop_distro

After making these changes, restart Hypertable

* * *

<a name="switching_to_hortonworks_distro"></a>
**Q: How do I run Hypertable on top of Hortonworks Hadoop distro?**

With the release of version 0.9.7.0, Hypertable can now run on most modern distributions of Hadoop. Cloudera CDH4 is the distribution that is configured by default. To switch to the Hortonworks Data Platform 2 distribution, edit the HADOOP_DISTRO variable at the top of your cluster.def:

    HADOOP_DISTRO=hdp2

and then run the following command:

    ht cluster set_hadoop_distro

After making these changes, restart Hypertable

* * *

<a name="dfs_broker_io_error"></a>
**Q: Why am I seeing this error message in the DFSBroker.hadoop.log?** `mkdirs DFS directory /hypertable/servers/rs1/log/user - DFS BROKER i/o error`

Hypertable persists all of its state in the DFS under the directory /hypertable. This directory needs to exist and be writeable by the Hypertable server processes. To do this in HDFS, run the following commands in the same user account that was used to start the HDFS server processes.

    sudo -u hdfs hadoop fs -mkdir /hypertable
    sudo -u hdfs hadoop fs -chmod 777 /hypertable

* * *

<a name="class_not_found_pipemaprunner"></a>
**java.lang.ClassNotFoundException: Class org.apache.hadoop.streaming.PipeMapRunner not found**

This is caused by running a MapReduce version 1 (MRv1) streaming job using the Yarn MapReduce streaming jar file. The full error output looks something like this:

    15/02/09 23:08:57 INFO mapred.JobClient: Task Id : attempt_201502092222_0001_m_000032_2, Status : FAILED
    java.lang.RuntimeException: java.lang.RuntimeException: java.lang.ClassNotFoundException: Class org.apache.hadoop.streaming.PipeMapRunner not found
            at org.apache.hadoop.conf.Configuration.getClass(Configuration.java:1806)
            at org.apache.hadoop.mapred.JobConf.getMapRunnerClass(JobConf.java:1061)
            at org.apache.hadoop.mapred.MapTask.runOldMapper(MapTask.java:413)
            at org.apache.hadoop.mapred.MapTask.run(MapTask.java:332)
            at org.apache.hadoop.mapred.Child$4.run(Child.java:268)
            at java.security.AccessController.doPrivileged(Native Method)
            at javax.security.auth.Subject.doAs(Subject.java:396)
            at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1438)
            at org.apache.hadoop.mapred.Child.main(Child.java:262)
    Caused by: java.lang.RuntimeException: java.lang.ClassNotFoundException: Class org.apache.hadoop.streaming.PipeMapRunner not found
            at org.apache.hadoop.conf.Configuration.getClass(Configuration.java:1774)
            at org.apache.hadoop.conf.Configuration.getClass(Configuration.java:1798)

To remedy this problem, run the job with the MRv1 streaming jar file. For example:

    hadoop jar $CDH_HOME/lib/hadoop-0.20-mapreduce/contrib/streaming/hadoop-streaming-2.0.0-mr1-cdh4.7.0.jar ...

* * *

<a name="all_datanodes_are_bad"></a>
**java.io.IOException: All datanodes X.X.X.X:50010 are bad. Aborting...**

This message may appear in the FsBroker log after Hypertable has been under heavy load. It is usually unrecoverable and requires a restart of Hypertable to clear up. The appearance of this error usually indicates sub-optimal kernel configuration on the Hypertable server machines. See [Linux Kernel Configuration](misc/linux_kernel_configuration.md) for instructions on how to configure the kernel on your Hypertable machines to make this problem go away.

* * *

<a name="failed_to_add_datanode"></a>
**java.io.IOException: Failed to add a datanode.**

This message may appear in the FsBroker.local.log file if you have an imbalance in the DataNode data directories (dfs.data.dir). For example, if you have one large disk and a number of smaller disks that are full, you may encounter this error. You will also see the following error in the Hadoop DataNode log files.

    org.apache.hadoop.util.DiskChecker$DiskOutOfSpaceException: No space left on device

To remedy this, add the following property to your hdfs-site.xml file and push the change out to all DataNodes.

    <property>
      <name>dfs.datanode.fsdataset.volume.choosing.policy</name>
      <value>
        org.apache.hadoop.hdfs.server.datanode.fsdataset.AvailableSpaceVolumeChoosingPolicy
      </value>
    </property>

Then restart HDFS and Hypertable.
