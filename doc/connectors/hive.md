# Hive Connector

This document describes the Hypertable-Hive integration. [Hive](https://hive.apache.org/) is data warehouse infrastructure built on top of Hadoop. The Hypertable-Hive integration allows Hive QL statements to read from and write to Hypertable via SELECT and INSERT commands.

## Table of Contents

### Introduction

Hypertable integrates with Hive through its external storage handler interface. A hive storage handler for Hypertable is included in the Hypertable jar file which can be found in the `lib/java` directory of your Hypertable installation.
(_NOTE: The lib/java directory is empty when Hypertable is initially installed, but_ _gets populated the first time you start Hypertable on top of Hadoop HDFS_)

The Hypertable-Hive storage handler was overhauled in Hypertable version 0.9.8.1 to make it compatible with the latest version of Hive (0.13.0 or greater) and to add new features such as support for the binary column format and the ability to create and drop external Hypertable tables through the hive command interpreter. This document describes this new version of the storage handler as it exists in Hypertable version 0.9.8.1 and later releases. It has been tested with the following Hadoop/Hive combinations:

  * Cloudera CDH4 with Hive 0.13.1
  * Hortonworks HDP2.1 with Hive 0.13.0

The Hypertable storage handler should work with any Hadoop 2 based distribution and Hive 0.13.0 or later.

### Prerequisites

In order for Hive and the MapReduce framework to locate the Hypertable storage handler, the Hypertable jar file needs to be copied into HDFS under the same canonical path as the one in the local filesystem. To do that you need to execute the following commands:

    HT_JAR=`readlink -f /opt/hypertable/current/lib/java/hypertable.jar`

    hdfs dfs -rm -f $HT_JAR
    hdfs dfs -mkdir -p `dirname $HT_JAR`
    hdfs dfs -copyFromLocal $HT_JAR `dirname $HT_JAR`

The above commands only need to be run once each time Hypertable is upgraded. Once the hypertable.jar files is copied to the proper location in HDFS, the hive interpreter can be run as follows:

    # Commands read from a file
    hive --auxpath $HT_JAR -f <fname>

    # Commands supplied on the command line
    hive --auxpath $HT_JAR -e "<commands>"

### Table Create, Load, and Query

The first step required for this example is to create a _test_ namespace in Hypertable to parallel the _test_ database that we'll create in Hive:

    /opt/hypertable/current/bin/ht shell -e "create namespace test;"

The data file used in this example ([kv1.txt](http://cdn.hypertable.com/pub/kv1.txt)) contains data that looks like the following:

    ...
    481 val_481
    457 val_457
    98 val_98
    282 val_282
    197 val_197
    ...

Next we'll run the hive script shown below, but before we do that, some explanation is in order. The script starts by creating a _test_ database and then creates an external, non-native table called _hypertable_1_ backed by a Hypertable table _xyz_ using the Hypertable storage handler. It then creates a native table _pokes_ and populates it with the data from kv1.txt. Lastly, it populates _hypertable_1_ by performing an INSERT command that selects the rows from _pokes_ where _id_ column equals 98.

The mapping of columns from the Hive table _hypertable_1_ to the Hypertable table _xyz_ is specified by the `WITH SERDEPROPERTIES ('hypertable.columns.mapping' = ':key,poke:id')` clause. The comma separated fields after the '=' character parallel the column definitions in the CREATE TABLE statement.

The first field is `:key` which specifies the column which will be used as the row key in the Hypertable table _xyz_. There must be exactly one `:key` mapping (compound keys are not supported). In this case, the row key maps to the first column in _hypertable_1_ which is _id_. The second field is `poke:id` which indicates that the column with column family _poke_ and column qualifier "id" will map to the second column in _hypertable_1_ which is _poke_id_.

    CREATE DATABASE test;

    USE test;

    CREATE TABLE hypertable_1(id int, poke_id string)
      STORED BY 'org.hypertable.hadoop.hive.HypertableStorageHandler'
      WITH SERDEPROPERTIES ('hypertable.columns.mapping' = ':key,poke:id')
      TBLPROPERTIES ('hypertable.table.name' = '/test/xyz');

    CREATE TABLE pokes (id INT, poker STRING);

    LOAD DATA LOCAL INPATH 'kv1.txt' OVERWRITE INTO TABLE pokes;

    INSERT OVERWRITE TABLE hypertable_1 SELECT * FROM pokes WHERE id=98;

Now that the table _hypertable_1_ has been populated with data, we can dump its contents by running the following hive command:

    hive --auxpath $HT_JAR -e "USE test; SELECT * FROM hypertable_1;" 2> /dev/null

which will generate the following output:

    98    val_98

Now let's verify that the table _xyz_ was indeed created in Hypertable and was populated with data:

    $ /opt/hypertable/current/bin/ht shell

    hypertable> use test;

    hypertable> get listing;
    xyz

    hypertable> show create table xyz;
    CREATE TABLE xyz (
      poke,
      ACCESS GROUP default (poke)
    );

    hypertable> select * from xyz;
    98          poke:id  val_98
    98          poke:id  val_98

Note that the _xyz_ table contains two cells with row key 98. This is because there are two rows in the input file (kv1.txt) that contain "98 val_98" and Hive collapses them as duplicates.

### Mapping to an Existing Table

In this next example we'll create an external, non-native table in Hive called  _hypertable_2_ that maps to an existing table in Hypertable. We'll use the Hypertable table _xyz_ that was created in the previous example. For this mapping to work properly, the column data in the Hypertable table must match the data types specified for the Hive columns. In this example, the key column, _id_ , is specified with data type int. Hive uses string representation as the default encoding format for data types in the external non-native tables, so the contents of the corresponding Hypertable column (row key) must contain integers rendered as ASCII strings, which is exactly how the Hypertable table _xyz_ was populated in the previous exercise (see next section for how to specify binary encoding format).

    USE test;

    CREATE EXTERNAL TABLE hypertable_2(id int, poke_id string)
      STORED BY 'org.hypertable.hadoop.hive.HypertableStorageHandler'
      WITH SERDEPROPERTIES ('hypertable.columns.mapping' = ':key,poke:id')
      TBLPROPERTIES ('hypertable.table.name' = '/test/xyz');

The above Hive statements have the effect of creating a new Hive table _hypertable_2_ mapped to the table  _xyz_ in Hypertable. To verify that this mapping was successful, we can dump the contents of the _hypertable_2_ table with the following command:

    hive --auxpath $HT_JAR -e "USE test; SELECT * FROM hypertable_2;" 2> /dev/null

which will generate the following output:

    98    val_98

### Binary Format Column Data

Hive uses ASCII strings for the default encoding format of column data in external, non-native tables. This can be somewhat inefficient because it requires integer-to-string conversion and occupies more space. For example, the 4-byte integer value 1000000000 requires ten bytes to store as an ASCII string, instead of four. Hive solves this problem by allowing a binary encoding format to be specified for any column. This is accomplished by appending a "#b" suffix to the column name in the column mapping clause, as illustrated in the hive script below.

The data file used in this example ([employee.txt](http://cdn.hypertable.com/pub/employee.txt)) contains the following data:

    jimmy   21    20000.0
    jim     35    40000.0
    james   50    60000.0
    billy   25    25000.0
    bill    40    45000.0
    william 60    65000.0

    USE test;

    CREATE TABLE hypertable_binary(key string, age int, salary double)
      STORED BY 'org.hypertable.hadoop.hive.HypertableStorageHandler'
      WITH SERDEPROPERTIES ('hypertable.columns.mapping' = ':key,info:age#b,info:salary#b')
      TBLPROPERTIES ('hypertable.table.name' = '/test/employee');

    CREATE TABLE employee (name STRING, age INT, salary DOUBLE);

    LOAD DATA LOCAL INPATH 'employee.txt' OVERWRITE INTO TABLE employee;

    INSERT OVERWRITE TABLE hypertable_binary SELECT * FROM employee;

After running the above script, we can verify that the table _employee_ was indeed created in Hypertable and was populated with binary data:

    $ /opt/hypertable/current/bin/ht shell

    hypertable> use test;

    hypertable> show tables;
    employee
    xyz

    hypertable> show create table employee;
    CREATE TABLE employee (
      info,
      ACCESS GROUP default (info)
    );

    hypertable> select * from employee;
    bill        info:age \0\0\0(
    bill        info:salary @??\0\0\0\0\0
    billy       info:age    \0\0\0
    billy       info:salary @?j\0\0\0\0\0
    james       info:age    \0\0\02
    james       info:salary @?L\0\0\0\0\0
    jim         info:age    \0\0\0#
    jim         info:salary @?\0\0\0\0\0
    jimmy       info:age    \0\0\0
    jimmy       info:salary @ӈ\0\0\0\0\0
    william     info:age    \0\0\0<
    william     info:salary @?\0\0\0\0\0

We can now issue Hive QL commands to select rows of interest:

    $ hive --auxpath $HT_JAR -e "USE test; SELECT * FROM hypertable_binary WHERE age > 30; quit;" 2> /dev/null
    bill           40       45000.0
    james          50       60000.0
    jim            35       40000.0
    william        60       65000.0

    $ hive --auxpath $HT_JAR -e "USE test; SELECT * FROM hypertable_binary WHERE salary < 30000.0; quit;" 2> /dev/null
    billy          25      25000.0
    jimmy          21      20000.0

### Limitations

  * Whitespace should not be used in between entries in the `hypertable.columns.mapping` string, since these will be interperted as part of the column name, which is not what you want.

  * There is currently no way to access multiple versions of the same Hypertable cell. Hive can only access the latest version of a cell.

  * Binary format is not supported for the `:key` column

### Acknowledgements

We'd like to thank John Sichi for his help and suggestions in developing the initial Hypertable Storage Handler for Hive.
