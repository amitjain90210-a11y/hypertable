# HQL Reference

The Hypertable Query Language (HQL) allows you to create, modify, and query tables and invoke adminstrative commands. HQL is interpreted by the following interfaces:

  * The hypertable command line interface (ht shell)
  * The hql_exec* and hql_query* Thrift API methods
  * The Hypertable::HqlInterpreter C++ class

## Table of Contents

### ALTER TABLE

**EBNF**

    ALTER TABLE name alter_mode '(' [alter_definition] ')'
        [alter_mode '(' alter_definition ')' ... ]

    alter_mode:
      ADD
      | DROP
      | RENAME COLUMN FAMILY

    alter_definition:
      add_definition
      | drop_cf_definition
      | rename_cf_definition

    add_definition:
      column_family_name [MAX_VERSIONS '=' int] [TTL '=' duration]
      | ACCESS GROUP name [access_group_option ...]
        ['(' [column_family_name, ...] ')']

    drop_cf_definition:    column_family_name

    rename_cf_definition:    (old)column_family_name, (new)column_family_name

    duration:
      num MONTHS
      | num WEEKS
      | num DAYS
      | num HOURS
      | num MINUTES
      | num [ SECONDS ]

    access_group_option:
      IN_MEMORY
      | BLOCKSIZE '=' int
      | REPLICATION '=' int
      | COMPRESSOR '=' compressor_spec
      | BLOOMFILTER '=' bloom_filter_spec

    compressor_spec:
      bmz [ bmz_options ]
      | lzo
      | quicklz
      | snappy
      | zlib [ zlib_options ]
      | none

    bmz_options:
      --fp-len int
      | --offset int

    zlib_options:
      -9
      | --best
      | --normal

    bloom_filter_spec:
      rows [ bloom_filter_options ]
      | rows+cols [ bloom_filter_options ]
      | none

    bloom_filter_options:
      --false-positive float
      --bits-per-item float
      --num-hashes int
      --max-approx-items int

**DESCRIPTION**

The ALTER TABLE command provides a way to alter a table by adding access groups and column families or removing column families or renaming column families. See CREATE TABLE for a description of the column family and access group options. Column families that are not explicitly included in an access group specification will go into the "default" access group.

**EXAMPLE**

The following statements,

    CREATE TABLE foo (
      a MAX_VERSIONS=1,
      b TTL=1 DAY,
      c,
      ACCESS GROUP primary BLOCKSIZE=1024 ( a ),
      ACCESS GROUP secondary COMPRESSOR="zlib --best" ( b, c )
    );

    ALTER TABLE foo
      ADD ( d MAX_VERSIONS=2 )
      ADD ( ACCESS GROUP tertiary BLOOMFILTER="rows --false-positive 0.1" (d))
      DROP ( c )
      RENAME COLUMN FAMILY (a, e);

will produce the following output with `SHOW CREATE TABLE foo;`

    CREATE TABLE foo (
      e MAX_VERSIONS=1,
      b TTL=86400,
      d MAX_VERSIONS=2,
      ACCESS GROUP primary BLOCKSIZE=1024 (e),
      ACCESS GROUP secondary COMPRESSOR="zlib --best" (b),
      ACCESS GROUP tertiary BLOOMFILTER="rows --false-positive 0.1" (d),
    )

### CREATE NAMESPACE

**EBNF**

    CREATE NAMESPACE namespace_name;

**DESCRIPTION**

CREATE NAMESPACE command creates a new namespace. If _namespace_name_ starts with '/' it treats the _namespace_name_ as an absolute path otherwise it considers it to be a sub-namespace relative to the current namespace.

**EXAMPLE**

    hypertable> CREATE NAMESPACE "/test";
    hypertable> USE "/test";
    hypertable> CREATE NAMESPACE "subtest";

### CREATE TABLE

**EBNF**

    CREATE TABLE name '(' [create_definition, ...] ')' [table_option ...]
    CREATE TABLE name LIKE example_name

    create_definition:
      column_family_name [column_family_option ...]
      | INDEX column_family_name
      | QUALIFIER INDEX column_family_name
      | ACCESS GROUP name [access_group_option ...]
        ['(' [column_family_name, ...] ')']

    column_family_option:
      MAX_VERSIONS '=' int
      | TTL '=' duration
      | COUNTER

    duration:
      int MONTHS
      | int WEEKS
      | int DAYS
      | int HOURS
      | int MINUTES
      | int [ SECONDS ]

    access_group_option:
      COUNTER
      | IN_MEMORY
      | BLOCKSIZE '=' int
      | REPLICATION '=' int
      | COMPRESSOR '=' compressor_spec
      | BLOOMFILTER '=' bloom_filter_spec

    compressor_spec:
      bmz [ bmz_options ]
      | lzo
      | quicklz
      | snappy
      | zlib [ zlib_options ]
      | none

    bmz_options:
      --fp-len int
      | --offset int

    zlib_options:
      -9
      | --best
      | --normal

    bloom_filter_spec:
      rows [ bloom_filter_options ]
      | rows+cols [ bloom_filter_options ]
      | none

    bloom_filter_options:
      --false-positive float
      --bits-per-item float
      --num-hashes int
      --max-approx-items int

    table_option:
      MAX_VERSIONS '=' int
      | TTL '=' duration
      | IN_MEMORY
      | BLOCKSIZE '=' int
      | REPLICATION '=' int
      | COMPRESSOR '=' compressor_spec
      | GROUP_COMMIT_INTERVAL '=' int

**DESCRIPTION**

CREATE TABLE creates a table with the given name. A table consists of a set of column family and access group specifications.

**Column Families**

Column families are somewhat analogous to a traditional database column. The main difference is that a theoretically infinite number of qualified columns can be created within a column family. The qualifier is an optional NUL- terminated string that can be supplied, along with the data, in the insert statement. This is what gives tables in Hypertable their sparse nature. For example, given a column family "tag", the following set of qualified columns may be inserted for a single row.

  * tag:good
  * tag:science
  * tag:authoritative
  * tag:green

The column family is represented internally as a single byte, so there is a limit of 255 column families (the 0 value is reserved) which may be supplied in the CREATE TABLE statement.

**Secondary Indices**

Tables can also have one or more indices, each indexing a single column family. Two types of indices exist: a _cell value index_ , which optimizes scans on a single column family that do an excact match or prefix match of the cell value, and a _qualifier index_ , which optimizes scans on a single column family that do an exact match or prefix match of the column qualifier. The use of indices is optional.

