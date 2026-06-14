# HDFS and Durability

Hypertable offers what's known as _durability_. Once a write completes and success is reported back to the client, that write can be guaranteed to be reflected in all subsequent operations. This durability guarantee, however, comes at a cost of performance. HDFS offers a number of APIs that let you control the "durability level" of writes. Through a set of configuration properties, Hypertable can be tuned to favor guaranteed durability over performance and vice-versa.

### HDFS hflush(), hsync(), and SYNC_BLOCK

For much of its history, HDFS has favored performance over guaranteed durability. When a file was closed or flushed, the file contents were written from the DataNode into the operating system using the normal `close()` and `write()` system calls. The problem with this approach, as far as durability is concerned, is that it only guarantees that the data will move from the DataNode into the operating system. The data may not be immediately persisted to the underlying physical storage, but may still reside in-memory in the operating system's file cache. This creates a window of vulnerability where if multiple DataNode machines fail simultaneously (e.g. loss of power to a rack), then previously written data may be lost. To combat this problem, HDFS (as of Hadoop 2.0) has introduced new APIs to provide a way to guarantee that written data will be immediately persisted to the underlying physical storage. These APIs are described in the following table.

API |  Description
---|---
` SYNC_BLOCK ` |  This is a file open flag that causes the DFSClient to set a _sync_ flag on the last packet of a block. This causes the block file to be fsync'ed (persisted to underlying storage) upon close.
` hflush()` |  This API flushes all outstanding data (i.e. the current unfinished packet) from the client into the OS buffers on all DataNode replicas.
` hsync()` |  This API flushes the data to the DataNodes, like hflush(), but should also force the data to underlying physical storage via fsync (or equivalent).

### Hypertable Properties

As of the 0.9.8.8 release of Hypertable, `SYNC_BLOCK` can be supplied as an open flag to all files and commit log writes can be flushed with either `hsync()` or `hflush()`. Three new properties have been introduced to provide control over the use of these APIs which are described below.

* * *

`HdfsBroker.SyncBlock`

Pass `SYNC_BLOCK` flag to Filesystem.create() when creating files

**Default Value:** true

* * *

`Hypertable.LogFlushMethod.Meta`

This is a string property that can take either the value FLUSH or SYNC. It controls the flush method for writes to the METADATA commit log. When running Hypertable on top of HDFS, a value of FLUSH causes `hflush()` to be used and a value of SYNC causes `hsync()` to be used.

**Default Value:** SYNC

* * *

`Hypertable.LogFlushMethod.User`

This is a string property that can take either the value FLUSH or SYNC. It controls the flush method for writes to the USER (non-system table) commit log. When running Hypertable on top of HDFS, a value of FLUSH causes `hflush()` to be used and a value of SYNC causes `hsync()` to be used.

**Default Value:** FLUSH

### Guaranteeing Durability

As can be seen by the default values of the properties listed in the previous section, by default, durability is only guaranteed when complete file blocks are written, when files are closed, and for each METADATA commit log write. Writes to the USER (non-system table) commit log are not guaranteed to be durable. If a 100% durability is required for your deployment, you can configure Hypertable to offer a durability guarantee to USER commit log writes by adding the following property setting to your Hypertable config file:

    Hypertable.LogFlushMethod.User=SYNC

### Trading Durability for Performance

The durability problem that can happen when flushing writes with `hflush()` and not providing the `SYNC_BLOCK` flag to file open calls only arises in the event of a simultaneous failure of a large number (i.e. 3 or more) of DataNode machines. This can happen, for example, when power to an entire rack is lost. If performance is critical for your deployment and you're ok with repairing your database (or re-installing) in the event of simultaneous machine failure, you can tune Hypertable for maximum write performance by adding the following property settings to your Hypertable config file:

    HdfsBroker.SyncBlock=false
    Hypertable.LogFlushMethod.Meta=FLUSH

**NOTE:** This is the default behavior for pre-0.9.8.8 versions of Hypertable.
