# Diagnostic and Recovery

As is the case with all databases, there are certain circumstances when Hypertable can get into an inconsistent state. For example, if the underlying file system loses files due to corruption, or if critical system files are inadvertently removed by an administrator. Hyppertable provides a number of diagnostic and recovery tools that can be used to get Hypertable back into a consistent and operational state. These tools are described below.

### htck

The [htck](../tools/ht_htck.md) program is used to check the integrity (metadata consistency) of a Hypertable database. If an integrity problem is detected, the tool can also be used to repair it.

### log_player

The [log_player](../tools/ht_log_player.md) program converts cells in a commit log (in the brokered file system) into a form that allows them to be re-inserted into Hypertable. It can be used in situations where Hypertable is not coming up due to major filesystem corruption and you need to recover data that has be inserted into the database.

### metalog_tool

The [metalog_tool](../tools/ht_metalog_tool.md) program can be used to manipulate a mata log. The Master and the RangeServers each have a meta log which holds the operational state of the server. Among other things, the Master Meta Log (MML) holds the state of all in-progress operations and the RangeServer Meta Log (RSML) holds the meta state of each range it is managing. The most common use of the metalog_tool is to remove bad log entities, but it can also be used to edit individual log entity state.

### salvage

The [salvage](../tools/ht_salvage.md) program can be used to salvage data from a (potentially corrupt) Hypertable database. It operates by recursively walking the `/hypertable/tables` directory in the brokered filesystem looking for CellStore files and extracting data from them. The recovered data is written into a tree of `.tsv` files that can be re-loaded into a clean database at a later time. For each unique table directory encountered, a `.hql` file will also be generated which contains the HQL required to re-create the table.
