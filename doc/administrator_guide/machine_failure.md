# Machine Failure

This document describes how Hypertable handles failure of its various components.

## Table of Contents

### RangeServer

Hypertable continuously monitors and reacts to RangeServer failures. When a RangeServer fails, the Master will orchestrate a recovery procedure that involves logically removing the server from the system and re-assigning the ranges that it was managing to other RangeServers. The system can withstand the loss of **any** range server, even the ones holding the ROOT or other METADATA ranges. The Master is notified of a range server failure when the RangeServer loses its Hyperspace session, which means it can detect any kind of Range Server failure, even cases where a server silently drops off the network. Aside from a transient delay in database access, RangeServer failure and recovery is  _completely transparent_ to client applications, whether they're Thrift-based or native. There are two configuration properties that control the behavior of failure recovery:

[`Hypertable.Failover.GracePeriod`](../reference_manual/configuration_properties.md#Hypertable.Failover.GracePeriod) \- The Master will wait this many milliseconds before trying to recover a RangeServer. If you are doing testing on your Hypertable cluster that involves manual stopping and restarting of RangeServers, you can increase this value to prevent unintended RangeServer failover. If you need lower-latency recovery, this property can be set to a smaller value. The default value for this property is 30000.

[`Hypertable.Failover.Quorum.Percentage`](../reference_manual/configuration_properties.md#Hypertable.Failover.Quorum.Percentage) \- Percentage of live RangeServers required for failover to proceed. If your system cannot handle the failure of some percentage of RangeServers, you can tune this parameter to prevent failover from taking place under this circumstance. The system will notify the administrator of this situation via the notification script (see below), giving the administrator the opportunity to manually intervene and replace the servers. The default value for this property is 90.

The Master will send out a notification when it discovers a RangeServer failure and when it successfully recovers the server. It will also send out an error notification if recover cannot proceed due to a filesystem problem or `Hypertable.Failover.Quorum.Percentage` constraint violation. See [Notification Script](notification_script.md) for details on how to setup and install a notification script.

### Master

Hypertable has a single Master process. To achieve high availability, the Master can be started on mulitple machines. When these Master processes come up they will try to acquire a lock on a file (`/hypertable/master`) in Hyperspace. Whichever process acquires the lock becomes the Master. The other Master processes will enter a lock acquisition retry loop, ready to take over should the current Master fail for whatever reason. Aside from a transient delay in any in-progress Master operation, Master failover is _completely transparent_ to client applications, whether they're Thrift-based or native. To configure your system with standby Masters, edit the _master_ role at the top of your _cluster.def_ file to include more than one machine that can act as the Master:

    role: master master1, master2

### Hyperspace

Hyperspace is an internal service that acts as a highly available lock manager and provides a file system for storing small amounts of system metadata. Loss of Hyperspace can result in catastrophic loss of your database, so we recommend that you run multiple Hyperspace replicas. To do so, edit the hyperspace role at the top of your _cluster.def_ file to include multiple machines to run Hyperspace replicas:

    role: hyperspace hyperspace1, hyperspace2, hyperspace3

When the system comes up, one of the hyperspace machines will be elected master and the others will act as slaves and will maintain an exact replica of the Hyperspace database. Loss of the elected Hyperspace master is currently not handled transparently. To recover from a loss of the Hyperspace master, stop Hypertable (e.g. `ht cluster stop`), remove the failed machine from the hyperspace role at the top of your _cluster.def_ file, for example:

    role: hyperspace hyperspace2, hyperspace3

and then restart the system (e.g. `ht cluster start`).
