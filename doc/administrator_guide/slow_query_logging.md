# Slow Query Logging

The ThriftBroker logs information about slow queries to a file called `SlowQuery.log` in the log directory. A query is considered slow if it takes more than a configured amount of time to finish execution. Slow query logging is only performed for scan queries issued through the synchronous query APIs.

### Configuration

Slow query logging is enabled by default, but can be disabled by setting the following configuration property:

    ThriftBroker.SlowQueryLog.Enable=false

The definition of _slow_ is specified by the config property `ThriftBroker.SlowQueryLog.LatencyThreshold` which defaults to 10000 milliseconds. To set the threshold to five seconds, for example, the following property can be added to the configuration file:

    ThriftBroker.SlowQueryLog.LatencyThreshold=5000

### Log Format

To give you an idea of what the slow query log looks like, consider the following eight line snippet:

    1457147225 1457129991 get_cells ::ffff:172.27.120.131 17234 34 49 137198 247839 131238 rs1,rs2,rs3,rs4,rs5 /test SELECT "description" FROM Fruits
    1457416456 1457381569 get_cells_as_arrays ::ffff:172.27.120.137 34887 34 49 149218 307238 0 rs1,rs2,rs3,rs4,rs5 /test SELECT "description" FROM Fruits
    1458169571 1458146803 get_cells_serialized ::ffff:172.27.120.132 22768 34 49 182791 358721 0 rs1,rs2,rs3,rs4,rs5 /test SELECT "description" FROM Fruits
    1458245925 1458170692 scanner_close ::ffff:172.27.120.131 75233 34 49 766 287233 411738 rs1,rs2,rs3,rs4,rs5 /test SELECT * FROM Fruits
    1458304787 1458292928 scanner_close ::ffff:172.27.120.139 11859 9 16 78122 138729 0 rs2,rs3 /test SELECT "genus","tag:bitter","tag:sweet" FROM Fruits WHERE "lemon" <= ROW < "orange" MAX_VERSIONS 1
    1458478665 1458380409 hql_exec ::ffff:172.27.120.134 98256 1 1 185 309 0 rs3 /test SELECT * from Fruits WHERE ROW = 'pear'
    1458523722 1458481003 hql_exec_as_arrays ::ffff:172.27.120.138 42719 1 1 213 334 0 rs2 /test SELECT * from Fruits WHERE ROW = 'lemon'
    1459177197 1459069959 get_cell ::ffff:172.27.120.135 107238 1 1 331 662 65243 rs4 / SELECT * FROM 1_up WHERE "2EABAA==',"Content:1', <= CELL <= "2EABAA==',"Content:1', MAX_VERSIONS 1

Each log line represents a single slow query and consists of the 13 fields. The fields are described below.

  1. Finish Time (seconds since Epoch)
  2. Start Time (seconds since Epoch)
  3. Thrift function name
  4. Remote peer (client) address
  5. Latency (milliseconds)
  6. Number of subscanners
  7. Number of scanblocks (blocks returned from RangeServers)
  8. Bytes returned
  9. Bytes scanned (in-memory and disk)
  10. Disk bytes read
  11. List of RangeServers contacted (comma-separated list of proxy names)
  12. Namespace
  13. HQL representation of query

### Affected APIs

Slow query logging is only performed for the synchronous query APIs. This includes the `get_` convenience APIs and the `hql_` APIs for which the issued HQL statement is a SELECT statement. Slow query logging is also performed in the `scanner_close` API with the assumtion that the `scanner_close` call will immediately follow the `scanner_get_` calls. If the application processing of scanner results introduces significant latency, scanner_close may falsly report slow queries due to application latency. The following Thrift APIs include slow query logging:

  * get_cell
  * get_cells
  * get_cells_as_arrays
  * get_cells_serialized
  * get_row
  * get_row_as_arrays
  * get_row_serialized
  * hql_exec
  * hql_query
  * hql_query_as_arrays
  * scanner_close
