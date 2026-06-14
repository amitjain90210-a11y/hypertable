# User Guide

## Table of Contents

### HQL Tutorial

**Introduction**

This tutorial shows you how to import a search engine query log into Hypertable, storing the data into tables with different primary keys, and how to issue queries against the tables. You'll need to download the data from [http://cdn.hypertable.com/pub/query-log.tsv.gz](http://cdn.hypertable.com/pub/query-log.tsv.gz):

    $ mkdir -p hql_tutorial
    $ cd hql_tutorial
    $ wget [http://cdn.hypertable.com/pub/query-log.tsv.gz](http://cdn.hypertable.com/pub/query-log.tsv.gz)

The next step is to make sure Hypertable is properly installed (see [Installation](../installation/index.md)) and then launch the service. Once you have Hypertable up and running, fire up an interactive session:

    $ ht shell

    Welcome to the hypertable command interpreter.
    For information about Hypertable, visit http://www.hypertable.org/ Type 'help' for a list of commands, or 'help shell' for a
    list of shell meta commands.

    hypertable>

Type "help" to display the list of valid HQL commands:

    hypertable> help

    USE ................ Sets the current namespace
    COMPACT ............ Schedules manual compaction
    CREATE NAMESPACE ... Creates a new namespace
    DROP NAMESPACE ..... Removes a namespace
    EXISTS TABLE ....... Check if table exists
    CREATE TABLE ....... Creates a table
    DELETE ............. Deletes all or part of a row from a table
    DESCRIBE TABLE ..... Displays a table's schema
    DROP TABLE ......... Removes a table
    RENAME TABLE ....... Renames a table
    DUMP TABLE ......... Create efficient backup file
    ALTER TABLE ........ Add/remove column family from existing table
    REBUILD INDICES .... Rebuilds a table's indices
    INSERT ............. Inserts data into a table
    LOAD DATA INFILE ... Loads data from a TSV input file into a table
    SELECT ............. Selects (and display) cells from a table
    SHOW CREATE TABLE .. Displays CREATE TABLE command used to create table
    SHOW TABLES ........ Displays only the list of tables in the current namespace
    STATUS ............. Checks system status
    GET LISTING ........ Displays the list of tables and namespace in the current namespace
    SET ................ Set system state variables

    Statements must be terminated with ';'.  For more information on a specific statement, type 'help <statement>', where <statement> is from the preceeding list.</statement></statement>

**USE**

First, open the root namespace. For an explanation of namespaces see [Namespaces](../overview.md#namespaces). To open the root namespace issue the following HQL command:

    hypertable> use "/";

**CREATE NAMESPACE**

Now create a namespace, _Tutorial_ , within which we'll create our tables:

    hypertable> create namespace "Tutorial";
    hypertable> use Tutorial;

**CREATE TABLE**

Now that we have created and opened the _Tutorial_ namespace we can create tables within it. In this tutorial we will be loading data into, and querying data from, two separate tables. The first table, QueryLogByUserID, will be indexed by the fields UserID+QueryTime and the second table, QueryLogByTimestamp, will be indexed by the fields QueryTime+UserID. Notice that any identifier that contains non-alphanumeric characters (e.g. '-') must be surrounded by quotes.

    hypertable> CREATE TABLE QueryLogByUserID ( Query, ItemRank, ClickURL );
    hypertable> CREATE TABLE QueryLogByTimestamp ( Query, ItemRank, ClickURL );

See the HQL Documentation: [CREATE TABLE](../reference_manual/hql.md#create-table) for complete syntax.

**SHOW TABLES**

Show all of the tables that exist in the current namespace:

    hypertable> show tables;
    QueryLogByUserID
    QueryLogByTimestamp

**SHOW CREATE TABLE**

Now, issue the SHOW CREATE TABLE command to make sure you got everything right. We didn't have to include the field called 'row' because we'll use that in our LOAD DATA INFILE command later:

    hypertable> show create table QueryLogByUserID;

    CREATE TABLE QueryLogByUserID (
        Query,
        ItemRank,
        ClickURL,
        ACCESS GROUP default (Query, ItemRank, ClickURL)
    );

And, notice that, by default, a single ACCESS GROUP named "default" is created. Access groups are a way to physically group columns together on disk. See the [CREATE TABLE](../reference_manual/hql.md#create-table) documentation for a more detailed description of access groups.

**LOAD DATA INFILE**

Now, let's load some data using the MySQL-like TAB delimited format (TSV). For that, we assume you have the example data in the file `query-log.tsv.gz`. This file includes an initial header line indicating the format of each line in the file by listing tab delimited column names. To inspect this file we first quit out of the Hypertable command line interpreter and then use the zcat program (requires gzip package) to display the contents of `query-log.tsv.gz`:

    hypertable> quit

    $ zcat query-log.tsv.gz
    #QueryTime      UserID  Query   ItemRank        ClickURL
    2008-11-13 00:01:30     2289203 kitchen counter in new orleans  10      http://www.era.com 2008-11-13 00:01:30     2289203 kitchen counter in new orleans  4       http://www.superpages.com 2008-11-13 00:01:30     2289203 kitchen counter in new orleans  5       http://www.superpages.com 2008-11-13 00:01:31     1958633 beads amethyst gemstone 1       http://www.gemsbiz.com 2008-11-13 00:01:31     3496052 chat
    2008-11-13 00:01:33     892003  photo example quarter doubled die coin  5       http://www.coinresource.com 2008-11-13 00:01:33     892003  photo example quarter doubled die coin  5       http://www.coinresource.com 2008-11-13 00:01:35     2251112 radio stations in buffalo       1       http://www.ontheradio.net 2008-11-13 00:01:37     1274922 fafsa renewal   1       http://www.fafsa.ed.gov 2008-11-13 00:01:37     1274922 fafsa renewal   1       http://www.fafsa.ed.gov 2008-11-13 00:01:37     441978  find phone numbers      1       http://www.anywho.com 2008-11-13 00:01:37     441978  find phone numbers      3       http://www.411.com 

...

Now let's load the data file `query-log.tsv.gz` into the table QueryLogByUserID. The row key is formulated by zero-padding the UserID field out to nine digits and concatenating the QueryTime field. The QueryTime field is used as the internal cell timestamp. To load the file, first jump back into the Hypertable command line interpreter and then issue the LOAD DATA INFILE command show below.

    $ ht shell
    ...
    hypertable> use Tutorial;
    hypertable> LOAD DATA INFILE ROW_KEY_COLUMN="%09UserID"+QueryTime TIMESTAMP_COLUMN=QueryTime "query-log.tsv.gz" INTO TABLE QueryLogByUserID;

    Loading 7,464,729 bytes of input data...

    0%   10   20   30   40   50   60   70   80   90   100%
    |----|----|----|----|----|----|----|----|----|----|
    ***************************************************
    Load complete.

      Elapsed time:  9.84 s
    Avg value size:  15.42 bytes
      Avg key size:  29.00 bytes
        Throughput:  4478149.39 bytes/s (764375.74 bytes/s)
       Total cells:  992525
        Throughput:  100822.73 cells/s
           Resends:  0

A quick inspection of the table shows:

    hypertable> select * from QueryLogByUserID limit 8;
    000000036 2008-11-13 10:30:46   Query   helena ga
    000000036 2008-11-13 10:31:34   Query   helena ga
    000000036 2008-11-13 10:45:23   Query   checeron s
    000000036 2008-11-13 10:46:07   Query   cheveron gas station
    000000036 2008-11-13 10:46:34   Query   cheveron gas station richmond virginia
    000000036 2008-11-13 10:48:56   Query   cheveron glenside road richmond virginia
    000000036 2008-11-13 10:49:05   Query   chevron glenside road richmond virginia
    000000036 2008-11-13 10:49:05   ItemRank        1
    000000036 2008-11-13 10:49:05   ClickURL        http://yp.yahoo.com 000000053 2008-11-13 15:18:21   Query   mapquest
    000000053 2008-11-13 15:18:21   ItemRank        1
    000000053 2008-11-13 15:18:21   ClickURL        http://www.mapquest.com   Elapsed time:  0.01 s
    Avg value size:  18.08 bytes
      Avg key size:  30.00 bytes
        Throughput:  43501.21 bytes/s
       Total cells:  12
        Throughput:  904.70 cells/s

Now let's load the data file query-log.tsv.gz into the table QueryLogByTimestamp. The row key is formulated by concatenating the QueryTime field with the nine digit, zero-padded UserID field. The QueryTime field is used as the internal cell timestamp.

    hypertable> LOAD DATA INFILE ROW_KEY_COLUMN=QueryTime+"%09UserID" TIMESTAMP_COLUMN=QueryTime "query-log.tsv.gz" INTO TABLE QueryLogByTimestamp;

    Loading 7,464,729 bytes of input data...

    0%   10   20   30   40   50   60   70   80   90   100%
    |----|----|----|----|----|----|----|----|----|----|
    ***************************************************
    Load complete.

      Elapsed time:  10.18 s
    Avg value size:  15.42 bytes
      Avg key size:  29.00 bytes
        Throughput:  4330913.20 bytes/s (739243.98 bytes/s)
       Total cells:  992525
        Throughput:  97507.80 cells/s
           Resends:  0

And a quick inspection of the table shows:

    hypertable> select * from QueryLogByTimestamp limit 4;
    2008-11-13 00:01:30 002289203 Query kitchen counter in new orleans
    2008-11-13 00:01:30 002289203 ItemRank 5
    2008-11-13 00:01:30 002289203 ClickURL http://www.superpages.com 2008-11-13 00:01:31 001958633 Query beads amethyst gemstone
    2008-11-13 00:01:31 001958633 ItemRank 1
    2008-11-13 00:01:31 001958633 ClickURL http://www.gemsbiz.com 2008-11-13 00:01:31 003496052 Query chat
    2008-11-13 00:01:33 000892003 Query photo example quarter doubled die coin
    2008-11-13 00:01:33 000892003 ItemRank 5
    2008-11-13 00:01:33 000892003 ClickURL http://www.coinresource.com   Elapsed time:  0.00 s
    Avg value size:  18.11 bytes
      Avg key size:  30.00 bytes
        Throughput:  287150.49 bytes/s
       Total cells:  19
        Throughput:  5969.21 cells/s

See the HQL Documentation: [LOAD DATA INFILE](../reference_manual/hql.md#load-data-infile) for complete syntax.

**SELECT**

Let's start by examining the QueryLogByUserID table. To select all of the data for user ID 003269359 we need to use the starts with operator =^. Remember that the row key is the concatenation of the user ID and the timestamp which is why we need to use the starts with operator.

    hypertable> select * from QueryLogByUserID where row =^ '003269359';
    003269359 2008-11-13 04:36:34 Query binibining pilipinas 2008 winners
    003269359 2008-11-13 04:36:34 ItemRank 5
    003269359 2008-11-13 04:36:34 ClickURL http://www.missosology.org 003269359 2008-11-13 04:37:34 Query pawee's kiss and tell
    003269359 2008-11-13 04:37:34 ItemRank 3
    003269359 2008-11-13 04:37:34 ClickURL http://www.missosology.org 003269359 2008-11-13 05:07:10 Query rn jobs in 91405
    003269359 2008-11-13 05:07:10 ItemRank 9
    003269359 2008-11-13 05:07:10 ClickURL http://91405.jobs.com 003269359 2008-11-13 05:20:22 Query rn jobs in 91405
    ...
    003269359 2008-11-13 09:42:49 Query wound ostomy rn training
    003269359 2008-11-13 09:42:49 ItemRank 11
    003269359 2008-11-13 09:42:49 ClickURL http://www.wocn.org 003269359 2008-11-13 09:46:50 Query pych nurse in encino tarzana hospital
    003269359 2008-11-13 09:47:18 Query encino tarzana hospital
    003269359 2008-11-13 09:47:18 ItemRank 2
    003269359 2008-11-13 09:47:18 ClickURL http://www.encino-tarzana.com 003269359 2008-11-13 09:52:42 Query encino tarzana hospital
    003269359 2008-11-13 09:53:08 Query alhambra hospital
    003269359 2008-11-13 09:53:08 ItemRank 1
    003269359 2008-11-13 09:53:08 ClickURL http://www.alhambrahospital.com   Elapsed time:  0.01 s
    Avg value size:  19.24 bytes
      Avg key size:  30.00 bytes
        Throughput:  2001847.79 bytes/s
       Total cells:  352
        Throughput:  40651.35 cells/s

The result set was fairly large (352 cells), so let's now try selecting just the queries that were issued by the user with ID 003269359 during the hour of 5am. To do this we need to add a TIMESTAMP predicate. Each cell has an internal timestamp and the TIMESTAMP predicate can be used to filter the results based on this timestamp.

    hypertable> select * from QueryLogByUserID where row =^ '003269359' AND "2008-11-13 05:00:00" <= TIMESTAMP < "2008-11-13 06:00:00";
    003269359 2008-11-13 05:07:10 Query rn jobs in 91405
    003269359 2008-11-13 05:07:10 ItemRank 9
    003269359 2008-11-13 05:07:10 ClickURL http://91405.jobs.com 003269359 2008-11-13 05:20:22 Query rn jobs in 91405
    003269359 2008-11-13 05:20:22 ItemRank 16
    003269359 2008-11-13 05:20:22 ClickURL http://www.careerbuilder.com 003269359 2008-11-13 05:34:02 Query usc university hospital
    003269359 2008-11-13 05:34:02 ItemRank 1
    003269359 2008-11-13 05:34:02 ClickURL http://www.uscuh.com 003269359 2008-11-13 05:37:01 Query rn jobs in san fernando valley
    003269359 2008-11-13 05:37:01 ItemRank 7
    003269359 2008-11-13 05:37:01 ClickURL http://www.medhunters.com 003269359 2008-11-13 05:46:22 Query northridge hospital
    003269359 2008-11-13 05:46:22 ItemRank 2
    003269359 2008-11-13 05:46:22 ClickURL http://northridgehospital.org 003269359 2008-11-13 05:53:34 Query valley presbyterian hospital
    003269359 2008-11-13 05:53:34 ItemRank 4
    003269359 2008-11-13 05:53:34 ClickURL http://www.hospital-data.com 003269359 2008-11-13 05:55:36 Query valley presbyterian hospital website
    003269359 2008-11-13 05:55:36 ItemRank 1
    003269359 2008-11-13 05:55:36 ClickURL http://www.valleypres.org 003269359 2008-11-13 05:59:24 Query mission community hospital
    003269359 2008-11-13 05:59:24 ItemRank 1
    003269359 2008-11-13 05:59:24 ClickURL http://www.mchonline.org   Elapsed time:  0.00 s
    Avg value size:  18.50 bytes
      Avg key size:  30.00 bytes
        Throughput:  2602086.44 bytes/s
       Total cells:  36
        Throughput:  53651.27 cells/s

Keep in mind that the internal cell timestamp is different than the one embedded in the row key. In this example, they both represent the same time. By specifying the TIMESTAMP_COLUMN option to LOAD DATA INFILE, we extracted the QueryTime field to be used as the internal cell timestamp. If we hadn't supplied that option, the system would have auto-assigned a timestamp. To display the internal cell timestamp, add the DISPLAY_TIMESTAMPS option:

    hypertable> select * from QueryLogByUserID limit 5 DISPLAY_TIMESTAMPS;
    2008-11-13 10:30:46.000000000   000000036 2008-11-13 10:30:46   Query   helena ga
    2008-11-13 10:31:34.000000000   000000036 2008-11-13 10:31:34   Query   helena ga
    2008-11-13 10:45:23.000000000   000000036 2008-11-13 10:45:23   Query   checeron s
    2008-11-13 10:46:07.000000000   000000036 2008-11-13 10:46:07   Query   cheveron gas station
    2008-11-13 10:46:34.000000000   000000036 2008-11-13 10:46:34   Query   cheveron gas station richmond virginia

      Elapsed time:  0.00 s
    Avg value size:  17.20 bytes
      Avg key size:  30.00 bytes
        Throughput:  207563.76 bytes/s
       Total cells:  5
        Throughput:  4397.54 cells/s

There is no index for the internal cell timestamps, so if we don't include a row =^ expression in our predicate, the system will do a full table scan. This is why we imported the data into a second table QueryLogByTimestamp. This table includes the timestamp as the row key prefix which allows us to efficiently query data over a time interval.

The following query selects all query log data for November 14th, 2008:

    hypertable> select * from QueryLogByTimestamp WHERE ROW =^ '2008-11-14';
    2008-11-14 00:00:00 001040178   Query   noodle tools
    2008-11-14 00:00:00 001040178   ItemRank        1
    2008-11-14 00:00:00 001040178   ClickURL        http://www.noodletools.com 2008-11-14 00:00:01 000264655   Query   games.myspace.com
    2008-11-14 00:00:01 000264655   ItemRank        1
    2008-11-14 00:00:01 000264655   ClickURL        http://games.myspace.com 2008-11-14 00:00:01 000527424   Query   franklinville schools new jersey
    2008-11-14 00:00:01 000527424   ItemRank        1
    2008-11-14 00:00:01 000527424   ClickURL        http://www.greatschools.net 2008-11-14 00:00:01 000632400   Query   lack of eye contact symptom of...
    ...
    2008-11-14 06:02:33 003676354   Query   baby 20showers
    2008-11-14 06:02:35 003378030   Query   task and responsibility matrix
    2008-11-14 06:02:35 003378030   ItemRank        2
    2008-11-14 06:02:35 003378030   ClickURL        http://im.ncsu.edu 2008-11-14 06:02:36 004578101   Query   jcpenneys
    2008-11-14 06:02:37 005120734   Query   ebay
    2008-11-14 06:02:40 000957500   Query   buccal fat size of ping pong ball

      Elapsed time:  2.37 s
    Avg value size:  15.36 bytes
      Avg key size:  30.00 bytes
        Throughput:  1709616.45 bytes/s
       Total cells:  89412
        Throughput:  37689.18 cells/s

And to select all query log data for November 14th, 2008 during the hour of 3am:

    hypertable> select * from QueryLogByTimestamp WHERE ROW =^ '2008-11-14 03';
    2008-11-14 03:00:00 002512415   Query   ny times
    2008-11-14 03:00:00 002512415   ItemRank        1
    2008-11-14 03:00:00 002512415   ClickURL        http://www.nytimes.com 2008-11-14 03:00:00 005294906   Query   kickmeto.fosi
    2008-11-14 03:00:00 005459226   Query   http://www.dickdyertoyota.com 2008-11-14 03:00:02 000637292   Query   days of our lives
    2008-11-14 03:00:02 000637292   ItemRank        3
    2008-11-14 03:00:02 000637292   ClickURL        http://www.nbc.com 2008-11-14 03:00:03 002675105   Query   ghetto superstar lyrics
    ...
    2008-11-14 03:59:52 002874080   ClickURL        http://www.paintball-discounters.com 2008-11-14 03:59:53 004292772   Query   drop down menu
    2008-11-14 03:59:55 005656539   Query   to buy indian hair to make wigs in new york
    2008-11-14 03:59:55 005656539   ItemRank        1
    2008-11-14 03:59:55 005656539   ClickURL        http://query.nytimes.com 2008-11-14 03:59:58 004318586   Query   myspace .com

      Elapsed time:  0.17 s
    Avg value size:  15.37 bytes
      Avg key size:  30.00 bytes
        Throughput:  2267099.06 bytes/s
       Total cells:  8305
        Throughput:  49967.51 cells/s

And finally, to select all query log data for November 14th, 2008 during the minute of 3:45am:

    hypertable> select * from QueryLogByTimestamp WHERE ROW =^ '2008-11-14 03:45';
    2008-11-14 03:45:00 003895650   Query   ks lottery.
    2008-11-14 03:45:00 003895650   ItemRank        2
    2008-11-14 03:45:00 003895650   ClickURL        http://www.lotterypost.com 2008-11-14 03:45:00 005036796   Query   [http://www.glasgowdailytimes](http://www.glasgowdailytimes) 10-20-2005
    2008-11-14 03:45:01 002863052   Query   map quest
    2008-11-14 03:45:01 005514285   Query   john bermeo
    2008-11-14 03:45:02 002394176   Query   http://www.eggseye.com 2008-11-14 03:45:02 003454227   Query   hawaiian weddig band
    2008-11-14 03:45:03 001006089   Query   brokers hiring loan officers in indiana
    2008-11-14 03:45:06 000844720   Query   latest design microsoft freeware
    ...
    2008-11-14 03:45:55 003920469   ItemRank        3
    2008-11-14 03:45:55 003920469   ClickURL        http://www.pennyblood.com 2008-11-14 03:45:56 002729906   Query   tryaold
    2008-11-14 03:45:56 003919348   Query   feathered draped fox fur mandalas
    2008-11-14 03:45:56 003919348   ItemRank        8
    2008-11-14 03:45:56 003919348   ClickURL        http://www.greatdreams.com 2008-11-14 03:45:56 004803968   Query   -

      Elapsed time:  0.02 s
    Avg value size:  15.71 bytes
      Avg key size:  30.00 bytes
        Throughput:  305030.80 bytes/s
       Total cells:  130
        Throughput:  6673.51 cells/s

See the HQL Documentation: [SELECT](../reference_manual/hql.md#select) for complete syntax.

**ALTER TABLE**

The ALTER TABLE command can be used to add and/or remove columns from a table. The following command will add a 'Notes' column in a new access group called 'extra' and will drop column 'ItemRank'.

    hypertable> ALTER TABLE QueryLogByUserID ADD(Notes, ACCESS GROUP extra(Notes)) DROP(ItemRank);

To verify the change, issue the SHOW CREATE TABLE command:

    hypertable> show create table QueryLogByUserID;

    CREATE TABLE QueryLogByUserID (
      Query,
      ClickURL,
      Notes,
      ACCESS GROUP default (Query, ClickURL),
      ACCESS GROUP extra (Notes)
    )

And to verify that the column no longer exists, issue the same SELECT statement we issued above (NOTE: the data for the column still exists in the filesystem, it will get lazily garbage collected).

    hypertable> select * from QueryLogByUserID limit 8;
    000000036 2008-11-13 10:30:46   Query   helena ga
    000000036 2008-11-13 10:31:34   Query   helena ga
    000000036 2008-11-13 10:45:23   Query   checeron s
    000000036 2008-11-13 10:46:07   Query   cheveron gas station
    000000036 2008-11-13 10:46:34   Query   cheveron gas station richmond virginia
    000000036 2008-11-13 10:48:56   Query   cheveron glenside road richmond virginia
    000000036 2008-11-13 10:49:05   Query   chevron glenside road richmond virginia
    000000036 2008-11-13 10:49:05   ClickURL        http://yp.yahoo.com 000000053 2008-11-13 15:18:21   Query   mapquest
    000000053 2008-11-13 15:18:21   ClickURL        http://www.mapquest.com   Elapsed time:  0.00 s
    Avg value size:  21.50 bytes
      Avg key size:  30.00 bytes
        Throughput:  140595.14 bytes/s
       Total cells:  10
        Throughput:  2730.00 cells/s

See HQL Documentation: [ALTER TABLE](../reference_manual/hql.md#alter-table) for complete syntax.

**INSERT & DELETE**

Now let's augment the QueryLogByUserID table by adding some information in the Notes column for a few of the queries:

    hypertable> INSERT INTO QueryLogByUserID VALUES
    ("000019058 2008-11-13 07:24:43", "Notes", "animals"),
    ("000019058 2008-11-13 07:57:16", "Notes", "food"),
    ("000019058 2008-11-13 07:59:36", "Notes", "gardening");

      Elapsed time:  0.01 s
    Avg value size:  6.67 bytes
       Total cells:  3
        Throughput:  298.36 cells/s
           Resends:  0

Notice the new data by querying the affected row:

    hypertable> select * from QueryLogByUserID where row =^ '000019058';
    000019058 2008-11-13 07:24:43   Query   tigers
    000019058 2008-11-13 07:24:43   Notes   animals
    000019058 2008-11-13 07:57:16   Query   bell peppers
    000019058 2008-11-13 07:57:16   Notes   food
    000019058 2008-11-13 07:58:24   Query   bell peppers
    000019058 2008-11-13 07:58:24   ClickURL        http://agalternatives.aers.psu.edu 000019058 2008-11-13 07:59:36   Query   growing bell peppers
    000019058 2008-11-13 07:59:36   Query   growing bell peppers
    000019058 2008-11-13 07:59:36   ClickURL        http://www.farm-garden.com 000019058 2008-11-13 07:59:36   ClickURL        http://www.organicgardentips.com 000019058 2008-11-13 07:59:36   Notes   gardening
    000019058 2008-11-13 12:31:02   Query   tracfone
    000019058 2008-11-13 12:31:02   ClickURL        http://www.tracfone.com   Elapsed time:  0.00 s
    Avg value size:  16.38 bytes
      Avg key size:  30.00 bytes
        Throughput:  162271.26 bytes/s
       Total cells:  13
        Throughput:  3498.39 cells/s

Now try deleting one of the notes we just added

    hypertable> delete Notes from QueryLogByUserID where ROW ="000019058 2008-11-13 07:24:43";

      Elapsed time:  0.00 s
       Total cells:  1
        Throughput:  256.41 cells/s
           Resends:  0

And verify that the cell was, indeed, deleted:

    hypertable> select * from QueryLogByUserID where row =^ '000019058';
    000019058 2008-11-13 07:24:43   Query   tigers
    000019058 2008-11-13 07:57:16   Query   bell peppers
    000019058 2008-11-13 07:57:16   Notes   food
    000019058 2008-11-13 07:58:24   Query   bell peppers
    000019058 2008-11-13 07:58:24   ClickURL        http://agalternatives.aers.psu.edu 000019058 2008-11-13 07:59:36   Query   growing bell peppers
    000019058 2008-11-13 07:59:36   Query   growing bell peppers
    000019058 2008-11-13 07:59:36   ClickURL        http://www.farm-garden.com 000019058 2008-11-13 07:59:36   ClickURL        http://www.organicgardentips.com 000019058 2008-11-13 07:59:36   Notes   gardening
    000019058 2008-11-13 12:31:02   Query   tracfone
    000019058 2008-11-13 12:31:02   ClickURL        http://www.tracfone.com   Elapsed time:  0.00 s
    Avg value size:  16.38 bytes
      Avg key size:  30.00 bytes
        Throughput:  162271.26 bytes/s
       Total cells:  12
        Throughput:  3498.39 cells/s

See the HQL Documentation: [INSERT](../reference_manual/hql.md#insert) and the HQL Documentation: [DELETE](../reference_manual/hql.md#delete) for complete syntax.

**DROP TABLE**

The DROP TABLE command is used to remove tables from the system. The IF EXISTS option prevents the system from throwing an error if the table does not exist:

    hypertable> drop table IF EXISTS foo;

Let's remove one of the example tables:

    hypertable> drop table QueryLogByUserID;
    hypertable> show tables;
    QueryLogByTimestamp

Then let's remove the other:

    hypertable> drop table QueryLogByTimestamp;
    hypertable> show tables;

**GET LISTING & DROP NAMESPACE**

Now, we want to get rid of the _Tutorial_ namespace and verify that we have:

    hypertable> use "/";

    hypertable> get listing;
    Tutorial        (namespace)
    sys     (namespace)

    hypertable> drop namespace Tutorial;

    hypertable> get listing;
    sys     (namespace)

The _sys_ namespace is used by the Hypertable system and should not be used to contain user tables.

Note that a namespace must be empty (ie must not contain any sub-namespaces or tables) before you can drop it. In this case since we had already dropped the _QueryLogByUserID_ and _QueryLogByTimestamp_ tables, we could go ahead and drop the _Tutorial_ namespace.

### Secondary Indices

Hypertable contains support for secondary indices. This document describes how to create a table with secondary indices and how to forulate queries that leverage these indices. Secondary indices can be specified in the [CREATE TABLE](../reference_manual/hql.md#create-table) statement and can be added or dropped with the [ALTER TABLE](../reference_manual/hql.md#alter-table) command. Indices added with the ALTER TABLE command are not populated with existing table data. To populate indices added with ALTER TABLE, you must run the [REBUILD INDICES](../reference_manual/hql.md#rebuild-indices) command. Hypertable supports two types of indices: 1) _value_ indices, and 2) _qualifier_ indices. Value indices index column value data and qualifier indices index column qualifier data. See the [CREATE TABLE](../reference_manual/hql.md#create-table) documentation for more information on how to specify each type of index. The scripts and data files for these examples can be in the archive [secondary-indices.tgz](http://hypertable.com/pub/secondary-indices.tgz). All of the example queries show were run against a table with the following schema and loaded with [products.tsv](http://hypertable.com/pub/products.tsv).

    CREATE TABLE products (
      title,
      section,
      info,
      category,
      INDEX section,
      INDEX info,
      QUALIFIER INDEX info,
      QUALIFIER INDEX category
    );

##  Queries against the _value index_

One important difference between secondary index queries and normal table scan queries is that with secondary index queries, the SELECT statement behaves like SQL SELECT in that the WHERE predicate acts as a boolean selector of rows and the columns listed after the SELECT keyword act as a projection of the selected rows. In other words, you can project an arbitrary set of columns that don't necessarily have to be referenced in the WHERE predicate.

**Exact match**

Select the _title_ column of all rows whose _section_ column contains exactly "books".

    SELECT title FROM products WHERE section = "books";

    0307743659	title	The Shining Mass Market Paperback
    0321321928	title	C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    0321776402	title	C++ Primer Plus (6th Edition) (Developer's Library)

Select the _title_ column of all rows that contain an _info:actor_ column containing exactly "Jack Nicholson".

    SELECT title FROM products WHERE info:actor = "Jack Nicholson";

    B00002VWE0	title	 Five Easy Pieces (1970)
    B002VWNIDG	title	The Shining (1980)

**Prefix match**

Select the _title_ and _info:publisher_ columns of all rows that contain an _info:publisher_ column whose value starts with "Addison-Wesley".

    SELECT title,info:publisher FROM products WHERE info:publisher =^ 'Addison-Wesley';
    SELECT title,info:publisher FROM products WHERE info:publisher =~ /^Addison-Wesley/;

    0321321928	title	C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    0321321928	info:publisher	Addison-Wesley Professional; 1 edition (March 10, 2005)
    0321776402	title	C++ Primer Plus (6th Edition) (Developer's Library)
    0321776402	info:publisher	Addison-Wesley Professional; 6 edition (October 28, 2011)

**Regular expression match**

Select the _title_ and _info:publisher_ columns of all rows that contain an _info:author_ column whose value starts with "Stephen " followed by either a 'P' or 'K' character.

    SELECT title,info:author FROM products WHERE info:author =~ /^Stephen [PK]/;
    SELECT title,info:author FROM products WHERE Regexp(info:author, '^Stephen [PK]');

    0307743659	title	The Shining Mass Market Paperback
    0307743659 info:author Stephen King
    0321776402	title	C++ Primer Plus (6th Edition) (Developer's Library)
    0321776402	info:author	Stephen Prata

##  Queries against the _qualifier index_

Like the value index queries, the qualifier index queries have the traditional SQL select/project semantics.

**Exact match**

Select the _title_ column of all rows that contain an _info:studio_ column.

    SELECT title FROM products WHERE Exists(info:studio);

    B00002VWE0	title	Five Easy Pieces (1970)
    B000Q66J1M	title	2001: A Space Odyssey [Blu-ray]
    B002VWNIDG	title	The Shining (1980)

**Regular expression match**

Select the _title_ column of all rows that contain a _category_ column with qualifier that starts with "/Movies".

    SELECT title FROM products WHERE Exists(category:/^\/Movies/);

    B00002VWE0	title	Five Easy Pieces (1970)
    B000Q66J1M	title	2001: A Space Odyssey [Blu-ray]
    B002VWNIDG	title	The Shining (1980)

Select the _title_ column of all rows that contain a _category_ column with qualifier that starts with "/Books" followed at some point later with "Programming".

    SELECT title FROM products WHERE Exists(category:/^\/Books.*Programming/);

    0321321928	title	C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    0321776402	title	C++ Primer Plus (6th Edition) (Developer's Library)

##  Boolean operators

The boolean operators AND and OR can be used to combine column predicates. The boolean AND operator can also combine column predicates and ROW intervals.

**OR operator**

Select the _title_ column of all rows that contain an _info:author_ column that starts with "Stephen P" or contain an _info:publisher_ column that starts with "Anchor".

    SELECT title FROM products WHERE info:author =~ /^Stephen P/ OR info:publisher =^ "Anchor";
    SELECT title FROM products WHERE info:author =~ /^Stephen P/ OR info:publisher =~ /^Anchor/;

    0307743659	title	The Shining Mass Market Paperback
    0321776402	title	C++ Primer Plus (6th Edition) (Developer's Library)

**AND operator**

Select the _title_ column of all rows that contain an _info:author_ column that starts with "Stephen " followed by either the letter 'P' or 'K' and contain an _info:publisher_ column that starts witht "Anchor"

    SELECT title FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =^ "Anchor";
    SELECT title FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =~ /^Anchor/;

    0307743659	title	The Shining Mass Market Paperback

Select the _title_ column of all rows whose row key is greater than 'B00002VWE0' and that contain an _info:actor_ column containing exactly "Jack Nicholson".

    SELECT title FROM products WHERE ROW > 'B00002VWE0' AND info:actor = 'Jack Nicholson';

    B002VWNIDG	title	The Shining (1980)

Select the _title_ column of all rows whose row key starts with 'B' and that contain an _info:actor_ column containing exactly "Jack Nicholson".

    SELECT title FROM products WHERE ROW =^ 'B' AND info:actor = 'Jack Nicholson';

    B00002VWE0	title	Five Easy Pieces (1970)
    B002VWNIDG	title	The Shining (1980)

##  Limitations

  1. Each secondary index can only contain data for a single column. Compound indices are not supported.
  2. For value index queries, all column predicate values must have a fixed prefix.

This means that regular expression queries must start with the '^' character and be followed by some fixed string of non-meta characters.

  3. All column predicates must leverage the same index

Either all column predicates must be of the form:

         Exists(<column-specifier>)

or

         <column-specifier> [=,=~,=^] <value-pattern>

You cannot mix-and-match the two. For example, the following query will not leverage the secondary indexes and will result int a full table scan:

         SELECT * FROM products WHERE Exists(info:studio) OR info:actor = "Jack Nicholson";

  4. Boolean operators cannot be mixed

Either all boolean operators must be AND, or all boolean operators must be OR.

### Hadoop MapReduce

In order to run this example, Hadoop needs to be installed and HDFS and the MapReduce framework needs to be up and running. The remainder of this section assumes a CDH4 installation, change command lines accordingly for your distribution.

Hypertable ships with a jar file, `hypertable.jar` that contains Hadoop InputFormat and OutputFormat classes that allow MapReduce programs to directly read from and write to tables in Hypertable. In this section, we walk you through an example MapReduce program, WikipediaWordCount, that tokenizes articles in a table called _wikipedia_ that has been loaded with a Wikipedia dump. It reads the _article_ column, tokenizes it, and populates the _word_ column of the same table. Each unique word in the article turns into a qualified column and the value is the number of times the word appears in the article.

**Setup**

First, exit the Hypertable command line interpreter and download the Wikipedia dump, for example:

    $ wget http://cdn.hypertable.com/pub/wikipedia.tsv.gz

Next, jump back into the Hypertable command line interpreter and create the _wikipedia_ table by executing the HQL commands show below.

    CREATE NAMESPACE test;
    USE test;
    DROP TABLE IF EXISTS wikipedia;
    CREATE TABLE wikipedia (
           title,
           id,
           username,
           article,
           word
    );

Now load the compressed Wikipedia dump file directly into the wikipedia table by issuing the following HQL commands:

    hypertable> LOAD DATA INFILE "wikipedia.tsv.gz" INTO TABLE wikipedia;

    Loading 638,058,135 bytes of input data...

    0%   10   20   30   40   50   60   70   80   90   100%
    |----|----|----|----|----|----|----|----|----|----|
    ***************************************************
    Load complete.

      Elapsed time:  78.28 s
    Avg value size:  1709.59 bytes
      Avg key size:  24.39 bytes
        Throughput:  25226728.63 bytes/s (8151017.58 bytes/s)
       Total cells:  1138847
        Throughput:  14548.46 cells/s
           Resends:  8328

**Example**

In this example, we'll be running the WikipediaWordCount program which is included in the `hypertable-examples.jar` file included in the binary package installation. The following is a link to the source code for this program.

[WikipediaWordCount.java](https://github.com/hypertable/hypertable/blob/master/examples/java/org/hypertable/examples/hadoop/mapreduce/WikipediaWordCount.java)

To get an idea of what the data looks like, try the following select:

    hypertable> select * from wikipedia where row =^ "Addington";
    Addington, Buckinghamshire      title   Addington, Buckinghamshire
    Addington, Buckinghamshire      id      377201
    Addington, Buckinghamshire      username        Roleplayer
    Addington, Buckinghamshire      article {{infobox UK place \n|country = England\n|latitude=51.95095\n|longitude=-0.92177\n|official_name= Addington\n| population = 145 ...

Now exit from the Hypertable command line interpreter and run the WikipediaWordCount MapReduce program:

    hypertable> quit

    HYPERTABLE_HOME=/opt/hypertable/current
    VERSION=`$HYPERTABLE_HOME/bin/ht version | head -1 | cut -f1 -d' '`
    env HADOOP_CLASSPATH=$HYPERTABLE_HOME/lib/java/hypertable.jar:$HYPERTABLE_HOME/lib/java/libthrift.jar hadoop jar $HYPERTABLE_HOME/lib/java/hypertable-examples.jar org.hypertable.examples.WikipediaWordCount -libjars $HYPERTABLE_HOME/lib/java/hypertable.jar,$HYPERTABLE_HOME/lib/java/libthrift.jar -Dmapred.reduce.tasks=6 --columns=article --namespace=test

To verify that it worked, jump back into the Hypertable command line interpreter and try selecting for the _word_ column:

    $ ht shell

    hypertable> select word from wikipedia where row =^ "Addington";
    ...
    Addington, Buckinghamshire      word:A  1
    Addington, Buckinghamshire      word:Abbey      1
    Addington, Buckinghamshire      word:Abbotts    1
    Addington, Buckinghamshire      word:According  1
    Addington, Buckinghamshire      word:Addington  6
    Addington, Buckinghamshire      word:Adstock    1
    Addington, Buckinghamshire      word:Aston      1
    Addington, Buckinghamshire      word:Aylesbury  3
    Addington, Buckinghamshire      word:BUCKINGHAM 1
    Addington, Buckinghamshire      word:Bayeux     2
    Addington, Buckinghamshire      word:Bene       1
    Addington, Buckinghamshire      word:Bishop     1
    ...

### Hadoop Streaming MapReduce

In order to run this example, Hadoop needs to be installed and HDFS and the MapReduce framework needs to be up and running. The remainder of this section assumes a CDH4 installation, change command lines accordingly for your distribution.

In this example, we'll be running a Hadoop Streaming MapReduce job that uses a Bash script as the mapper and a Bash script as the reducer. Like the example in the previous section, the programs operate on a table called _wikipedia_ that has been loaded with a Wikipedia dump.

**Setup**

First, exit the Hypertable command line interpreter and download the Wikipedia dump, for example:

    $ wget http://cdn.hypertable.com/pub/wikipedia.tsv.gz

Next, jump back into the Hypertable command line interpreter and create the _wikipedia_ table by executing the HQL commands show below.

    CREATE NAMESPACE test;
    USE test;
    DROP TABLE IF EXISTS wikipedia;
    CREATE TABLE wikipedia (
           title,
           id,
           username,
           article,
           word
    );

Now load the compressed Wikipedia dump file directly into the wikipedia table by issuing the following HQL commands:

    hypertable> LOAD DATA INFILE "wikipedia.tsv.gz" INTO TABLE wikipedia;

    Loading 638,058,135 bytes of input data...

    0%   10   20   30   40   50   60   70   80   90   100%
    |----|----|----|----|----|----|----|----|----|----|
    ***************************************************
    Load complete.

      Elapsed time:  78.28 s
    Avg value size:  1709.59 bytes
      Avg key size:  24.39 bytes
        Throughput:  25226728.63 bytes/s (8151017.58 bytes/s)
       Total cells:  1138847
        Throughput:  14548.46 cells/s
           Resends:  8328

The mapper script (`tokenize-article.sh`) and the reducer script (reduce-word-counts.sh) are show below.

**Example**

The following script, `tokenize-article.sh`, will be used as the mapper script.

    #!/usr/bin/env bash

    IFS="   "
    read name column article

    while [ $? == 0 ] ; do

      if [ "$column" == "article" ] ; then

        # Strip punctuation
        stripped_article=`echo $article | awk 'BEGIN { FS="\t" } { print $NF }' | tr "\!\"#\$&'()*+,-./:;<=>?@[\\\\]^_\{|}~" " " | tr -s " "` ;

        # Split article into words
        echo $stripped_article | awk -v name="$name" 'BEGIN { article=name; FS=" "; } { for (i=1; i<=NF; i++) printf "%s\tword:%s\t1\n", article, $i; }' ;

      fi

      # Read another line
      read name column article

    done
    exit 0

The following script, `reduce-word-counts.sh`, will be used as the reducer script.

    #!/usr/bin/env bash

    last_article=
    last_word=
    let total=0

    IFS="   "
    read article word count

    while [ $? == 0 ] ; do
        if [ "$article" == "$last_article" ] && [ "$word" == "$last_word" ] ; then
            let total=$count+total
        else
            if [ "$last_word" != "" ]; then
                echo "$last_article $last_word      $total"
            fi
            let total=$count
            last_word=$word
            last_article=$article
        fi
        read article word count
    done

    if [ $total -gt 0 ] ; then
        echo "$last_article $last_word      $total"
    fi
    exit 0

To populate the _word_ column of the _wikipedia_ table by tokenizing the _article_ column using the above mapper and reduce script, issue the following command:

    hypertable> quit

    $ hadoop jar $CDH_HOME/lib/hadoop-0.20-mapreduce/contrib/streaming/hadoop-streaming-2.0.0-mr1-cdh4.7.0.jar \
    -libjars /opt/hypertable/current/lib/java/hypertable.jar,/opt/hypertable/current/lib/java/libthrift.jar \
    -Dhypertable.mapreduce.namespace=test \
    -Dhypertable.mapreduce.input.table=wikipedia \
    -Dhypertable.mapreduce.output.table=wikipedia \
    -mapper /home/doug/tokenize-article.sh \
    -combiner /home/doug/reduce-word-counts.sh \
    -reducer /home/doug/reduce-word-counts.sh \
    -file /home/doug/tokenize-article.sh \
    -file /home/doug/reduce-word-counts.sh \
    -inputformat org.hypertable.hadoop.mapred.TextTableInputFormat \
    -outputformat org.hypertable.hadoop.mapred.TextTableOutputFormat \
    -input wikipedia -output wikipedia

**Input/Output Configuration Properties**

The following table lists the job configuration properties that are used to specify, among other things, the input table, output table, and scan specification. These properties can be supplied to a streaming MapReduce job with -D _property_ _=value_ arguments.

**Input/Output Configuration Properties**

Property | Description | Example Value
---|---|---
hypertable.mapreduce.namespace |  Namespace for both input and output table |  /test
hypertable.mapreduce.input.namespace |  Namespace for input table |  /test/intput
hypertable.mapreduce.input.table |  Input table name |  wikipedia
hypertable.mapreduce.input.scan_spec.columns |  Comma separated list of input columns |  id,title
hypertable.mapreduce.input.scan_spec.value_regexps |  Value regex |  l.*e\";
hypertable.mapreduce.input.scan_spec.options |  Input WHERE clause options. These options (i.e. LIMIT, OFFSET) are evaluated for each single job |  MAX_VERSIONS 1 KEYS_ONLY
hypertable.mapreduce.input.scan_spec.row_interval |  Input row interval |  Dog <= ROW < Kitchen
hypertable.mapreduce.input.scan_spec.timestamp_interval |  Timestamp filter |  TIMESTAMP >= 2011-11-21
hypertable.mapreduce.input.include_timestamps |  Emit integer timestamp as the
1st field (nanoseconds since epoch) |  true
hypertable.mapreduce.output.namespace |  Namespace containing output table |  /test/output
hypertable.mapreduce.output.table |  Output table name |  wikipedia
hypertable.mapreduce.output.mutator_flags |  flags parameter passed to mutator constructor (1 = NO_LOG_SYNC) |  1
hypertable.mapreduce.thriftbroker.framesize |  sets the ThriftClient framesize (in bytes); the default is 16 MB |  20971520
hypertable.mapreduce.thriftbroker.host |  Hostname of ThriftBroker. Can be a [host specification pattern](../tools/ht_ssh.md#host-specification-pattern) in which case one of the matching hosts will be chosen at random. |  localhost
hypertable.mapreduce.thriftbroker.port |  ThriftBroker port |  15867

**Column Selection**

To run a MapReduce job over a subset of columns from the input table, specify a comma separated list of columns in the hypertable.mapreduce.input.scan_spec.columns Hadoop configuration property. For example,

    $ hadoop jar /usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
    -libjars /opt/hypertable/current/lib/java/hypertable.jar,/opt/hypertable/current/lib/java/libthrift.jar \
    -Dhypertable.mapreduce.namespace=test \
    -Dhypertable.mapreduce.input.table=wikipedia \
    -Dhypertable.mapreduce.input.scan_spec.columns="id,title" \
    -mapper /bin/cat -reducer /bin/cat \
    -inputformat org.hypertable.hadoop.mapred.TextTableInputFormat \
    -input wikipedia -output wikipedia2

**Timestamps**

To filter the input table with a timestamp predicate, specify the timestamp predicate in the hypertable.mapreduce.input.scan_spec.timestamp_interval Hadoop configuration property. The timestamp predicate is specified using the same format as the timestamp predicate in the WHERE clause of the [SELECT](../reference_manual/hql.md#select) statement, as illustrated in the following examples:

  * TIMESTAMP < 2010-08-03 12:30:00
  * TIMESTAMP >= 2010-08-03 12:30:00
  * 2010-08-01 <= TIMESTAMP <= 2010-08-09

To preserve the timestamps from the input table, set the hypertable.mapreduce.input.include_timestamps Hadoop configuration property to _true_. This will cause the TextTableInputFormat class to produce an additional field (field 0) that represents the timestamp as nanoseconds since the epoch. The following example illustrates how to pass a timestamp predicate into a Hadoop Streaming MapReduce program.

    $ hadoop jar /usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
    -libjars /opt/hypertable/current/lib/java/hypertable.jar,/opt/hypertable/current/lib/java/libthrift.jar \
    -Dhypertable.mapreduce.namespace=test \
    -Dhypertable.mapreduce.input.table=wikipedia \
    -Dhypertable.mapreduce.output.table=wikipedia2 \
    -Dhypertable.mapreduce.input.scan_spec.columns="id,title" \
    -Dhypertable.mapreduce.input.scan_spec.timestamp_interval="2010-08-01 <= TIMESTAMP <= 2010-08-09" \
    -Dhypertable.mapreduce.input.include_timestamps=true \
    -mapper /bin/cat -reducer /bin/cat \
    -inputformat org.hypertable.hadoop.mapred.TextTableInputFormat \
    -outputformat org.hypertable.hadoop.mapred.TextTableOutputFormat \
    -input wikipedia -output wikipedia2

**Row Intervals**

To restrict the MapReduce to a specific row interval of the input table, a row range can be specified with the hypertable.mapreduce.input.scan_spec.row_interval Hadoop configuration property. The row interval predicate is specified using the same format as the timestamp predicate in the WHERE clause of the SELECT statement, as illustrated in the following examples:

  * ROW < foo
  * ROW >= bar
  * bar <= ROW <= 'foo;'

The following example illustrates how a row interval is passed into a Hadoop Streaming MapReduce program.

    $ hadoop jar /usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
    -libjars /opt/hypertable/current/lib/java/hypertable.jar,/opt/hypertable/current/lib/java/libthrift.jar \
    -Dhypertable.mapreduce.namespace=test \
    -Dhypertable.mapreduce.input.table=wikipedia \
    -Dhypertable.mapreduce.output.table=wikipedia2 \
    -Dhypertable.mapreduce.input.scan_spec.columns="id,title" \
    -Dhypertable.mapreduce.input.scan_spec.row_interval="Dog <= ROW <= Kitchen" \
    -mapper /bin/cat -reducer /bin/cat \
    -inputformat org.hypertable.hadoop.mapred.TextTableInputFormat \
    -outputformat org.hypertable.hadoop.mapred.TextTableOutputFormat \
    -input wikipedia -output wikipedia2

**Options**

A subset of the WHERE clause options of the [HQL SELECT](http://www.hypertable.org/hql/select.html) statement can be specified by supplying the options with the hypertable.mapreduce.input.scan_spec.options Hadoop configuration property. The following options are supported:

  * MAX_VERSIONS
  * CELL_LIMIT
  * KEYS_ONLY

The following example illustrates how to pass options to a Hadoop Streaming MapReduce program.

    $ hadoop jar /usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
    -libjars /opt/hypertable/current/lib/java/hypertable.jar,/opt/hypertable/current/lib/java/libthrift.jar \
    -Dhypertable.mapreduce.namespace=test \
    -Dhypertable.mapreduce.input.table=wikipedia \
    -Dhypertable.mapreduce.output.table=wikipedia2 \
    -Dhypertable.mapreduce.input.scan_spec.options="MAX_VERSIONS 1 KEYS_ONLY CELL_LIMIT 2" \
    -mapper /bin/cat -reducer /bin/cat \
    -inputformat org.hypertable.hadoop.mapred.TextTableInputFormat \
    -outputformat org.hypertable.hadoop.mapred.TextTableOutputFormat \
    -input wikipedia -output wikipedia2

### Regular Expression Filtering

Hypertable supports filtering of data using regular expression matching on the rowkey, column qualifiers and value. Hypertable uses RE2 for regular expression matching, the complete supported syntax can be found in the [RE2 Syntax](http://code.google.com/p/re2/wiki/Syntax) document.

**Example**

In this example we'll use a DMOZ dataset which contains title, description and a bunch of topic tags for a set of URLs. The domain components of the URL have been reversed so that URLs from the same domain sort together. In the schema, the rowkey is a URL and the title, description and topic are column families. Heres a small sample from the dataset:

    com.awn.www     Title   Animation World Network com.awn.www     Description     Provides information resources to the international animation community. Features include searchable database archives, monthly magazine, web animation guide, the Animation Village, discussion forums and other useful resources.
    com.awn.www     Topic:Arts
    com.awn.www     Topic:Animation

Exit the hypertable shell and download the dataset, which is in the .tsv.gz format which can be directly loaded into Hypertable without unzipping:

    hypertable> quit

    $ wget [http://cdn.hypertable.com/pub/dmoz.tsv.gz](http://cdn.hypertable.com/pub/dmoz.tsv.gz)

Jump back into the hypertable shell and create the dmoz table as follows:

    ht shell

    hypertable> USE "/";
    hypertable> CREATE TABLE dmoz(Description, Title, Topic, ACCESS GROUP topic(Topic));
    hypertable> LOAD DATA INFILE "dmoz.tsv.gz" INTO TABLE dmoz;

    Loading 412,265,627 bytes of input data...

    0%   10   20   30   40   50   60   70   80   90   100%
    |----|----|----|----|----|----|----|----|----|----|
    ***************************************************
    Load complete.

      Elapsed time:  242.26 s
    Avg value size:  15.09 bytes
      Avg key size:  24.76 bytes
        Throughput:  6511233.28 bytes/s (1701740.27 bytes/s)
       Total cells:  39589037
        Throughput:  163414.69 cells/s
           Resends:  144786

In the following queries we limit the number of rows returned to 2 for brevity. Suppose you want a subset of the URLs from the domain inria.fr where the first component of the domain doesn't start with the letter 'a', you could run:

    hypertable> SELECT Title FROM dmoz WHERE ROW REGEXP "fr\.inria\.[^a]" LIMIT 2 REVS=1 KEYS_ONLY;

    fr.inria.caml
    fr.inria.caml/pub/docs/oreilly-book

To look at all topics which start with write (case insensitive):

    hypertable> SELECT Topic:/(?i)^write/ FROM dmoz LIMIT 2;

    13.141.244.204/writ_den Topic:Writers_Resources
    ac.sms.www/clubpage.asp?club=CL001003004000301311       Topic:Writers_Resources

The next example shows how to query for data where the description contains the word game followed by either foosball or halo:

    hypertable> SELECT CELLS Description FROM dmoz WHERE VALUE REGEXP "(?i:game.*(foosball|halo)\s)" LIMIT 2 REVS=1;

    com.armchairempire.www/Previews/PCGames/planetside.htm  Description     Preview by Mr. Nash. "So, on the one side the game is sounding pretty snazzy, on the other it sounds sort of like Halo at its core."
    com.digitaldestroyers.www       Description     Video game fans in Spartanburg, South Carolina who like to get together and compete for bragging rights. Also compete with other Halo / Xbox fan clubs.

### Atomic Counters

Column families can optionally act as atomic counters by supplying the COUNTER option in the column specification of the CREATE TABLE command. Counter columns are accessed using the same methods as other columns. However, to modify the counter, the value must be formatted specially, as described in the following table.

**Value** |  **Format Description**
---|---
`['+'] n` |  Increment the counter by n
`'-' n` |  Decrement the counter by n
`'=' n` |  Reset the counter to n

**Example**

In this example we create a table of counters called counts that contains a single column family url that acts as an atomic counter for urls. By convention, the row key is the URL with the domain name reversed (so that URLs from the same domain sort next to each other) and the column qualifier is the hour in which the "hit" occurred. The table is created with the following HQL:

    hypertable> use "/";
    hypertable> create table counts ( url COUNTER );

Let's say we've accumulated url "hit" occurrences in the following .tsv file:

    #row    column  value
    org.hypertable.www/     url:2010-10-26_09       +1
    org.hypertable.www/     url:2010-10-26_09       +1
    org.hypertable.www/download.html        url:2010-10-26_09       +1
    org.hypertable.www/documentation.html   url:2010-10-26_09       +1
    org.hypertable.www/download.html        url:2010-10-26_09       +1
    org.hypertable.www/about.html   url:2010-10-26_09       +1
    org.hypertable.www/     url:2010-10-26_09       +1
    org.hypertable.www/     url:2010-10-26_10       +1
    org.hypertable.www/about.html   url:2010-10-26_10       +1
    org.hypertable.www/     url:2010-10-26_10       +1
    org.hypertable.www/download.html        url:2010-10-26_10       +1
    org.hypertable.www/download.html        url:2010-10-26_10       +1
    org.hypertable.www/documentation.html   url:2010-10-26_10       +1
    org.hypertable.www/     url:2010-10-26_10       +1

If we were to load this file with LOAD DATA INFILE into the counts table, a subsequent select would yield the following output:

    hypertable> select * from counts;
    org.hypertable.www/     url:2010-10-26_09       3
    org.hypertable.www/     url:2010-10-26_10       3
    org.hypertable.www/about.html   url:2010-10-26_09       1
    org.hypertable.www/about.html   url:2010-10-26_10       1
    org.hypertable.www/documentation.html   url:2010-10-26_09       1
    org.hypertable.www/documentation.html   url:2010-10-26_10       1
    org.hypertable.www/download.html        url:2010-10-26_09       2
    org.hypertable.www/download.html        url:2010-10-26_10       2

### Group Commit

Updates are carried out by the RangeServers through the following steps:

  1. Write the update to the commit log
  2. Sync the commit log
  3. Populate in-memory data structure with the update

Under high concurrency, step #2 can become a bottleneck. Distributed filesystems such as HDFS can typically handle a small number of sync operations per second. The Group Commit feature solves this problem by delaying updates, grouping them together, and carrying them out in a batch on some regular interval.

A table can be configured to use group commit by supplying the GROUP_COMMIT_INTERVAL option in the CREATE TABLE statement. The GROUP_COMMIT_INTERVAL option tells the system that updates to this table should be carried out with group commit and also specifies the commit interval in milliseconds. The interval is constrained by the value of the config property Hypertable.RangeServer.CommitInterval, which acts as a lower bound (default is 50ms). The value specified for GROUP_COMMIT_INTERVAL will get rounded up to the nearest multiple of this property value. The following is an example CREATE TABLE statement that creates a table counts set up for group commit operation.

**Example**

    hypertable> CREATE TABLE counts (
      url,
      domain
    ) GROUP_COMMIT_INTERVAL=100;

### Unique Cells

Unique cells can be used whenever an application wants to make sure that there can never be more than one cell value in a column family. Unique cells are useful i.e. for assigning product IDs, user IDs etc. Traditional SQL databases offer auto-incrementing columns, but an auto-incrementing column would be relatively slow to implement in a distributed database. Hypertable's support for unique cells is therefore a bit different.

First, the column family needs to be set up to store only the oldest value:

CREATE TABLE profile ('guid' MAX_VERSIONS 1 TIME_ORDER DESC, ...)

To insert values, create a mutator and write the unique cell to the database. Then create a scanner, fetch the cell and verify that it was written correctly. If the scanner returns the same value then the update was fine. Otherwise the cell already existed with a different value.

Since this process is a bit cumbersome we introduced the HyperAppHelper library. It exports the following C++ function which requires a TablePtr and a KeySpec as a parameter. If the guid parameter is empty, Hypertable will fill it with an 128 bit GUID:

`void create_cell_unique(const TablePtr &table, const KeySpec &key, String &guid);`

This function can also be used through the Thrift interface. Here's a PHP snippet from the microblogging example. If the last parameter $guid is an empty string, then a new guid will be created and returned.

`self::$_client->create_cell_unique(self::$_namespace, $table, $key, $guid);`

The newly created GUID will look similar to this one:

`d7f8350a-777b-42b8-9967-e0cdc0dd1545`
