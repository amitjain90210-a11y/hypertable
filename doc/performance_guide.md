# Performance Guide

This guide contains various topics on how to maximize the performance you get out of Hypertable.

## Table of Contents

### Bypassing Commit Log (WAL) Writes

This feature provides a way to significantly increase bulk loading performance by bypassing writes to the commit log (WAL). The benefit comes at a cost of data loss vulnerability while loading is taking place.

When data is written into Hypertable, it first gets written to a commit log (also known as write-ahead log or WAL) in the underlying filesystem and then is inserted into in-memory data structures called CellCaches. The reason for writing the data to the commit log is so that if a machine fails, or the system is restarted, the contents of the in-memory CellCaches can be reconstructed. Over time, the in-memory CellCaches get written out to on-disk files called CellStores. So, in general, the Hypertable design involves writing each piece of data at least twice to disk, once to the commit log and again to the initial CellStores. Since writing to the file system is expensive (e.g. HDFS writes are typically performend on three replicas), bypassing writes to the commit log can significantly increase bulk loading performance. The downside to bypassing commit log writes is that if a RangeServer fails during the load or Hypertable is restarted, some of the loaded data may be lost. This data loss window of vulnerability exists while data is being loaded and lasts until the table, into which it is being loaded, gets manually compacted. If the probability of RangeServer failure during a load is low, the risk may well be worth it. If a RangeServer does fail during the window of vulnerability, the data will have to be reloaded to ensure that it all makes it into the database.

**LOAD DATA INFILE**

The HQL command `LOAD DATA INFILE` accepts an option, _NO_LOG_ , that causes writes to the commit log to be bypassed. After successfully loading data with the NO_LOG option, the table in which the data was loaded should be compacted in order to close data loss window of vulnerability. For example:

    LOAD DATA INFILE **NO_LOG** 'data.tsv' INTO TABLE MyTable;
    COMPACT TYPE=MINOR TABLE MyTable;

**Thrift API**

Bypassing writes to the commit log can be programatically enabled by passing a flag to the [mutator_open](../reference_manual/thrift_api.md#mutatoropen) and [async_mutator_open](../reference_manual/thrift_api.md#asyncmutatoropen) Thrift APIs. The following code snippet illustrates how to do this in Java:

    ThriftClient client = ThriftClient.create("localhost", 15867);
    long ns = client.namespace_open("/");
    long mutator = client.mutator_open(ns, "MyTable", MutatorFlag.NO_LOG.getValue(), 0);

To close the data loss window of vulnerability, a manual compaction of _MyTable_ should be performed with the HQL [COMPACT](../reference_manual/hql.md#compact) command. Currently there is no support for running compactions programatically.

**Performance Numbers**

The following table illustrates the performance benefit gained by bypassing commit log writes. It contains loading performance numbers from a test in which 200GB of synthetically generated data was loaded into a small Hypertable cluster running on top of HDFS with three-way replication, both with and without commit log writes.

Test |  Elapsed Time (seconds) |  Throughput (bytes/s)
---|---|---
With commit log writes |  `8,985` |  `22,260,178`
Without commit log writes |  `4,154` |  `48,140,995`