The indices are stored in an index table which is created in the same namespace as the primary table and has the same name with one (cell value index) or two (qualifier index) caret signs (`^`) as a prefix.

A column family can have both types of indices (cell value index and qualifier index) at the same time. The following HQL command creates a table with three column families (a, b and c). Column family a has a cell value index, column family b has a qualifier index and c has both.

    CREATE TABLE foo (
        a,
        b,
        c,
        INDEX a,
        QUALIFIER INDEX b,
        INDEX c,
        QUALIFIER INDEX c,
     );

Indices speed up some queries that match on column families. Accessing columns which are indexed is nearly as fast as accessing them by their row key. On the downside they require additional disk storage and cause a very small performance impact when inserting data to an indexed column.

Cell value indices are used when selecting cells by value (`SELECT a FROM TABLE t WHERE a = "cell-value" `...) or by a value prefix (`SELECT a FROM TABLE t WHERE a =^ "cell-prefix" `...).

Qualifier indices are used when selecting cells from a qualified column (`SELECT a:foo FROM TABLE t `...) or selecting all cells with a qualifier prefix (`SELECT a:^prefix FROM TABLE t` ...).

**Access Groups**

Tables consist of one or more access groups, each containing some number of column families. There is a default access group named "default" which contains all column families that are not explicitly referenced in an ACCESS GROUP clause. For example, the following two statements are equivalent.

    CREATE TABLE foo (
       a,
       b,
       c,
       ACCESS GROUP bar ( a, b )
    );

    CREATE TABLE foo (
       a,
       b,
       c,
       ACCESS GROUP bar (a, b),
       ACCESS GROUP default (c)
    );

Access groups provide control over the physical layout of the table data on disk. The data for all column families in the same access group are stored physically together on disk. By carefully defining a set of access groups and choosing which column families go into those access groups, performance can be significantly improved for expected workloads. For example, say you have a table with 100 column families, but two of the column families get access together with much higher frequency than the rest of the 98 column families. By putting the two frequently accessed column families in their own access group, the system does much less disk i/o because only the data for the two column families gets transfered whenever those column families are accessed. A row-oriented database can be emulated by having a single access group. A column-oriented database can be emulated by having each column family within their own access group.

**Table Options**

The following table options are supported:

      MAX_VERSIONS '=' int
      TTL '=' duration
      IN_MEMORY
      BLOCKSIZE '=' int
      REPLICATION '=' int
      COMPRESSOR '=' compressor_spec
      GROUP_COMMIT_INTERVAL '=' int

Most of these are the same options as the ones in the column family and access group specification except that they act as defaults in the case where no corresponding option is specified in the column family or access group specifier. See the description under Access Group Options for option details.

"group commit" is a feature whereby the system will accumulate update requests for a table and commit them together as a group on a regular interval. This improves the performance of systems that receive a large number of concurrent updates by reducing the number of times sync() gets called on the commit log.

The GROUP_COMMIT_INTERVAL option tells the system that updates to this table should be carried out with group commit and also specifies the commit interval in milliseconds. The interval is constrained by the value of the config property Hypertable.RangeServer.CommitInterval, which acts as a lower bound and defaults to 50ms. The value specified for GROUP_COMMIT_INTERVAL will get rounded up to the nearest multiple of this property value.

Column Family Options

The following column family options are supported:

      MAX_VERSIONS '=' int
      TTL '=' duration
      COUNTER

Cells in a table are specified by not only a row key and a qualified column, but also a timestamp. This allows for essentially multiple timestamped version s of each cell. Cells are kept stored in reverse chronological order of timestamp and the MAX_VERSIONS allows you to specify that you only want to keep the n most recent versions of each cell. Older versions are lazily garbage collected through the normal compaction process.

The TTL option allows you to specify that you only want to keep cell versions that fall within some time window in the immediate past. For example, you can specify that you only want to keep cells that were created within the past two weeks. Like the MAX_VERSIONS option, older versions are lazily garbage collected through the normal compaction process.

The COUNTER option makes each instance of this column act as an atomic counter. Counter columns are accessed using the same methods as other columns. However, to modify the counter, the value must be formatted specially, as described in the following table.

**Value Format** |  **Description**
---|---
`['+'] n` |  `Increment the counter by n`
`'-' n` |  `Decrement the counter by n`
`'=' n` |  `Reset the counter to n`

For example, consider the following sequence of values written to a counter column:

      +9
      =0
      +3
      +4
      +5
      -2
      +9

After these six values get written to a counter column, a subsequent read of that column would return the ASCII string "10".

**Access Group Options**

The following access group options are supported:

      COUNTER
      IN_MEMORY
      BLOCKSIZE '=' int
      REPLICATION '=' int
      COMPRESSOR '=' compressor_spec
      BLOOMFILTER '=' bloom_filter_spec

The COUNTER option makes all column families in the access group counter columns (see COUNTER description under Column Family Options section).

The IN_MEMORY option indicates that all cell data for the access group should remain memory resident. Queries against column families in IN_MEMORY access groups are efficient because no disk access is required.

The cell data inserted into an access group resides in one of two places. The recently inserted cells are stored in an in-memory data structure called the cell cache and older cells get compacted into on-disk data structures called cell stores. The cell stores are organized as a series of compressed blocks of sorted key/value pairs (cells). At the end of the compressed blocks is a block index which contains, for each block, the key (row,column,timestamp) of the last cell in the block, followed by the block offset. It also contains a Bloom Filter.

The BLOCKSIZE option controls the size of the compressed blocks in the cell stores. A smaller block size minimizes the amount of data that must be read from disk and decompressed for a key lookup at the expense of a larger block index which consumes memory. The default value for the block size is 65K.

The REPLICATION option controls the replication level in the underlying distributed file system (DFS) for cell store files created for this access group. The default is unspecified, which translates to whatever the default replication level is for the underlying file system.

The COMPRESSOR option specifies the compression codec that should be used for cell store blocks within an access group. See the Compressors section below for a description of each compression codec.

NOTE: if the block, after compression, is not significantly reduced in size, then no compression will be performed on the block

An access group can consist of many on-disk cell stores. A query for a single row key can result probing each cell store to see if data is present for that row even when most of the cell stores do not contain any data for that row. To eliminate this inefficiency, each cell store contains an optional Bloom Filter. The Bloom Filter is a probabilistic data structure that can indicate, with high probability, if a key is present and also indicate definitively if a key is not present. By mapping the bloom filters, for each cell store in memory, queries can be made much more efficient because only the cell stores that contain the row are searched.

