# Configuration Properties

###

* * *

`CephBroker.MonAddr`

Ceph monitor address to connect to

* * *

`CephBroker.Port`

Port number on which to listen (read by CephBroker only)

* * *

`CephBroker.Workers`

Number of Ceph broker worker threads created, maybe

**Default Value:** 20

* * *

`Comm.DispatchDelay`

[TESTING ONLY] Delay dispatching of read requests by this number of milliseconds

**Default Value:** 0

* * *

`Comm.UsePoll`

Use poll() interface

**Default Value:** false

* * *

`FsBroker.DisableFileRemoval`

Rename files with .deleted extension instead of removing (for testing)

**Default Value:** false

* * *

`FsBroker.Hdfs.NameNode.Host`

Name of host on which HDFS NameNode is running (NOTE: this property is deprecated, use `HdfsBroker.Hadoop.ConfDir` instead)

**Default Value:** default

* * *

`FsBroker.Hdfs.NameNode.Port`

Port number on which HDFS NameNode is running (NOTE: this property is deprecated, use `HdfsBroker.Hadoop.ConfDir` instead)

**Default Value:** 0

* * *

`FsBroker.Host`

Host on which the FS broker is running (read by clients only)

**Default Value:** localhost

* * *

`FsBroker.Local.DirectIO`

Read and write files using direct i/o

**Default Value:** false

* * *

`FsBroker.Local.Port`

Port number on which to listen (read by LocalBroker only)

**Default Value:** 15863

* * *

`FsBroker.Local.Reactors`

Number of local broker communication reactor threads created

* * *

`FsBroker.Local.Root`

Root of file and directory hierarchy for local broker (if relative path, then is relative to the Hypertable data directory root)

* * *

`FsBroker.Local.Workers`

Number of local broker worker threads created

**Default Value:** 20

* * *

`FsBroker.Port`

Port number on which FS broker is listening (read by clients only)

**Default Value:** 15863

* * *

`FsBroker.Timeout`

Length of time, in milliseconds, to wait before timing out FS Broker requests. This takes precedence over Hypertable.Request.Timeout

* * *

`HdfsBroker.Hadoop.ConfDir`

Hadoop configuration directory (e.g. /etc/hadoop/conf or /usr/lib/hadoop/conf)

* * *

`HdfsBroker.Port`

Port number on which to listen (read by HdfsBroker only)

* * *

`HdfsBroker.Reactors`

Number of HDFS broker communication reactor threads created

* * *

`HdfsBroker.Workers`

Number of HDFS broker worker threads created

* * *

`HdfsBroker.fs.default.name`

