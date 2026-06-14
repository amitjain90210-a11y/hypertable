# Status Checking

Hypertable includes a number of scripts that perform status checks to verify that Hypertable and the services it comprises are up and operating properly.

## Table of Contents

### Introduction

All of the Hypertable check scripts conform to the Nagios plugin standard. The exit status of the check scripts are as follows:

    0 - OK
    1 - WARNING
    2 - CRITICAL
    3 - UNKNOWN

Each script also writes a single line description to the console in the format <service> <status> \- <description>. For example:

    FsBroker CRITICAL - connect error

### ht-check.sh

The `ht-check.sh` script performs an overal Hypertable status check. It has the following usage:

    usage: ht-check.sh [OPTIONS] [<server-options>]

    OPTIONS:
      -h,--help             Display usage information
      -t,--timeout <sec>    Timeout after <sec> seconds (default = 20)

This script performs an overall health check of Hypertable. It performs the following actions:

  * Connects to Hyperspace
  * Calls the Hyperspace status function
  * Reads active master address from the _address_ attribute of the `/hypertable/master` Hyperspace file
  * Connects to the active Master
  * Issues a _system status_ operation

The _system status_ operation in the master performs the following checks:

  * Performs a Master status check which is effectively the same as calling [ht-check-master.sh](status_checking.md#ht-check-mastersh) on the active master
  * For each registered RangeServer, a call is made to the RangeServer _status_ function

This check does not check the health of the ThriftBrokers. The health of the ThriftBrokers can be checked independently with the [ht-check-thriftbroker.sh](status_checking.md#ht-check-thriftbrokersh) script.

### ht-check-thriftbroker.sh

The `ht-check-thriftbroker.sh` script checks the status of the ThriftBroker. It has the following usage:

    usage: ht-check-thriftbroker.sh [OPTIONS] [<server-options>]

    OPTIONS:
      -h,--help             Display usage information
      -t,--timeout <sec>    Timeout after <sec> seconds (default = 5)
      -H,--hostname <addr>  Hostname or IP address of service (default = localhost)

The `ht-check-thriftbroker.sh` script connects to the ThriftBroker and issues a _status_ function call which simply returns OK status. The script verifies that the ThriftBroker is up and running and responding to function calls.

### ht-check-hyperspace.sh

The `ht-check-hyperspace.sh` script checks the status of Hyperspace. It has the following usage:

    usage: ht-check-hyperspace.sh [OPTIONS] [<server-options>]

    OPTIONS:
      -h,--help             Display usage information
      -t,--timeout <sec>    Timeout after <sec> seconds (default = 5)

The `ht-check-hyperspace.sh` script connects to Hyperspace and issues a _status_ function call which simply returns OK status. It verifies that Hyperspace is up and running and responding to function calls.

### ht-check-fsbroker.sh

The `ht-check-fsbroker.sh` script checks the status of the FsBroker. It has the following usage:

    usage: ht-check-fsbroker.sh [OPTIONS] [<server-options>]

    OPTIONS:
      -h,--help             Display usage information
      -t,--timeout <sec>    Timeout after <sec> seconds (default = 5)
      -H,--hostname <addr>  Hostname or IP address of service (default = localhost)

The `ht-check-fsbroker.sh` script connects to the FsBroker and issues a status function call which returns the broker status. The FsBrokers maintain status by tracking read and write errors.

**Read Errors**

If an error is encountered in the FsBroker's `read()` or `pread()` function, the status returned by the FsBroker will be CRITICAL until a subsequent call to either read function succeeds. Read errors stick for a minimum of 60 seconds. They don't get cleared until a successful read occurs 60 seconds after the last read error was detected. This guarantees that intermittent read errors will be detected by status checks, assuming they are run at least once per minute.

**Write Errors**

If an error is encountered in the FsBroker's `append()` or `flush()` function, the status returned by the FsBroker will be CRITICAL until a subsequent call to either write function succeeds. Write errors stick for a minimum of 60 seconds. They don't get cleared until a successful write occurs 60 seconds after the last write error was detected. This guarantees that intermittent write errors will be detected by status checks, assuming they are run at least once per minute.

**HDFS Specific Errors**

When the HDFS broker initially comes up, the filesystem is checked for _safemode_. If it is in safemode, the status check will CRITICAL until the filesystem exits safemode.

### ht-check-master.sh

The `ht-check-master.sh` script checks the status of the Hypertable Master. It has the following usage:

    usage: ht-check-master.sh [OPTIONS] [<server-options>]

    OPTIONS:
      -h,--help             Display usage information
      -t,--timeout <sec>    Timeout after <sec> seconds (default = 5)
      -H,--hostname <addr>  Hostname or IP address of service (default = localhost)

The `ht-check-master.sh` script connects to the Hypertable Master and issues a status command. The following table describes the status that is returned under various conditions.

Status Code |  Condition
---|---
OK |  Master has acquired the lock, but RangeServers have not connected and reached a quorum
OK - Standby |  Master is unable to acquire the lock and has entered the retry loop
WARNING |  A RangeServer is in the process of being recovered.
WARNING |  FsBroker status check returned WARNING
CRITICAL |  Server is starting up or shutting down
CRITICAL |  If one or more RangeServers has failed, but recovery is blocked due to lack of quorum.
CRITICAL |  FsBroker status check returned CRITICAL

The Master performs an FsBroker status check on the FsBroker to which it is connected. This status check performs effectively the same checks as [ht-check-fsbroker.sh](status_checking.md#ht-check-fsbrokersh), so running `ht-check-master.sh` on a Master machine obviates the need to also run `ht-check-fsbroker.sh` on the same machine.

### ht-check-rangeserver.sh

The ht-check-rangeserver.sh script checks the status of the RangeServer. It has the following usage:

    usage: ht-check-rangeserver.sh [OPTIONS] [<server-options>]

    OPTIONS:
      -h,--help             Display usage information
      -t,--timeout <sec>    Timeout after <sec> seconds (default = 5)
      -H,--hostname <addr>  Hostname or IP address of service (default = localhost)

The `ht-check-rangeserver.sh` script connects to the RangeServer and calls its  _status_ function. The status function performs the following steps to determine the status:

  * Check if server is starting up or shutting down (status CRITICAL)
  * Calls status function of FsBroker to which it is connected (status propagated if not OK)
  * Checks for status persisted in the persistent status log

**Persistent status**

When the RangeServer encounters certain non CRITICAL errors that require investigation, it will persist a WARNING status entry in the persistent status log. This persistent status log file path is `$HT_HOME/run/STATUS.htRangeServer`. The last entry in this log will get returned by the RangeServer status function of all other status checks return OK. An entry will get written to this persistent status log if, for example, a checksum error is encounterd during replay of a commit log fragment or if a commit log fragment file is truncated. The persistent status log entry will contain information about the error and the status function will return WARNING status until the persistent status file is manually removed.

The RangeServer performs an FsBroker status check on the FsBroker to which it is connected. This status check performs effectively the same checks as [ht-check-fsbroker.sh](status_checking.md#ht-check-fsbrokersh), so running `ht-check-rangeserver.sh` on a RangeServer machine obviates the need to also run `ht-check-fsbroker.sh` on the same machine.