The bloom filter specification can take one of the following forms. The rows form, which is the default, causes only row keys to be inserted into the bloom filter. The rows+cols form causes the row key concatenated with the column family to be inserted into the bloom filter. none disables the bloom filter.

      rows [ bloom_filter_options ]
      rows+cols [ bloom_filter_options ]
      none

The following table describes the bloom filter options:

**Option** |  **Default** |  **Description**
---|---|---
`--false-positive arg` |  `0.01` |  `Expected false positive probability. This option is (currently) mutually exclusive with the --bits-per-item and --num-hashes options. If specified it will choose the minimum number of bits per item that can achieve the given false positive probability and will choose the appropriate number of hash functions.`
`--bits-per-item arg` |  `NULL` |  `Number of bits to use per item (to compute size of bloom filter). Must be used in conjunction with --num-hashes.`
`--num-hashes arg` |  `NULL` |  `Number of hash functions to use. Must be used in conjunction with --bits-per-item.`
`--max-approx-items arg` |  `1000` |  `Number of cell store items used to guess the number of actual Bloom filter entries
Compressors`

The cell store blocks within an access group are compressed using the compression codec that is specified for the access group. The following compression codecs are available:

  * bmz
  * lzo
  * quicklz
  * snappy
  * zlib
  * none

The default code is snappy for cell store blocks. The following tables describe the available options.

**bmz codec options**

**Option** | **Default** | **Description**
---|---|---
`--fp-len arg` |  `19` |  `Minimum fingerprint length`
`--offset arg` |  `0` |  `Starting fingerprint offset`

**zlib codec options**

**Option** | **Description**
---|---
`-9 [ --best ]` |  `Highest compression ratio (at the cost of speed)`
`--normal` |  `Normal compression ratio`

### DELETE

**EBNF**

    DELETE ('*' | column [',' column ...])
      FROM table_name
      WHERE ROW '=' row_key
      [(TIMESTAMP timestamp | VERSION timestamp)]

    column:
      column_family [':' column_qualifier]

    timestamp:
      YYYY-MM-DD HH:MM:SS[.nanoseconds]

**DESCRIPTION**

The `DELETE` command provides a way to delete cells from a row in a table. The command applies to a single row only and can be used to delete, for a given row, all of the cells in a qualified column, all the cells in a column family, or all of the cells in the row. If the `TIMESTAMP` clause is given, then the delete will only apply to those cells whose internal timestamp field is equal to or less than the given timestamp. An example of each type of delete is shown below. Assume that we are re starting with a table that contains the following:

    hypertable> SELECT * FROM crawldb DISPLAY_TIMESTAMPS;
    2010-01-01 00:00:02.00000000    org.hypertable.www      status-code     200
    2010-01-01 00:00:01.00000000    org.hypertable.www      status-code     200
    2010-01-01 00:00:04.00000000    org.hypertable.www      anchor:http://www.news.com/     Hypertable
    2010-01-01 00:00:03.00000000    org.hypertable.www      anchor:http://www.news.com/     Hypertable
    2010-01-01 00:00:06.00000000    org.hypertable.www      anchor:http://www.opensource.org/       Hypertable.org
    2010-01-01 00:00:05.00000000    org.hypertable.www      anchor:http://www.opensource.org/       Hypertable.org
    2010-01-01 00:00:08.00000000    org.hypertable.www      checksum        822828699
    2010-01-01 00:00:07.00000000    org.hypertable.www      checksum        2921728

The first example shows how to delete one specific timestamped version of a cell in the column anchor:http://www.opensource.org/ of the row org.hypertable.www.

    hypertable> DELETE "anchor:http://www.opensource.org/" FROM crawldb WHERE
    ROW='org.hypertable.www' VERSION "2010-01-01 00:00:06";

    hypertable> select "anchor" from crawldb DISPLAY_TIMESTAMPS;
    2010-01-01 00:00:04.00000000    org.hypertable.www      anchor:http://www.news.com/     Hypertable
    2010-01-01 00:00:03.00000000    org.hypertable.www      anchor:http://www.news.com/     Hypertable
    2010-01-01 00:00:05.00000000    org.hypertable.www      anchor:http://www.opensource.org/       Hypertable.org

The next example shows how to delete the cells in the column anchor:http://www.opensource.org/ of the row org.hypertable.www.

    hypertable> DELETE "anchor:http://www.opensource.org/" FROM crawldb WHERE
    ROW='org.hypertable.www';

    hypertable> select * from crawldb;
    org.hypertable.www      status-code     200
    org.hypertable.www      status-code     200
    org.hypertable.www      anchor:http://www.news.com/     Hypertable
    org.hypertable.www      anchor:http://www.news.com/     Hypertable
    org.hypertable.www      checksum        822828699
    org.hypertable.www      checksum        2921728

The next example shows how to delete all of the cells in the column family checksum of the row org.hypertable.www.

    hypertable> DELETE checksum FROM crawldb WHERE ROW="org.hypertable.www";

    hypertable> select * from crawldb;
    org.hypertable.www      status-code     200
    org.hypertable.www      status-code     200
    org.hypertable.www      anchor:http://www.news.com/     Hypertable
    org.hypertable.www      anchor:http://www.news.com/     Hypertable

And finally, here's how to delete all of the cells in the row org.hypertable.www.

    hypertable> DELETE * FROM crawldb WHERE ROW="org.hypertable.www";

    hypertable> SELECT * FROM crawldb;

### DESCRIBE TABLE

**EBNF**

    DESCRIBE TABLE [ WITH IDS ] table_name

**DESCRPTION**

The `DESCRIBE TABLE` command displays the XML-style schema for a table. The output of the straight `DESCRIBE TABLE` command can be passed into the Hypertable C++ `Client::create_table()` API as the schema parameter. If the optional `WITH IDS` clause is supplied, then the schema "generation" attribute and the column family "id" attributes are included in the XML output. For example, the following table creation statement:

    CREATE TABLE foo (
      a MAX_VERSIONS=1,
      b TTL=1 DAY,
      c,
      ACCESS GROUP primary BLOCKSIZE=1024 ( a, b ),
      ACCESS GROUP secondary compressor="zlib --best" ( c )
    );

will create a table with the following schema as reported by the `CREATE TABLE` command:

          a
          1
          false

          b
          86400
          false

          c
          false