Hadoop Filesystem default name, same as fs.default.name property in Hadoop config (e.g. hdfs://localhost:9000) (NOTE: this property is deprecated, use `HdfsBroker.Hadoop.ConfDir` instead)

* * *

`Hyperspace.Checkpoint.Size`

Run BerkeleyDB checkpoint when logs exceed this size limit

**Default Value:** 1000000

* * *

`Hyperspace.Client.Datagram.SendPort`

Client UDP send port for keepalive packets

**Default Value:** 0

* * *

`Hyperspace.GracePeriod`

Hyperspace Grace period (see Chubby paper)

**Default Value:** 60000

* * *

`Hyperspace.KeepAlive.Interval`

Hyperspace Keepalive interval (see Chubby paper)

**Default Value:** 10000

* * *

`Hyperspace.Lease.Interval`

Hyperspace Lease interval (see Chubby paper)

**Default Value:** 60000

* * *

`Hyperspace.LogGc.Interval`

Check for unused BerkeleyDB log files after this much time

**Default Value:** 60000

* * *

`Hyperspace.LogGc.MaxUnusedLogs`

Number of unused BerkeleyDB to keep around in case of lagging replicas

**Default Value:** 200

* * *

`Hyperspace.Maintenance.Interval`

Hyperspace maintenance interval (checkpoint BerkeleyDB, log cleanup etc)

**Default Value:** 60000

* * *

`Hyperspace.Replica.Dir`

Root of hyperspace file and directory heirarchy in local filesystem (if relative path, then is relative to the Hypertable data directory root)

* * *

`Hyperspace.Replica.Host`

Hostname of Hyperspace replica

* * *

`Hyperspace.Replica.Port`

Port number on which Hyperspace is or should be listening for requests

**Default Value:** 15861

* * *

`Hyperspace.Replica.Reactors`

Number of Hyperspace Master communication reactor threads created

* * *

`Hyperspace.Replica.Replication.Port`

Hyperspace replication port

**Default Value:** 15862

* * *

`Hyperspace.Replica.Replication.Timeout`

Hyperspace replication master dies if it doesn't receive replication acknowledgement within this period

**Default Value:** 10000

* * *

`Hyperspace.Replica.Workers`

Number of Hyperspace Replica worker threads created

**Default Value:** 20

* * *

`Hyperspace.Session.Reconnect`

Reconnect to Hyperspace on session expiry

**Default Value:** false

* * *

`Hyperspace.Timeout`

Timeout (millisec) for hyperspace requests (preferred to Hypertable.Request.Timeout

**Default Value:** 30000

* * *

`Hypertable.Client.Workers`

Number of client worker threads created

**Default Value:** 20

* * *

`Hypertable.Cluster.Name`

Name of cluster used in Monitoring UI and admin notification messages

* * *

`Hypertable.CommitLog.Compressor`

Commit log compressor to use (zlib, lzo, quicklz, snappy, bmz, none)

**Default Value:** quicklz

* * *

`Hypertable.CommitLog.RollLimit`

Roll commit log (close current fragment file and create a new one) after writing this many bytes

**Default Value:** 100000000

* * *

`Hypertable.CommitLog.SkipErrors`

Skip over any corruption encountered in the commit log

**Default Value:** false

* * *

`Hypertable.Connection.Retry.Interval`

Average time, in milliseconds, between connection retry atempts

**Default Value:** 10000

* * *

`Hypertable.DataDirectory`

Hypertable data directory root

**Default Value:** Top-level installation directory

* * *

`Hypertable.Directory`

Top-level hypertable directory name

**Default Value:** hypertable

* * *

`Hypertable.Failover.GracePeriod`

Master will wait this many milliseconds before trying to recover a RangeServer

**Default Value:** 30000

* * *

`Hypertable.Failover.Quorum.Percentage`

Percentage of live RangeServers required for failover to proceed

**Default Value:** 90

* * *

`Hypertable.Failover.RecoverInSeries`

Carry out USER log recovery for failed servers in series

**Default Value:** false

* * *

`Hypertable.Failover.Timeout`

Timeout (milliseconds) for failover operations

**Default Value:** 300000

* * *

`Hypertable.HqlInterpreter.Mutator.NoLogSync`

Suspends CommitLog sync operation on updates until command completion

**Default Value:** false

* * *

`Hypertable.LoadBalancer.BalanceDelay.Initial`

Amount of time (seconds) to wait after start up before running balancer

**Default Value:** 86400

* * *

`Hypertable.LoadBalancer.BalanceDelay.NewServer`

Amount of time (seconds) to wait before running balancer when a new RangeServer is detected

**Default Value:** 60

* * *

`Hypertable.LoadBalancer.Crontab`

Crontab entry to control when load balancer is run

**Default Value:** 0 0 * * *

* * *

`Hypertable.LoadBalancer.Enable`

Enable automatic load balancing

**Default Value:** true

* * *

`Hypertable.LoadBalancer.LoadavgThreshold`

Servers with loadavg above this much above the mean will be considered by the load balancer to be overloaded

**Default Value:** 0.25

* * *

`Hypertable.LoadMetrics.Interval`

Period of time, in seconds, between writing metrics to sys/RS_METRICS

**Default Value:** 3600

* * *

`Hypertable.LocationCache.MaxEntries`

Size of range location cache in number of entries

**Default Value:** 1000000

* * *

`Hypertable.Logging.Level`

Set system wide logging level (default: info)

**Default Value:** info

* * *

`Hypertable.Master.DiskThreshold.Percentage`

Stop assigning ranges to RangeServers if disk usage is above this threshold

**Default Value:** 90

* * *

`Hypertable.Master.Gc.Interval`

Garbage collection interval in milliseconds by Master

**Default Value:** 300000

* * *

`Hypertable.Master.Host`

Host on which Hypertable Master is running

* * *

`Hypertable.Master.Locations.IncludeMasterHash`

Includes master hash (host:port) in RangeServer location id

**Default Value:** false

* * *

`Hypertable.Master.NotificationInterval`

Notification interval (in seconds) of abnormal state

**Default Value:** 3600

* * *

`Hypertable.Master.Port`

Port number on which Hypertable Master is or should be listening

**Default Value:** 15864

* * *

`Hypertable.Master.Reactors`

Number of Hypertable Master communication reactor threads created

* * *

`Hypertable.Master.Split.SoftLimitEnabled`

Enable aggressive splitting of tables with little data to spread out ranges

**Default Value:** true

* * *

`Hypertable.Master.Workers`

Number of Hypertable Master worker threads created

**Default Value:** 100

* * *

`Hypertable.MetaLog.SkipErrors`

Skipping errors instead of throwing exceptions on metalog errors

**Default Value:** false

* * *

`Hypertable.Metadata.Replication`

Replication factor for commit log files

**Default Value:** -1

* * *

`Hypertable.Metrics.Ganglia.Disable`

Disable publishing of metrics to Ganglia

**Default Value:** false

* * *

`Hypertable.Metrics.Ganglia.Port`

UDP Port on which Hypertable gmond python extension module listens for metrics

**Default Value:** 15860

* * *

`Hypertable.Monitoring.Disable`

Disables the generation of monitoring statistics

**Default Value:** false

* * *

`Hypertable.Monitoring.Interval`

Monitoring statistics gathering interval (in milliseconds)

**Default Value:** 30000

* * *

`Hypertable.Mutator.FlushDelay`

Number of milliseconds to wait prior to flushing scatter buffers (for testing)

**Default Value:** 0

* * *

`Hypertable.Mutator.ScatterBuffer.FlushLimit.Aggregate`

Amount of updates (bytes) accumulated for all servers to trigger a scatter buffer flush

**Default Value:** 50000000

* * *

`Hypertable.Mutator.ScatterBuffer.FlushLimit.PerServer`

Amount of updates (bytes) accumulated for a single server to trigger a scatter buffer flush

**Default Value:** 10000000

* * *

`Hypertable.Network.Interface`

Use this interface for network communication

* * *

`Hypertable.RangeLocator.MaxErrorQueueLength`

Maximum numbers of errors to be stored

**Default Value:** 4

* * *

`Hypertable.RangeLocator.MetadataReadaheadCount`

Number of rows that the RangeLocator fetches from the METADATA

**Default Value:** 10

* * *

`Hypertable.RangeLocator.MetadataRetryInterval`

Retry interval when connecting to a RangeServer to fetch metadata

**Default Value:** 3000

* * *

`Hypertable.RangeLocator.RootMetadataRetryInterval`

Retry interval when connecting to the Root RangeServer

**Default Value:** 3000

* * *

`Hypertable.RangeServer.AccessGroup.CellCache.PageSize`

Page size for CellCache pool allocator

**Default Value:** 524288

* * *

`Hypertable.RangeServer.AccessGroup.CellCache.ScannerCacheSize`

CellCache scanner cache size

**Default Value:** 1024

* * *

`Hypertable.RangeServer.AccessGroup.GarbageThreshold.Percentage`

Perform major compaction when garbage accounts for this percentage of the data

**Default Value:** 20

* * *

`Hypertable.RangeServer.AccessGroup.MaxMemory`

Maximum bytes consumed by an Access Group

**Default Value:** 1000000000

* * *

`Hypertable.RangeServer.AccessGroup.ShadowCache`

Enable CellStore shadow caching

**Default Value:** false

* * *

`Hypertable.RangeServer.BlockCache.Compressed`

Controls whether or not block cache stores compressed blocks

**Default Value:** true

* * *

`Hypertable.RangeServer.BlockCache.MaxMemory`

Maximum (target) size of block cache

**Default Value:** -1 (all available RAM)

* * *

`Hypertable.RangeServer.BlockCache.MinMemory`

Minimum size of block cache

**Default Value:** 0

* * *

`Hypertable.RangeServer.CellStore.DefaultBlockSize`

Default block size for cell stores

**Default Value:** 65536

* * *

`Hypertable.RangeServer.CellStore.DefaultBloomFilter`

Default bloom filter for cell stores

**Default Value:** rows

* * *

`Hypertable.RangeServer.CellStore.DefaultCompressor`

Default compressor for cell stores

**Default Value:** snappy

* * *

`Hypertable.RangeServer.CellStore.Merge.RunLengthThreshold`

Trigger a merge if an adjacent run of merge candidate CellStores exceeds this length

**Default Value:** 5

* * *

`Hypertable.RangeServer.CellStore.SkipBad`

Skip over corrupt cell stores.

**NOTE:** This property should only be used in certain disaster recovery scenarios, such as when the filesystem has become corrupt. This property leads to leaked files and hides the extent of the data loss. It is better to manually remove corrupt files and use the [Hypertable.RangeServer.CellStore.SkipNotFound](configuration_properties.md#Hypertable.RangeServer.CellStore.SkipNotFound) to skip over them.

**Default Value:** false

* * *

[ ](configuration_properties.md#Hypertable.RangeServer.CellStore.SkipNotFound)

`Hypertable.RangeServer.CellStore.SkipNotFound`

Skip over cell stores that are non-existent

**Default Value:** false

* * *

`Hypertable.RangeServer.CellStore.TargetSize.Minimum`

Merging compaction target CellStore size during normal activity period

**Default Value:** 10MB

* * *

`Hypertable.RangeServer.CellStore.TargetSize.Maximum`

Merging compaction target CellStore size during low activity period

**Default Value:** 50MB

* * *

`Hypertable.RangeServer.ClockSkew.Max`

Maximum amount of clock skew (microseconds) the system will tolerate

**Default Value:** 3000000

* * *

`Hypertable.RangeServer.CommitInterval`

Default minimum group commit interval in milliseconds

**Default Value:** 50

* * *

`Hypertable.RangeServer.CommitLog.Compressor`

Commit log compressor to use (zlib, lzo, quicklz, snappy, bmz, none)

**Default Value:** quicklz

* * *

`Hypertable.RangeServer.CommitLog.DfsBroker.Host`

Host of FS Broker to use for Commit Log

* * *

`Hypertable.RangeServer.CommitLog.DfsBroker.Port`

Port of FS Broker to use for Commit Log

* * *

`Hypertable.RangeServer.CommitLog.FragmentRemoval.RangeReferenceRequired`

Only remove linked log fragments if they're part of a transfer log referenced by a range

**Default Value:** true

* * *

`Hypertable.RangeServer.CommitLog.PruneThreshold.Max`

Upper threshold for amount of outstanding commit log before pruning

* * *

`Hypertable.RangeServer.CommitLog.PruneThreshold.Max.MemoryPercentage`

Upper threshold in terms of % RAM for amount of outstanding commit log before pruning

**Default Value:** 50

* * *

`Hypertable.RangeServer.CommitLog.PruneThreshold.Min`

Lower threshold for amount of outstanding commit log before pruning

**Default Value:** 1000000000

* * *

`Hypertable.RangeServer.ControlFile.CheckInterval`

Minimum time interval (milliseconds) to check for control files in run/ directory

**Default Value:** 30000

* * *

`Hypertable.RangeServer.Data.DefaultReplication`

Default replication for data

**Default Value:** -1

* * *

`Hypertable.RangeServer.Failover.FlushLimit.Aggregate`

Amount of updates (bytes) accumulated for all range to trigger a replay buffer flush

**Default Value:** 100000000

* * *

`Hypertable.RangeServer.Failover.FlushLimit.PerRange`

Amount of updates (bytes) accumulated for a single range to trigger a replay buffer flu\ sh

**Default Value:** 10000000

* * *

`Hypertable.RangeServer.IgnoreClockSkewErrors`

Ignore clock skew errors

**Default Value:** false

* * *

`Hypertable.RangeServer.LoadSystemTablesOnly`

Instructs the RangeServer to only load system tables (for debugging)

**Default Value:** false

* * *

`Hypertable.RangeServer.LowMemoryLimit.Percentage`

Amount of memory to free in low memory condition as percentage of RangeServer memory limit

**Default Value:** 10

* * *

`Hypertable.RangeServer.LowActivityPeriod`

Crontab-style entry specifying the low activity period. This property can be specified multiple times to specify multiple low activity periods. The RangeServer performs more aggressive maintenance during this period.

**Default Value:** * 2-4 * * *

* * *

`Hypertable.RangeServer.Maintenance.Interval`

Maintenance scheduling interval in milliseconds

**Default Value:** 30000

* * *

`Hypertable.RangeServer.Maintenance.LowMemoryPrioritization`

Use low memory prioritization algorithm for freeing memory in low memory mode

**Default Value:** true

* * *

`Hypertable.RangeServer.Maintenance.MaxAppQueuePause`

Each time application queue is paused, keep it paused for no more than this many milliseconds

**Default Value:** 120000

* * *

`Hypertable.RangeServer.Maintenance.MergesPerInterval`

Limit on number of merging tasks to create per maintenance interval

* * *

`Hypertable.RangeServer.Maintenance.MergingCompaction.Delay`

Millisecond delay before scheduling merging compactions in non-low memory mode

**Default Value:** 900000

* * *

`Hypertable.RangeServer.Maintenance.MoveCompactionsPerInterval`

Limit on number of major compactions due to move per maintenance interval

**Default Value:** 2

* * *

`Hypertable.RangeServer.Maintenance.InitializationPerInterval`

Limit on number of initialization tasks to create per maintenance interval

* * *

`Hypertable.RangeServer.MaintenanceThreads`

Number of maintenance threads. Default is max(1.5*drive-count, number-of-cores).

* * *

`Hypertable.RangeServer.MemoryLimit`

Absolute RangeServer memory limit

* * *

`Hypertable.RangeServer.MemoryLimit.EnsureUnused`

Amount of unused physical memory

* * *

`Hypertable.RangeServer.MemoryLimit.EnsureUnused.Percentage`

Amount of unused physical memory specified as percentage of physical RAM

* * *

`Hypertable.RangeServer.MemoryLimit.Percentage`

RangeServer memory limit specified as percentage of physical RAM

**Default Value:** 60

* * *

`Hypertable.RangeServer.Monitoring.DataDirectories`

Comma-separated list of directory mount points of disk volumes to monitor

**Default Value:** /

* * *

`Hypertable.RangeServer.Port`

Port number on which range servers are or should be listening

**Default Value:** 15865

* * *

`Hypertable.RangeServer.ProxyName`

Use this value for the proxy name (if set) instead of reading from run dir.

**Default Value:**

* * *

`Hypertable.RangeServer.QueryCache.EnableMutexStatistics`

Enables waiter statistics on query cache mutex

**Default Value:** true

* * *

`Hypertable.RangeServer.QueryCache.MaxMemory`

Maximum size of query cache

**Default Value:** 50000000

* * *

`Hypertable.RangeServer.Range.MaximumSize`

Maximum size of a range in bytes before updates get throttled

**Default Value:** 3000000000

* * *

`Hypertable.RangeServer.Range.MetadataSplitSize`

Size of METADATA range in bytes before splitting (for testing)

* * *

`Hypertable.RangeServer.Range.RowSize.Unlimited`

Marks range active and unsplittable upon encountering row overflow condition. Can cause ranges to grow extremely large. Use with caution!

**Default Value:** false

* * *

`Hypertable.RangeServer.Range.SplitOff`

Portion of range to split off (high or low)

**Default Value:** high

* * *

`Hypertable.RangeServer.Range.SplitSize`

Size of range in bytes before splitting

**Default Value:** 536870912

* * *

`Hypertable.RangeServer.Range.RowSize.Unlimited`

Marks range active and unsplittable upon encountering row overflow condition. Can cause ranges to grow extremely large. Use with caution!

**Default Value:** false

* * *

`Hypertable.RangeServer.Reactors`

Number of Range Server communication reactor threads created

* * *

`Hypertable.RangeServer.ReadyStatus`

Status code indicating RangeServer is ready for operation. By setting this property to `OK` the RangeServer startup script will wait until all deferred initialization (loading of CellStores) is complete, before returning.

**Default Value:** WARNING

* * *

`Hypertable.RangeServer.Scanner.BufferSize`

Size of transfer buffer for scan results

**Default Value:** 1000000

* * *

`Hypertable.RangeServer.Scanner.Ttl`

Number of milliseconds of inactivity before destroying scanners

**Default Value:** 1800000

* * *

`Hypertable.RangeServer.Testing.MaintenanceNeeded.PauseInterval`

TESTING: After update, if range needs maintenance, pause for this number of milliseconds

**Default Value:** 0

* * *

`Hypertable.RangeServer.Timer.Interval`

Timer interval in milliseconds (reaping scanners, purging commit logs, etc.)

**Default Value:** 20000

* * *

`Hypertable.RangeServer.UpdateCoalesceLimit`

Amount of update data to coalesce into single commit log sync

**Default Value:** 5000000

* * *

`Hypertable.RangeServer.UpdateDelay`

Number of milliseconds to wait before carrying out an update (TESTING)

**Default Value:** 0

* * *

`Hypertable.RangeServer.Workers`

Number of Range Server worker threads created

**Default Value:** 50

* * *

`Hypertable.Request.Timeout`

Length of time, in milliseconds, before timing out requests (system wide)

**Default Value:** 600000

* * *

`Hypertable.Scanner.QueueSize`

Size of Scanner ScanBlock queue

**Default Value:** 5

* * *

`Hypertable.Silent`

Disable verbose output (system wide)

**Default Value:** false

* * *

`Hypertable.Verbose`

Enable verbose output (system wide)

**Default Value:** false

* * *

`Qfs.Broker.Reactors`

Number of QFS broker reactor threads

* * *

`Qfs.Broker.Workers`

Number of worker threads for QFS broker

**Default Value:** 20

* * *

`Qfs.MetaServer.Name`

Hostname of QFS meta server

**Default Value:** localhost

* * *

`Qfs.MetaServer.Port`

Port number for QFS meta server

**Default Value:** 20000

* * *

`ThriftBroker.API.Logging`

Enable or disable Thrift API logging

**Default Value:** false

* * *

`ThriftBroker.Future.Capacity`

Capacity of result queue (in bytes) for Future objects

**Default Value:** 50000000

* * *

`ThriftBroker.Hyperspace.Session.Reconnect`

ThriftBroker will reconnect to Hyperspace on session expiry

**Default Value:** true

* * *

`ThriftBroker.Mutator.FlushInterval`

Maximum flush interval in milliseconds

**Default Value:** 1000

* * *

`ThriftBroker.NextThreshold`

Total size threshold for (size of cell data) for thrift broker next calls

**Default Value:** 512000

* * *

`ThriftBroker.Port`

Port number for thrift broker

**Default Value:** 15867

* * *

`ThriftBroker.SlowQueryLog.Enable`

Enable slow query logging

**Default Value:** false

* * *

`ThriftBroker.SlowQueryLog.LatencyThreshold`

Latency threshold (ms) above which a query is considered slow

**Default Value:** 10000

* * *

`ThriftBroker.Timeout`

Timeout (ms) for thrift broker

* * *

`ThriftBroker.Workers`

Number of worker threads for thrift broker

**Default Value:** 50
