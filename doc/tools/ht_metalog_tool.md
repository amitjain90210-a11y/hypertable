# metalog_tool

metalog_tool is a program that can be used to manipulate a mata log. The Master and the RangeServers each have a meta log, which holds the operational state of the server. Among other things, the Master Meta Log (MML) holds the state of all in-progress operations and the RangeServer Meta Log (RSML) holds the meta state of each range it is managing. The most common use of the metalog_tool is to remove bad log entities, but it can also be used to edit individual log entity state.

### Input

The Master Meta Log holds the persistent state of the Master, including the state of all in-progress operations. It can be found at the following path in the brokered file system:

    /hypertable/servers/master/log/mml

The Range Server Meta Log holds the persistent state of a Range Server, including the state of all ranges managed by the server. The Range Server Meta Logs can be found at the following paths in the brokered file system:

    /hypertable/servers/*/log/rsml

The format of both the MML and RSMLs are the same. Each log is represented as a directory and contains numerically named log files. Log files with a high numeric name supercede files with lower numeric names. The log file consists of a series of serialized _entities_ , where an entity is the persistent state of some program object or concept. Each entity has a unique ID and the same entity can be serialized in the log multiple times, with the last serialization superceding all previous ones. The entities for the MML are different than the entities for the RSML, but all entities derive from the same base class, which is why a single tool can be used to manipulate both logs.

**_NOTE: This tool should never be run on a log in which the owner of the log (Master or Range Server) is running._**

### General Options

To print a human-readable version of a meta log to the terminal, the `--dump` option may be supplied. By itself, this option causes the most recent state of each entity in the log to be displayed. The output with this option is the same as the default output of the 'metalog_dump' command. For example:

    $ ht metalog_tool --dump /hypertable/servers/master/log/mml

To dump the contents of a specific log file, within the meta log directory, you can supply a pathname to the specific log file. For example:

    $ ht metalog_tool --dump /hypertable/servers/master/log/mml/249

To dump all entity records within a meta log file, supply the `--all` option. This may display the same entity multiple times which gives you a view of the state transitions the entity has made. For example:

    $ ht metalog_tool --dump --all /hypertable/servers/master/log/mml/249

One of the most common uses of the metalog_tool is to remove entities from a meta log. This can be achieved with the `--purge` and `--select` options.

The `--select` option can be used to select the entities that you would like to remove. It accepts either a comma-separated list of entity IDs, or a comma-separated list of entity types. For example, let's say you would like to remove the entity that is display with the following line in the dump output (take note of the ID 1355140):

    {MetaLog::Entity RangeServerConnection header={type=131072,checksum=1052026697,id=1355140,timestamp=Tue Jul 22 18:55:31 2014,flags=0,length=36} payload={ rs149 (mrashad21.i) state=REMOVED|BALANCED }

    $ ht metalog_tool --select 1355140 --purge /hypertable/servers/master/log/mml
    log version: 4
    1 entities purged.
    0 entities translated.
    0 entities modified.

The number of entities successfully purged is displayed in the output ("1 entities purged."). Now let's say you want to remove all of the OperationRecover entities from the log. To do that, you can supply the entity name as the argument to the `--select` option. For example:

    $ ht metalog_tool --select OperationRecover --purge /hypertable/servers/master/log/mml
    log version: 4
    791 entities purged.
    0 entities translated.
    0 entities modified.

The set of entity types supported by `--select` is listed below.

    BalancePlanAuthority
    OperationAlterTable
    OperationBalance
    OperationCreateNamespace
    OperationCreateTable
    OperationDropNamespace
    OperationDropTable
    OperationInitialize
    OperationMoveRange
    OperationRecover
    OperationRecoverRanges
    OperationRecoverServer
    OperationRenameTable
    OperationStop
    RangeServerConnection

### MML Options

To remove, from the BalancePlanAuthority entity, a specific table from the target of any moves, use the `--balance-plan-drop-table` option with the table ID of the table you wish to remove. This will remove all ServerReceiverPlan records that contain the specified table ID:

    $ ht metalog_tool --balance-plan-drop-table "3/7" /hypertable/servers/master/log/mml

To increment the BalancePlanAuthority generation number, use the `--balance-plan-incr-generation` option:

    $ ht metalog_tool --balance-plan-incr-generation /hypertable/servers/master/log/mml

To change the destination of ranges that exist in a recovery plan inside the BalancePlanAuthority entity, use the `--balance-plan-change-destination` option. The argument to this option has the following format:

    <failed-server>,<plan-type>,<old-destination>,<new-destination>

For example, to change the destination rs156 to rs999 in the USER range recovery plan for rs149, you could issue the following command:

    $ ht metalog_tool --balance-plan-change-destination rs149,USER,rs156,rs999 /hypertable/servers/master/log/mml

Valid values for the <plan-type> field are: ROOT, METADATA, SYSTEM, and USER. The <failed-server> and <plan-type> fields can hold the wildcard character ('*') to man all failed servers and all plan types, respectively:

    $ ht metalog_tool --balance-plan-change-destination *,*,rs156,rs999 /hypertable/servers/master/log/mml

The BalancePlanAuthority entity also has what's known as the "current set". This is the set of move plans for all non-recovery related moves. To clear this set, use the `--balance-plan-clear-current-set` option:

    $ ht metalog_tool --balance-plan-clear-current-set /hypertable/servers/master/log/mml

To change the destination of any OperationMoveRange entities, use the `--change-move-destination` option. The argument to this option takes the following form:

    rsN-rsM,rsO-rsP,...

For example, to change the destination of any OperationMoveRange entities from rs1 to rs3, you can use the following command:

    $ ht metalog_tool --change-move-destination rs1-rs3 /hypertable/servers/master/log/mml

### RSML Options

To dump the Range entities from an RSML in `.tsv` format, use the `--dump` option in combination with the `--metadata-tsv` option. The `--location` option is required for specifying the value of the Location column:

    $ ht metalog_tool --dump --metadata-tsv --location rs1 /hypertable/servers/rs1/log/rsml
    2:000991891         StartRow
    2:000991891         Location              rs1
    2:390849439         StartRow              375144033
    2:390849439         Location              rs1
    ...

To set the _needs compaction_ bit on all of the Range entities in an RSML, use the `--needs-compaction` option:

    $ ht metalog_tool --needs-compaction true /hypertable/servers/rs1/log/rsml

To set the _needs compaction_ bit on just a single entity, add the `--select` option (e.g. with entity ID 33):

    $ ht metalog_tool --needs-compaction true --select 33 /hypertable/servers/rs1/log/rsml

To set the _acknowledge load_ bit on all of the Range entities in an RSML, use the `--acknowledge-load` option:

    $ ht metalog_tool --acknowledge-load true /hypertable/servers/rs1/log/rsml

To set the _acknowledge load_ bit on just a single entity, add the `--select` option (e.g. with entity ID 33):

    $ ht metalog_tool --acknowledge-load true --select 33 /hypertable/servers/rs1/log/rsml

To set the _soft limit_ on all Range entities from a specific table, use the `--soft-limit` and `--table options:`

    $ ht metalog_tool --table 2 --soft-limit 777 /hypertable/servers/rs1/log/rsml

To set the _soft limit_ on a specific Range entity, add the `--select` option (e.g. with entity ID 33):

    $ ht metalog_tool --select 33 --table 2 --soft-limit 888 /hypertable/servers/rs1/log/rsml

To change the start row of a Range entity, use the `--translate-start-row-source` and `--translate-start-row-target` options:

    $ ht metalog_tool --translate-start-row-source "old-start-row" --translate-start-row-target "new-start-row" /hypertable/servers/rs1/log/rsml

To change the end row of a Range entity, use the `--translate-end-row-source` and `--translate-end-row-target` options:

    $ ht metalog_tool --translate-end-row-source "old-end-row" --translate-end-row-target "new-end-row" /hypertable/servers/rs1/log/rsml