and the following output will be generated when the `WITH IDS` clause is supplied in the `CREATE TABLE` statement:

          1
          a
          1
          false

          1
          b
          86400
          false

          1
          c
          false

### DROP NAMESPACE

**EBNF**

    DROP NAMESPACE [IF EXISTS] namespace_name

**DESCRIPTION**

The DROP NAMESPACE removes a namespace. If the IF EXISTS clause is specified, the command wont generate an error if the namespace _namespace_name_ does not exist. A namespace can only be dropped if it is empty (ie has contains no tables or sub-namespaces If _namespace_name_ starts with '/' it treats _namespace_name_ as an absolute path, otherwise it considers it to be a sub-namespace relative to the current namespace.

**EXAMPLE**

    hypertable> DROP NAMESPACE "/test/subtest";
    hypertable> DROP NAMESPACE "/test";

### DROP TABLE

**EBNF**

    DROP TABLE [IF EXISTS] table_name

**DESCRIPTION**

The DROP TABLE command removes the table _table_name_ from the system. If the IF EXIST clause is supplied, the command won't generate an error if a table by the name of _table_name_ does not exist.

**EXAMPLE**

    hypertable> drop table foo;

### DUMP TABLE

**EBNF**

    DUMP TABLE table_name
      [COLUMNS ('*' | (column_predicate [',' column_predicate]*))]
      [where_clause]
      [options_spec]

    where_clause:
      WHERE where_predicate [AND where_predicate]*

    where_predicate:
      row_predicate
      | timestamp_predicate
      | value_predicate

    row_predicate:
      ROW REGEXP 'row_regexp'

    timestamp_predicate:
      [timestamp relop] TIMESTAMP relop timestamp

    relop: '=' | '<' | '<=' | '>' | '>='

    value_predicate:
      VALUE REGEXP 'value_regexp'

    options_spec:
      (REVS revision_count
      | INTO FILE [file_location]filename[.gz]
      | BUCKETS n
      | NO_ESCAPE)*

    file_location:
      "dfs://" | "file://"

    timestamp:
      'YYYY-MM-DD HH:MM:SS[.nanoseconds]'

**DESCRIPTION**

The DUMP TABLE command provides a way to create efficient table backups which can be loaded with LOAD DATA INFILE. The problem with using SELECT to create table backups is that it outputs table data in order of row key. LOAD DATA INFILE yields worst-case performance when loading data that is sorted by the row key because only one RangeServer at a time will be actively receiving updates. Backup file generated with DUMP TABLE are much more efficient because the data distribution in the backup file causes many (or all) of the RangeServers to actively receive updates during the loading process. The DUMP TABLE command will randomly select n ranges and output cells from those ranges in round-robin fashion. n is the number of buckets (default is 20) and can be specified with the BUCKETS option.

**OPTIONS**

**REVS revision_count**

Each cell in a Hypertable table can have multiple timestamped revisions. By default all revisions of a cell are returned by the DUMP TABLE statement. The REVS option allows control over the number of cell revisions returned. The cell revisions are stored in reverse-chronological order, so REVS 1 will return the most recent version of the cell.

**INTO FILE [file://|dfs://]filename[.gz]**

The result of a DUMP TABLE command is displayed to standard output by default. The INTO FILE option allows the output to get redirected to a file. If the file name starts with the location specifier `dfs://` then the output file is assumed to reside in the DFS. If it starts with `file://` then output is sent to a local file. This is also the default location in the absence of any location specifier. If the file name specified ends in a `.gz` extension, then the output is compressed with gzip before it is written to the file.

**BUCKETS n**

This option causes the DUMP TABLE command to use n buckets. The default is 20. It is recommended that n is at least as large as the number of nodes in the cluster that the backup with be restored to.

**NO_ESCAPE**

The output format of a DUMP TABLE command comprises tab delimited lines, one cell per line, which is suitable for input to the LOAD DATA INFILE command. However, if the value portion of the cell contains either newline or tab characters, then it will confuse the LOAD DATA INFILE input parser. To prevent this from happening, newline, tab, and backslash characters are converted into two character escape sequences, described in the following table.

**Character** |  **Escape Sequence**
---|---
`backslash (\)` |  `'\' '\'`
`newline (\n)` |  `'\' \n'`
`tab (\t)` |  `'\' 't'`
`NUL (\0)` |  `'\' '0'`

The NO_ESCAPE option turns off this escaping mechanism.

**EXAMPLES**

    DUMP TABLE foo;
    DUMP TABLE foo WHERE '2008-07-28 00:00:02' < TIMESTAMP < '2008-07-28 00:00:07';
    DUMP TABLE foo INTO FILE 'foo.tsv.gz'
    DUMP TABLE foo REVS 1 BUCKETS 1000;
    DUMP TABLE LoadTest COLUMNS user:/^a/ WHERE ROW REGEXP "1.*2" AND VALUE REGEXP "foob";

### EXISTS TABLE

**EBNF**

    EXISTS TABLE table_name

**DESCRIPTION**

The EXISTS TABLE command will print "true" if a table named _table_name_ exists in the current namespace and will print "false" if it does not.

**EXAMPLE**

    hypertable> exists table foo;
    true

### GET LISTING

**EBNF**

    GET LISTING

**DESCRIPTION**

The GET LISTING command lists the tables and namespaces in the current namespace.

**EXAMPLE**

    hypertable> GET LISTING;
    foo
    sys   (namespace)
    Test

### INSERT

**EBNF**

    INSERT INTO table_name VALUES value_list

    value_list:
        value_spec [',' value_spec ...]

    value_spec:
        '(' row ',' column ',' value ')'
        '(' timestamp ',' row ',' column ',' value ')'

    column:
        family [ ':' qualifier ]

    timestamp:
        YYYY-MM-DD HH:MM:SS[.nanoseconds]

**DESCRIPTION**

The INSERT command inserts data (cells) into a table. The data is supplied as a list of comma separated tuples. Each tuple represents a cell and can take one of two forms:

(row, column, value)
(timestamp, row, column, value)

The first form just supplies the row key, column key, and value as strings and the cell timestamp is auto-assigned. The second form supplies the timestamp in addition to the row key, column key, and value.

**EXAMPLE**

    hypertable> INSERT INTO fruit VALUES ("cantelope", "tag:good", "Had with breakfast"), ("2009-08-02 08:30:00", "cantelope", "description", "A cultivated variety of muskmelon with orange flesh"),("banana", "tag:great", "Had with lunch");

    hypertable> SELECT * FROM fruit DISPLAY_TIMESTAMPS;
    2009-08-11 05:06:17.246062001  banana     tag:great    Had with lunch
    2009-08-11 05:06:17.246062002  cantelope  tag:good     Had with breakfast
    2009-08-02 08:30:00.000000000  cantelope  description  A cultivated variety of muskmelon with orange flesh

If timestamps are not supplied, then they will be automatically assigned by the RangeServer for non-indexed column families, and will be automatically assigned by the client library for indexed column families. It is therefore important that the system clock of the application servers be synchronized with the clocks of the Hypertable RangeServer machines.

Hypertable supports the GUID() function call for row key and value. It will generate a globally unique ID:

    INSERT INTO test VALUES (GUID(), "username", "bloefeld");
    INSERT INTO test VALUES ("harddisk0", "device", GUID());

might yield the following output from the SELECT command:

    3a983b8e-b7c7-49ae-b3e4-e221610f33ec username bloefeld
    harddisk0 device 6d38d110-8790-4a40-8653-701742343d1e

### LOAD DATA INFILE

**EBNF**

    LOAD DATA INFILE [options] [file_location]fname[.gz] INTO TABLE name

    LOAD DATA INFILE [options] [file_location]fname[.gz] INTO FILE fname

    options:

      (ROW_KEY_COLUMN '=' column_specifier ['+' column_specifier ...]
       | TIMESTAMP_COLUMN '=' name |
       | HEADER_FILE '=' '"' filename '"'
       | ROW_UNIQUIFY_CHARS '=' n
       | NO_ESCAPE
       | DUPLICATE_KEY_COLUMNS
       | IGNORE_UNKNOWN_COLUMNS
       | SINGLE_CELL_FORMAT)*

    column_specifier =
      [ column_format ] column_name

    column_format
      "%0" int
      | "%-"
      | "%"

    file_location:
      "dfs://" | "file://"

**DESCRIPTION**

The LOAD DATA INFILE command provides a way to bulk load data from an optionally compressed file or stdin (fname of "-", see Load from STDIN below), into a table. The input is assumed to start with a header line that indicates the format of the lines in the file. The header can optionlly be stored in a separate file and referenced with the HEADER_FILE option. The header is expected to have the following format:

    header =
      [ '#' ] single_cell_format
      | [ '#' ] multi_cell_format

    single_cell_format =
      "row" '\t' "column" '\t' "value" '\n'
      | "timestamp" '\t' "row" '\t' "column" '\t' "value" '\n'

    multi_cell_format =
      column | string ( '\t' ( column | string ) )*

    column = column_family [ ':' column_qualifier ]

Two basic tab-delimited formats are supported, a single cell format in which each line contains a single cell, and a multi-cell format in which each line can contain a list of cells. The following example shows the single-cell format:

**Example 1**

    row     column  value
    1127071 query   guardianship
    1127071 item:rank       8
    1127071 click_url       [http://adopting.adoption.com](http://adopting.adoption.com/)
    1246036 query   polish american priests association
    1246036 item:rank       6
    1246036 click_url       [http://www.palichicago.org](http://www.palichicago.org/)
    12653   query   lowes
    12653   item:rank       1
    12653   click_url       [http://www.lowes.com](http://www.lowes.com/)
    1270972 query   head hunters
    1270972 item:rank       2
    1270972 click_url       [http://www.headhunters.com](http://www.headhunters.com/)
    2648672 query   jamie farr
    2648672 item:rank       1
    2648672 click_url       [http://www.imdb.com](http://www.imdb.com/)
    ...

An optional initial timestamp column can be included which represents the cell timestamp, for example:

**Example 2**

    timestamp       row     column  value
    2009-08-12 00:01:08     1127071 query   guardianship
    2009-08-12 00:01:08     1127071 item:rank       8
    2009-08-12 00:01:08     1127071 click_url       [http://adopting.adoption.com](http://adopting.adoption.com/)
    2009-08-12 00:01:18     1246036 query   polish american priests association
    2009-08-12 00:01:18     1246036 item:rank       6
    2009-08-12 00:01:18     1246036 click_url       [http://www.palichicago.org](http://www.palichicago.org/)
    2009-08-12 00:01:14     12653   query   lowes
    2009-08-12 00:01:14     12653   item:rank       1
    2009-08-12 00:01:14     12653   click_url       [http://www.lowes.com](http://www.lowes.com/)
    2009-08-12 00:01:10     1270972 query   head hunters
    2009-08-12 00:01:10     1270972 item:rank       2
    2009-08-12 00:01:10     1270972 click_url       [http://www.headhunters.com](http://www.headhunters.com/)
    2009-08-12 00:01:17     2648672 query   jamie farr
    2009-08-12 00:01:17     2648672 item:rank       1
    2009-08-12 00:01:17     2648672 click_url       [http://www.imdb.com](http://www.imdb.com/)
    ...

The multi-line format assumes that each tab delimited field represents a cell value and the column header specifies the name of the column. Unless otherwise specified, the first column is assumed to be the rowkey. For example:

**Example 3**

    anon_id     query       item:rank   click_url
    3613173     batman signal images    18  [http://www.icomania.com](http://www.icomania.com/)
    1127071     guardianship  8     [http://adopting.adoption.com](http://adopting.adoption.com/)
    1270972     head hunters  2     [http://www.headhunters.com](http://www.headhunters.com/)
    465778      google    1     [http://www.google.com](http://www.google.com/)
    12653       lowes     1     [http://www.lowes.com](http://www.lowes.com/)
    48785       address locator     2   [http://www.usps.com/ncsc/](http://www.usps.com/ncsc/)
    48785       address locator     3   [http://factfinder.census.gov](http://factfinder.census.gov/)
    2648672     jamie farr          1   [http://www.imdb.com](http://www.imdb.com/)
    1246036     polish american 6   [http://www.palichicago.org](http://www.palichicago.org/)
    605089      dachshunds for sale 2   [http://www.houstonzone.org](http://www.houstonzone.org/)
    760038      stds       1   [http://www.ashastd.org](http://www.ashastd.org/)

When loaded into a table with a straight LOAD DATA INFILE command, the above file will produce a set of cells equivalent to Example 1 above.

**OPTIONS**

**ROW_KEY_COLUMN = column_specifier [ + column_specifier ... ]**

The LOAD DATA INFILE command accepts a number of options. The first is the ROW_KEY_COLUMN option. This is used in conjunction with the multi-cell input file format. It provides a way to select which column in the input file should be used as the row key (default is first column). By separating two or more column names with the `'+'` character, multiple column values will be concatenated together, separated by a single space character to form the row key. Also, each column specifier can have one of the following prefixes to control field width and justification:

**Table 1**

**Prefix** | **Description**
---|---
`%0` |  For numeric columns, specifies a field width of  and right-justify with '0' padding
`%-` |  Specifies a field width of  and right-justification with ' ' (space) padding
`%` |  Specifies a field width of  and left-justification with ' ' (space) padding

For example, assuming the data in Example 3 above is contained in a filed named `query-log.tsv`, then the following LOAD DATA INFILE command:

    LOAD DATA INFILE ROW_KEY_COLUMN="%09anon_id"+query "query-log.tsv" INTO TABLE 'anon-id-query';

will populated the 'anon-id-query' table with the following content:

    000012653 lowes      item:rank      1
    000012653 lowes      click_url      [http://www.lowes.com](http://www.lowes.com/)
    000048785 address locator       item:rank   3
    000048785 address locator       item:rank   2
    000048785 address locator       click_url   [http://factfinder.census.gov](http://factfinder.census.gov/)
    000048785 address locator       click_url   [http://www.usps.com/ncsc/](http://www.usps.com/ncsc/)
    000465778 google  item:rank     1
    000465778 google  click_url     [http://www.google.com](http://www.google.com/)
    000605089 dachshunds for sale       item:rank   2
    000605089 dachshunds for sale       click_url   [http://www.houstonzone.org](http://www.houstonzone.org/)
    000760038 stds       item:rank      1
    000760038 stds       click_url      [http://www.ashastd.org](http://www.ashastd.org/)
    001127071 guardianship          item:rank   8
    001127071 guardianship          click_url   [http://adopting.adoption.com](http://adopting.adoption.com/)
    001246036 polish american       item:rank   6
    001246036 polish american       click_url   [http://www.palichicago.org](http://www.palichicago.org/)
    001270972 head hunters          item:rank   2
    001270972 head hunters          click_url   [http://www.headhunters.com](http://www.headhunters.com/)
    002648672 jamie farr            item:rank   1
    002648672 jamie farr            click_url   [http://www.imdb.com](http://www.imdb.com/)
    003613173 batman signal images      item:rank   18
    003613173 batman signal images      click_url   [http://www.icomania.com](http://www.icomania.com/)

**TIMESTAMP_COLUMN = column_name**

The TIMESTAMP_COLUMN option is used in conjunction with the multi-cell input file format to specify which field of the input file should be used as the timestamp. The timestamp extracted from this field will be used for each cell in the row. The timestamp field is assumed to have the format YYYY-MM-DD HH:MM:SS

**HEADER_FILE = "filename"**

The HEADER_FILE option is used to specify an alternate file that contains the header line for the data file. This is useful in situations where you have log files that roll periodically and/or you want to be able to concatenate them. This option allows the input files to just contain data and the header to be specified in a separate file.

**ROW_UNIQUIFY_CHARS = n**

The ROW_UNIQUIFY_CHARS option provides a way to append a random string of characters to the end of the row keys to ensure that they are unique. The maximum number of characters you can specify is 21 and each character represents 6 random bits. It is useful in situations where the row key isn't discriminating enough to cause each input line to wind up in its own row. For example, let's say you want to dump a server log into a table, using the timestamp as the row key. However, as in the case of an Apache log, the timestamp usually only has resolution down to the second and there may be many entries that fall within the same second.

**NO_ESCAPE**

The NO_ESCAPE option provides a way to disable the escaping mechanism. The newline and tab characters are escaped and unescaped when transferred in and out of the system. The LOAD DATA INFILE command will scan the input for the two character sequences `'\' 'n'`, `'\' 't'`, `'\' '0'`, and `'\' '\'` and will convert them into a _newline_ , _tab_ , _NUL_ , and _backslash_ , respectively. The NO_ESCAPE option disables this conversion.

**DUPLICATE_KEY_COLUMNS**

Normally input fields that represent the row key (the first field or the ones designated in the ROW_KEY_COLUMN option) are not also inserted as cell data. This option causes the system to also insert the row key fields as cell data.

**IGNORE_UNKNOWN_COLUMNS**

Skip input lines that refer to unknown (non-existent) column families.

**SINGLE_CELL_FORMAT**

The LOAD DATA INFILE command will attempt to detect the format of the input file by parsing the first line if it begins with a `'#'` character. It assumes that the remainder of the line is a tab-delimited list of column names. However, if the file format is the 3-field single-cell format (i.e. row,column,value) and lacks a header, and the first character of the row key in first line happens to be the '#' character, the parser will get confused and interpret the first cell as the format line. The SINGLE_CELL_FORMAT option provides a way to tell the interpreter that there is no header format line and the format of the load file is one of the single cell formats (e.g. row,column,value or timestamp,row,column,value) and have it determine the format by counting the tabs on the first line.

**Loading from STDIN**

The LOAD DATA INFILE command has the ability to load data from standard input by specifying a file name of "-". The following is an example of how to use this feature:

    $ cat data.tsv | ht shell --batch -e 'load data infile "-" into table foo;'

**Load from DFS file**

If the data file name starts with the location specifier `dfs://` then the file is read from the DFS over the DfsBroker. If it begins with the specifier `file://` then it is read from the local FS (this is the default in the absence of a location specifier).

**Compression**

If the name of the input file ends with a `.gz`, the file is assumed to be compressed and will be streamed in through a decompressor (gzip).

### RENAME TABLE

**EBNF**

    RENAME TABLE table_name TO new_table_name

**DESCRIPTION**

The RENAME TABLE command renames the existing _table_name_ to the _new_table_name_.

**EXAMPLE**

    hypertable> rename table foo to bar;

### SELECT

**EBNF**

    SELECT [CELLS] ('*' | (column_predicate [',' column_predicate]*))

      FROM table_name
      [where_clause]
      [options_spec]

    where_clause:
        WHERE where_predicate [AND where_predicate ...]
    where_predicate:
      cell_predicate
      | row_predicate
      | column_value_predicate
      | timestamp_predicate

    relop: '=' | '<' | '<=' | '>' | '>=' | '=^'
    column_predicate
      = column_family
      | column_family ':' column_qualifer
      | column_family ':' '/' column_qualifier_regexp '/'
      | column_family ':' '^' column_qualifier_prefix

    cell_spec: row ',' column
    cell_predicate:
      [cell_spec relop] CELL relop cell_spec
      | '(' [cell_spec relop] CELL relop cell_spec
            (OR [cell_spec relop] CELL relop cell_spec)* ')'

    row_predicate:
      [row_key relop] ROW relop row_key
      | '(' [row_key relop] ROW relop row_key
              (OR [row_key relop] ROW relop row_key)* ')'
      | ROW REGEXP '"'row_regexp'"'

    column_value_predicate:
      column_family '=' value
      | column_family '=' '^' value

    timestamp_predicate:
      [timestamp relop] TIMESTAMP relop timestamp

    options_spec:
      (MAX_VERSIONS version_count
      | OFFSET row_offset
      | LIMIT row_count
      | CELL_OFFSET cell_offset
      | CELL_LIMIT max_cells
      | CELL_LIMIT_PER_FAMILY max_cells_per_cf
      | INTO FILE [file_location]filename[.gz]
      | DISPLAY_TIMESTAMPS
      | KEYS_ONLY
      | NO_ESCAPE
      | RETURN_DELETES
      | SCAN_AND_FILTER_ROWS)*

    timestamp:
      'YYYY-MM-DD HH:MM:SS[.nanoseconds]'

    file_location:
      "dfs://" | "file://"

**DESCRIPTION**

The SELECT command is used to issue queries that return a specific set of cells from a table. Conceptually, the command operates in two steps. The first step selects a set of candidate cells by applying the row or cell predicate. The second step filters the candidate cells by applying an optional timestamp predicate and other options.

**Row Predicate**

This is the part of the select statement that allows you to specify a set of rows or row intervals to be considered during query evaluation. A row or row interval can be specified using a comparison expression that combines the keyword ROW with comparison operators and row key string constants (e.g. ROW = "com.hypertable.www"). To specify multiple rows or row intervals, multiple comparison expressions can be strung together with the OR keyword. Row predicates cannot be combined with cell predicates (see below). If a row or cell predicate is not supplied, the query results in a full table scan.

**Cell Predicate**

This part of the select statement allows you to specify a set of cells or cell intervals
to be considered during query evaluation. A cell or cell interval can be specified using a comparison expression that combines the keyword CELL with comparison operators and cell key string constants (e.g. "com.hypertabl.www","tag:a" <= CELL < "com.hypertable.www","tag:j"). To specify multiple cells or cell intervals, multiple comparison expressions can be strung together with the OR keyword. Row predicates cannot be combined with cell predicates. If a row or cell predicate is not supplied, the query results in a full table scan.

**Timestamp Predicate**

Every cell of every table contains a 64-bit, high resolution timestamp that uniquely identifies a specific version of the cell. The timestamp is is either supplied by the application or auto-assigned by the system and is interpreted as nanoseconds since the Epoch (1970-01-01 00:00:00.000000000). Cells can be selected whos timestamp satisfies a certain criteria by specifying a comparison expression that combines the keyword TIMESTAMP with comparison operators and timestamp constants. Only one timestamp comparison expression is allowed. The timestamp predicate is a filter that is applied after the cells have been selected via the row or cell predicates. If no timestamp predicate is supplied, all cell versions are returned.

**Column Value Predicate**

When specifying a column value predicate, the column family must be identical to the column family used in the SELECT clause, and exactly one column family must be selected. The following examples are valid:

    SELECT col FROM test WHERE col = "foo";
    SELECT col FROM test WHERE col =^ "prefix";

The following examples are **not** valid because they select more than one column family or because the column family in the select clause is different from the one in the predicate (these limitations will be removed in future versions of Hypertable):

    SELECT * FROM test WHERE col = "foo";
    SELECT col, col2 FROM test WHERE col =^ "prefix";
    SELECT foo FROM test WHERE bar = "value";

**Column Qualifier Predicate**

The column qualifier predicate comes immediately after the SELECT keyword and can be used to do an exact match or prefix match of a column qualifer. If a qualifier index exists for the column family referenced, it will be used to efficiently satisfy the predicate. The following is an example of an exact match column qualifier predicate:

    SELECT tags:interesting FROM forum_posts;

The following is an example of a prefix match column qualifier predicate:

    SELECT tags:^interest FROM forum_posts;

**Comparison Operators**

The following table lists the comparison operators that can be used in Row, Cell, or Timestamp predicates.

Operator |  Description |  Example
---|---|---
= |  Equals |  `ROW = "com.hypertable.www/doc"`
=^ |  Starts With ( row, cell, and column predicates only ) |  `ROW =^ "com.hypertable"`
< |  Less Than |  `ROW < "com.hypertable"`
<= |  Less Than or Equal To |  `ROW <= "com.hypertable"`
> |  Greater Than |  `TIMESTAMP > "2012-01-02"`
>= |  Greater Than or Equal To |  `TIMESTAMP > "2012-01-02"`

**OPTIONS**

**MAX_VERSIONS version_count**

Each cell in a Hypertable table can have multiple timestamped versions. By default all versions of a cell are returned by the SELECT statement. The MAX_VERSIONS option allows control over the number of cell versions returned. The cell revisions are stored in reverse-chronological order, so `MAX_VERSIONS 1` will return the most recent version of the cell.

**`OFFSET row_offset`**

Skips the first _row_offset_ rows returned by the SELECT statement. This option cannot be combined with CELL_OFFSET and currently applies independently to each row (or cell) interval supplied in the WHERE clause.

`**LIMIT row_count**`

Limits the number of rows returned by the SELECT statement to _row_count_. The limit applies independently to each row (or cell) interval specified in the WHERE clause.

`**CELL_OFFSET cell_offset**`

Skips the first _cell_offset_ cells returned by the SELECT statement. This option cannot be combined with OFFSET and currently applies independently to each row (or cell) interval supplied in the WHERE clause.

`**CELL_LIMIT max_cells**`

Limits the total number of cells returned by the query to _max_cells_ (applied after CELL_LIMIT_PER_FAMILY). The limit applies independently to each row (or cell) interval specified in the WHERE clause.

`**CELL_LIMIT_PER_FAMILY max_cells_per_cf**`

Limits the number of cells returned per row per column family by the SELECT statement to _max_cells_per_cf_.

**`INTO FILE [file://|dfs://]filename[.gz]`**

The result of a SELECT command is displayed to standard output by default. The INTO FILE option allows the output to get redirected to a file.
If the file name starts with the location specifier dfs:// then the output file is assumed to reside in the DFS. If it starts with file:// then output is sent to a local file. This is also the default location in the absence of any location specifier. If the file name specified ends in a .gz extension, then the output is compressed with gzip before it is written to the file. The first line of the output, when using the INTO FILE option, is a header line, which will take one of the two following formats. The second format will be output if the DISPLAY_TIMESTAMPS option is supplied.

`#row '\t' column '\t' value`

`#timestamp '\t' row '\t' column '\t' value`

**`DISPLAY_TIMESTAMPS`**

The SELECT command displays one cell per line of output. Each line contains three tab delimited fields, row, column, and value. The DISPLAY_TIMESTAMPS option causes the cell timestamp to be included in the output as well. When this option is used, each output line will contain four tab delimited fields in the following order:

timestamp, row, column, value

**`KEYS_ONLY`**

The KEYS_ONLY option suppresses the output of the value. It is somewhat efficient because the option is processed by the RangeServers and not by the client. The value data is not transferred back to the client, only the key data.

**`NO_ESCAPE`**

The output format of a SELECT command comprises tab delimited lines, one cell per line, which is suitable for input to the LOAD DATA INFILE command. However, if the value portion of the cell contains either newline or tab characters, then it will confuse the LOAD DATA INFILE input parser. To prevent this from happening, newline, tab, and backslash characters are converted into two character escape sequences, described in the following table.

**Escape Sequences**

Character | Escape Sequence
---|---
`backslash \` |  `'\' '\'`
`newline \n` |  `'\' 'n'`
`tab \t` |  `'\' 't'`
`NUL` |  `'\' '0'`

The `NO_ESCAPE` option turns off this escaping mechanism.

**`RETURN_DELETES`**

The `RETURN_DELETES` option is used internally for debugging. When data is deleted from a table, the data is not actually deleted right away. A delete key will get inserted into the database and the delete will get processed and applied during subsequent scans. The `RETURN_DELETES` option will return the delete keys in addition to the normal cell keys and values. This option can be useful when used in conjuction with the DISPLAY_TIMESTAMPS option to understand how the delete mechanism works.

**`SCAN_AND_FILTER_ROWS`**

The `SCAN_AND_FILTER_ROWS` option can be used to improve query performance for queries that select a very large number of individual rows. The default algorithm for fetching a set of rows is to fetch each row individually, which involves a network roundtrip to a range server for each row. Supplying the `SCAN_AND_FILTER_ROWS` option tells the system to scan over the data and filter the requested rows at the range server, which will reduce the number of network roundtrips required when the number of rows requested is very large.

**EXAMPLES**

    SELECT * FROM test WHERE ('a' <= ROW <= 'e') and
                             '2008-07-28 00:00:02' < TIMESTAMP < '2008-07-28 00:00:07';
    SELECT * FROM test WHERE ROW =^ 'b';
    SELECT * FROM test WHERE (ROW = 'a' or ROW = 'c' or ROW = 'g');
    SELECT * FROM test WHERE ('a' < ROW <= 'c' or ROW = 'g' or ROW = 'c');
    SELECT * FROM test WHERE (ROW < 'c' or ROW > 'd');
    SELECT * FROM test WHERE (ROW < 'b' or ROW =^ 'b');
    SELECT * FROM test WHERE "farm","tag:abaca" < CELL <= "had","tag:abacinate";
    SELECT * FROM test WHERE "farm","tag:abaca" <= CELL <= "had","tag:abacinate";
    SELECT * FROM test WHERE CELL = "foo","tag:adactylism";
    SELECT * FROM test WHERE CELL =^ "foo","tag:ac";
    SELECT * FROM test WHERE CELL =^ "foo","tag:a";
    SELECT * FROM test WHERE CELL > "old","tag:abacate";
    SELECT * FROM test WHERE CELL >= "old","tag:abacate";
    SELECT * FROM test WHERE "old","tag:foo" < CELL >= "old","tag:abacate";
    SELECT * FROM test WHERE ( CELL = "maui","tag:abaisance" OR
                               CELL = "foo","tag:adage" OR
                               CELL = "cow","tag:Ab" OR
                               CELL =^ "foo","tag:acya");
    SELECT * FROM test INTO FILE "dfs:///tmp/foo";
    SELECT col2:"bird" from RegexpTest WHERE ROW REGEXP "http://.*";
    SELECT col1:/^w[^a-zA-Z]*$/ from RegexpTest WHERE ROW REGEXP "m.*\s\S";
    SELECT CELLS col1:/^w[^a-zA-Z]*$/ from RegexpTest WHERE VALUE REGEXP \"l.*e\";
    SELECT CELLS col1:/^w[^a-zA-Z]*$/ from RegexpTest WHERE ROW REGEXP \"^\\D+\"
        AND VALUE REGEXP \"l.*e\";";
    SELECT col FROM test WHERE col = "foo";
    SELECT col FROM test WHERE col =^ "prefix";
    SELECT tags:^prefix FROM test;

### SHOW CREATE TABLE

**EBNF**

    SHOW CREATE TABLE table_name

**DESCRIPTION**

The SHOW CREATE TABLE command shows the CREATE TABLE statement that creates the given table.

**EXAMPLE**

    hypertable> SHOW CREATE TABLE foo;
    CREATE TABLE foo (
      a,
      b,
      c,
      ACCESS GROUP bar (a, b),
      ACCESS GROUP default (c)
    );

### SHOW TABLES

**EBNF**

    SHOW TABLES

**DESCRIPTION**

The SHOW TABLES command lists only the tables in the current namespace.

**EXAMPLE**

    hypertable> SHOW TABLES;
    foo
    Test

### USE

**EBNF**

    USE namespace_name

**DESCRIPTION**

The USE command sets the current namespace. If _namespace_name_ starts with '/' it treats the _namespace_name_ as an absolute path, otherwise it considers it to be a sub-namespace relative to the current namespace.

**EXAMPLE**

    hypertable> USE "/";

    hypertable> CREATE NAMESPACE test;

    hypertable> USE "test";

    hypertable> CREATE NAMESPACE subtest;

    hypertable> USE "subtest";

    hypertable> GET LISTING;

    hypertable> USE "/test";

    hypertable> GET LISTING;
    subtest	(namespace)

    hypertable> USE "/";
    sys	(namespace)
    test	(namespace)
