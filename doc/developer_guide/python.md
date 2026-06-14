# Python

## Table of Contents

### Introduction

This document presents example Python code that excercises the Thrift API. To quickly get Hypertable up and running on a single machine so that you can try out these examples, see [Hypertable Standalone Installation](../installation/quick_start_standalone.md). The source code for all of the examples in this document, along with the build and run scripts, can be found in [hypertable_api_example.tgz](http://hypertable.com/pub/hypertable_api_example.tgz).

### Environment setup and running

The following bash script illustrates how to setup an enviroment and run a Hypertable python thrift client program.

    HYPERTABLE_HOME=/opt/hypertable/current

    PYTHONPATH=$HYPERTABLE_HOME/lib/py
    PYTHONPATH=$PYTHONPATH:$HYPERTABLE_HOME/lib/py/hypertable
    PYTHONPATH=$PYTHONPATH:$HYPERTABLE_HOME/lib/py/gen-py

    export PYTHONPATH

    $HYPERTABLE_HOME/bin/ht python2.6 ./hypertable_api_test.py

### Program boilerplate

The following import statements are required for the code examples in this document.

    import sys
    import ctypes
    import datetime
    import time
    import libHyperPython
    from hypertable.thriftclient import *
    from hyperthrift.gen.ttypes import *

### Creating a thrift client

All of the examples in this document reference a pointer to a Thrift client object. The following code snippet illustrates how to create a Thrift client object connected to a ThriftBroker listening on the default port (15867) on localhost. To change the ThriftBroker location, just change "localhost" to the domain name of the machine on which the ThriftBroker is running.

    try:
      client = ThriftClient("localhost", 15867)
    except:
      print sys.exc_info()
      sys.exit(1);

### Basics

The following code snippet illustrates the basics of working with namespaces and tables. The APIs introduced include [namespace_exists](../reference_manual/thrift_api.md#namespaceexists), [namespace_create](../reference_manual/thrift_api.md#namespacecreate), [namespace_open](../reference_manual/thrift_api.md#namespaceopen), [namespace_get_listing](../reference_manual/thrift_api.md#namespacegetlisting), [namespace_close](../reference_manual/thrift_api.md#namespaceclose), [table_drop](../reference_manual/thrift_api.md#tabledrop), and [table_create](../reference_manual/thrift_api.md#tablecreate).

    try:
      if not client.namespace_exists("test"):
        client.namespace_create("test");

      ns = client.namespace_open("test");

      if_exists = True;
      client.table_drop(ns, "Fruits", if_exists);

      column_families = {};
      column_families["genus"] = ColumnFamilySpec("genus");
      column_families["description"] = ColumnFamilySpec("description");
      column_families["tag"] = ColumnFamilySpec("tag");
      schema = Schema(column_families = column_families);
      client.table_create(ns, "Fruits", schema);

      client.namespace_create("/test/sub");

      listing = client.namespace_get_listing(ns);
      for entry in listing:
        if entry.is_namespace:
          print "{0}\t(dir)".format(entry.name);
        else:
          print "{0}".format(entry.name);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Fruits
    sub	(dir)

### Convenience APIs

####  set_cells

The following code snippet illustrates how to create [Cell](../reference_manual/thrift_api.md#cell) objects and insert them with the [set_cells](../reference_manual/thrift_api.md#setcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](python.md#basics) example.

    try:
      ns = client.namespace_open("test");

      cells = [];

      key = Key(row = "apple", column_family = "genus");
      cell = Cell(key, "Malus");
      cells.append(cell);

      key = Key(row = "apple", column_family = "description");
      cell = Cell(key, "The apple is the pomaceous fruit of the apple tree.");
      cells.append(cell);

      key = Key(row = "apple", column_family = "tag", column_qualifier = "crunchy");
      cell = Cell(key, None);
      cells.append(cell);

      client.set_cells(ns, "Fruits", cells);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

####  get_cells

The following code snippet illustrates how to fetch cells with the [get_cells](../reference_manual/thrift_api.md#getcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](python.md#basics) example.

    try:
      ns = client.namespace_open("test");

      ss = ScanSpec();
      ss.columns = ["description"];

      cells = client.get_cells(ns, "Fruits", ss);

      for cell in cells:
        print cell;

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='The apple is the pomaceous fruit of the apple tree.', key=Key(column_family='description', column_qualifier='', timestamp=1403329438563180002, flag=255, row='apple', revision=1403329438563180002))

####  set_cells_as_arrays

The following code snippet illustrates how to create [CellAsArray](../reference_manual/thrift_api.md#cellasarray) objects and insert them with the [set_cells_as_arrays](../reference_manual/thrift_api.md#setcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](python.md#basics) example.

    try:
      ns = client.namespace_open("test");

      cells_as_arrays = [];

      cell_as_array = ["orange", "genus", "", "Citrus"];
      cells_as_arrays.append(cell_as_array);

      cell_as_array = ["orange", "description", "", "The orange (specifically, "
                       "the sweet orange) is the fruit of the citrus species "
                       "Citrus x sinensis in the family Rutaceae."];
      cells_as_arrays.append(cell_as_array);

      cell_as_array = ["orange", "tag", "juicy", ""];
      cells_as_arrays.append(cell_as_array);

      client.set_cells_as_arrays(ns, "Fruits", cells_as_arrays);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

####  get_cells_as_arrays

The following code snippet illustrates how to fetch cells with the [get_cells_as_arrays](../reference_manual/thrift_api.md#getcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](python.md#basics) example. The code also makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](python.md#appendix---helper-functions).

    try:
      ns = client.namespace_open("test");

      ss = ScanSpec();
      ss.columns = ["description"];

      cells_as_arrays = client.get_cells_as_arrays(ns, "Fruits", ss);

      for cell_as_array in cells_as_arrays:
        print_cell_as_array(cell_as_array);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    ['apple', 'description', '', 'The apple is the pomaceous fruit of the apple tree.']
    ['orange', 'description', '', 'The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus x sinensis in the family Rutaceae.']

####  set_cells_serialized

The following code snippet illustrates how to insert cells with the [set_cells_serialized](../reference_manual/thrift_api.md#setcellsserialized) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](python.md#basics) example.

    try:
      ns = client.namespace_open("test");

      writer = libHyperPython.SerializedCellsWriter(100, 1)

      writer.add("canteloupe", "genus", "", 0, "Cucumis", 8, KeyFlag.INSERT);
      writer.add("canteloupe", "description", "", 0, "Canteloupe refers to a "
                 "variety of Cucumis melo, a species in the family Cucurbitaceae.",
                 87, KeyFlag.INSERT);
      writer.add("canteloupe", "tag", "juicy", 0, "", 0, KeyFlag.INSERT);

      writer.finalize(0);

      client.set_cells_serialized(ns, "Fruits", writer.get())

    except ClientException as e:
      print e.message;
      sys.exit(1);

####  get_cells_serialized

The following code snippet illustrates how to fetch cells with the [get_cells_serialized](../reference_manual/thrift_api.md#getcellsserialized) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](python.md#basics) example.

    try:
      ns = client.namespace_open("test");

      ss = ScanSpec();
      ss.columns = ["description"];

      cells_serialized = client.get_cells_serialized(ns, "Fruits", ss);

      reader = libHyperPython.SerializedCellsReader(cells_serialized, len(cells_serialized))
      while reader.has_next():
        cell = reader.get_cell();
        print cell;

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    {Cell: key='apple' cf='description' cq='' val='The apple is the pomaceous fruit of the apple tree.' len=51 ts=1403329438563180002 flag=FLAG_INSERT}
    {Cell: key='canteloupe' cf='description' cq='' val='Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.' len=87 ts=0 flag=FLAG_INSERT}
    {Cell: key='orange' cf='description' cq='' val='The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus x sinensis in the family Rutaceae.' len=120 ts=1403329438604792002 flag=FLAG_INSERT}

### Creating a table

The following code snippet illustrates how to create a table with the [table_create](../reference_manual/thrift_api.md#tablecreate) API. It introduces the API classes [Schema](../reference_manual/thrift_api.md#schema), [AccessGroupSpec](../reference_manual/thrift_api.md#accessgroupspec), [AccessGroupOptions](../reference_manual/thrift_api.md#accessgroupoptions), [ColumnFamilySpec](../reference_manual/thrift_api.md#columnfamilyspec), and [ColumnFamilyOptions](../reference_manual/thrift_api.md#columnfamilyoptions).

    try:
      ns = client.namespace_open("test");

      default_ag_options = AccessGroupOptions(blocksize = 65536);
      default_cf_options = ColumnFamilyOptions(max_versions = 1);

      ag_specs = {};
      cf_specs = {};

      cf_options = ColumnFamilyOptions(max_versions = 2);
      ag_spec = AccessGroupSpec(name = "ag_normal", defaults = cf_options);
      ag_specs["ag_normal"] = ag_spec;

      cf_spec = ColumnFamilySpec(name = "a", access_group = "ag_normal",
                                 value_index = True, qualifier_index = True);
      cf_specs["a"] = cf_spec;

      cf_options = ColumnFamilyOptions(max_versions = 3);
      cf_spec = ColumnFamilySpec(name = "b", access_group = "ag_normal",
                                 options = cf_options);
      cf_specs["b"] = cf_spec;

      ag_options = AccessGroupOptions(in_memory = True, blocksize = 131072);
      ag_spec = AccessGroupSpec(name = "ag_fast", options = ag_options);
      ag_specs["ag_fast"] = ag_spec;

      cf_spec = ColumnFamilySpec(name = "c", access_group = "ag_fast");
      cf_specs["c"] = cf_spec;

      ag_options = AccessGroupOptions(replication = 5);
      ag_spec = AccessGroupSpec(name = "ag_secure", options = ag_options);
      ag_specs["ag_secure"] = ag_spec;

      cf_spec = ColumnFamilySpec(name = "d", access_group = "ag_secure");
      cf_specs["d"] = cf_spec;

      cf_options = ColumnFamilyOptions(counter = True, max_versions = 0);
      ag_spec = AccessGroupSpec(name = "ag_counter", defaults = cf_options);
      ag_specs["ag_counter"] = ag_spec;

      cf_spec = ColumnFamilySpec(name = "e", access_group = "ag_counter");
      cf_specs["e"] = cf_spec;

      cf_options = ColumnFamilyOptions(counter = False);
      cf_spec = ColumnFamilySpec(name = "f", access_group = "ag_counter",
                                 options = cf_options);
      cf_specs["f"] = cf_spec;

      schema = Schema(ag_specs, cf_specs, None, None, None,
                      default_ag_options, default_cf_options);

      client.table_create(ns, "TestTable", schema);

      result = client.hql_query(ns, "SHOW CREATE TABLE TestTable");

      print result.results[0];

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    CREATE TABLE TestTable (
      d MAX_VERSIONS 1,
      a MAX_VERSIONS 2, INDEX a, QUALIFIER INDEX a,
      b MAX_VERSIONS 3,
      c MAX_VERSIONS 1,
      e MAX_VERSIONS 0 COUNTER true,
      f MAX_VERSIONS 0 COUNTER false,
      ACCESS GROUP default () BLOCKSIZE 65536,
      ACCESS GROUP 'ag_secure' (d) REPLICATION 5 BLOCKSIZE 65536,
      ACCESS GROUP 'ag_normal' (a, b) BLOCKSIZE 65536 MAX_VERSIONS 2,
      ACCESS GROUP 'ag_fast' (c) BLOCKSIZE 131072 IN_MEMORY true,
      ACCESS GROUP 'ag_counter' (e, f) BLOCKSIZE 65536 MAX_VERSIONS 0 COUNTER true
    ) BLOCKSIZE 65536 MAX_VERSIONS 1;

### Altering a table

The following code snippet illustrates how to alter a table with the [table_alter](../reference_manual/thrift_api.md#tablealter) API. It assumes that the table _TestTable_ has been created as in the [Creating a table](python.md#creating-a-table) example.

    try:
      ns = client.namespace_open("test");

      schema = client.get_schema(ns, "TestTable");

      # Rename column "b" to "z"
      cf_spec = schema.column_families["b"];
      del schema.column_families["b"];
      cf_spec.name = "z";
      schema.column_families["z"] = cf_spec;

      # Add column "g"
      cf_spec = ColumnFamilySpec(name = "g", access_group = "ag_counter");
      schema.column_families["g"] = cf_spec;

      client.table_alter(ns, "TestTable", schema);

      result = client.hql_query(ns, "SHOW CREATE TABLE TestTable");

      print result.results[0];

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    CREATE TABLE TestTable (
      d MAX_VERSIONS 1,
      a MAX_VERSIONS 2, INDEX a, QUALIFIER INDEX a,
      z MAX_VERSIONS 3,
      c MAX_VERSIONS 1,
      e MAX_VERSIONS 0 COUNTER true,
      f MAX_VERSIONS 0 COUNTER false,
      g MAX_VERSIONS 0 COUNTER true,
      ACCESS GROUP default () BLOCKSIZE 65536,
      ACCESS GROUP 'ag_secure' (d) REPLICATION 5 BLOCKSIZE 65536,
      ACCESS GROUP 'ag_normal' (a, z) BLOCKSIZE 65536 MAX_VERSIONS 2,
      ACCESS GROUP 'ag_fast' (c) BLOCKSIZE 131072 IN_MEMORY true,
      ACCESS GROUP 'ag_counter' (e, f, g) BLOCKSIZE 65536 MAX_VERSIONS 0 COUNTER true
    ) BLOCKSIZE 65536 MAX_VERSIONS 1;

### Mutator

The code snippet below illustrates how to insert cells into a table using a mutator. The APIs introduced include [mutator_open](../reference_manual/thrift_api.md#mutatoropen), [mutator_set_cells](../reference_manual/thrift_api.md#mutatorsetcells), [mutator_flush](../reference_manual/thrift_api.md#mutatorflush), and [mutator_close](../reference_manual/thrift_api.md#mutatorclose).

    try:
      ns = client.namespace_open("test");

      mutator = client.mutator_open(ns, "Fruits", 0, 0);

      ## Auto-assigned timestamps

      cells = [];

      key = Key(row = "lemon", column_family = "genus");
      cell = Cell(key, "Citrus");
      cells.append(cell);

      key = Key(row = "lemon", column_family = "tag", column_qualifier = "bitter");
      cell = Cell(key, None);
      cells.append(cell);

      key = Key(row = "lemon", column_family = "description");
      cell = Cell(key, "The lemon (Citrus x limon) is a small evergreen tree "
                  "native to Asia.");
      cells.append(cell);

      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);

      ## Explicitly-supplied timestamps

      cells = [];

      # 2014-06-06 16:27:15
      dt = datetime.datetime(2014, 6, 6, 16, 27, 15);
      ts = long(time.mktime(dt.timetuple())) * 1000000000L;

      key = Key(row = "mango", column_family = "genus", timestamp = ts);
      cell = Cell(key, "Mangifera");
      cells.append(cell);

      key = Key(row = "mango", column_family = "tag", column_qualifier = "sweet",
                timestamp = ts);
      cell = Cell(key, None);
      cells.append(cell);

      key = Key(row = "mango", column_family = "description", timestamp = ts);
      cell = Cell(key, "Mango is one of the delicious seasonal fruits grown in "
                  "the tropics.");
      cells.append(cell);

      # 2014-06-06 16:27:16
      dt = datetime.datetime(2014, 6, 6, 16, 27, 16);
      ts = long(time.mktime(dt.timetuple())) * 1000000000L;

      key = Key(row = "mango", column_family = "description", timestamp = ts);
      cell = Cell(key, "The mango is a juicy stone fruit belonging to the genus "
                  "Mangifera, consisting of numerous tropical fruiting trees, "
                  "that are cultivated mostly for edible fruits.");
      cells.append(cell);

      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);

      cells = [];

      ## Delete clells

      dt = datetime.datetime(2014, 6, 6, 16, 27, 15);
      ts = long(time.mktime(dt.timetuple())) * 1000000000L;

      key = Key(row = "apple", flag = KeyFlag.DELETE_ROW);
      cell = Cell(key, None);
      cells.append(cell);

      dt = datetime.datetime(2014, 6, 6, 16, 27, 15);
      ts = long(time.mktime(dt.timetuple())) * 1000000000L;
      key = Key(row = "mango", column_family = "description",
                timestamp = ts, flag = KeyFlag.DELETE_CELL);
      cell = Cell(key, None);
      cells.append(cell);

      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

### Scanner

The following examples illustrate how to query a table using a scanner. The APIs introduced include the [scanner_open](../reference_manual/thrift_api.md#scanneropen), [scanner_get_cells](../reference_manual/thrift_api.md#scannergetcells), and [scanner_close](../reference_manual/thrift_api.md#scannerclose) functions, and the [ScanSpec](../reference_manual/thrift_api.md#scanspec) and [RowInterval](../reference_manual/thrift_api.md#rowinterval) classes.

####  Full table scan

The following code illustrates how to do a full table scan using the scanner APIs.

    try:
      ns = client.namespace_open("test");

      scanner = client.scanner_open(ns, "Fruits", ScanSpec());

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.\x00', key=Key(column_family='description', column_qualifier='', timestamp=0, flag=255, row='canteloupe', revision=1403330740729682002))
    Cell(value='Cucumis\x00', key=Key(column_family='genus', column_qualifier='', timestamp=0, flag=255, row='canteloupe', revision=1403330740729682001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='juicy', timestamp=0, flag=255, row='canteloupe', revision=1403330740729682003))
    Cell(value='The lemon (Citrus x limon) is a small evergreen tree native to Asia.', key=Key(column_family='description', column_qualifier='', timestamp=1403330743454423003, flag=255, row='lemon', revision=1403330743454423003))
    Cell(value='Citrus', key=Key(column_family='genus', column_qualifier='', timestamp=1403330743454423001, flag=255, row='lemon', revision=1403330743454423001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='bitter', timestamp=1403330743454423002, flag=255, row='lemon', revision=1403330743454423002))
    Cell(value='The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.', key=Key(column_family='description', column_qualifier='', timestamp=1402097236000000000, flag=255, row='mango', revision=1403330743499910004))
    Cell(value='Mangifera', key=Key(column_family='genus', column_qualifier='', timestamp=1402097235000000000, flag=255, row='mango', revision=1403330743499910001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='sweet', timestamp=1402097235000000000, flag=255, row='mango', revision=1403330743499910002))
    Cell(value='The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus x sinensis in the family Rutaceae.', key=Key(column_family='description', column_qualifier='', timestamp=1403330740674705002, flag=255, row='orange', revision=1403330740674705002))
    Cell(value='Citrus', key=Key(column_family='genus', column_qualifier='', timestamp=1403330740674705001, flag=255, row='orange', revision=1403330740674705001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='juicy', timestamp=1403330740674705003, flag=255, row='orange', revision=1403330740674705003))

####  Restricted scan with ScanSpec

The following code illustrates how to do a table scan using a ScanSpec.

    try:
      ns = client.namespace_open("test");

      row_intervals = [ RowInterval("lemon", True, "orange", False) ];
      columns = ["genus", "tag:fleshy", "tag:bitter", "tag:sweet"];
      ss = ScanSpec(row_intervals = row_intervals, versions = 1, columns = columns);

      scanner = client.scanner_open(ns, "Fruits", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='Citrus', key=Key(column_family='genus', column_qualifier='', timestamp=1403330743454423001, flag=255, row='lemon', revision=1403330743454423001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='bitter', timestamp=1403330743454423002, flag=255, row='lemon', revision=1403330743454423002))
    Cell(value='Mangifera', key=Key(column_family='genus', column_qualifier='', timestamp=1402097235000000000, flag=255, row='mango', revision=1403330743499910001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='sweet', timestamp=1402097235000000000, flag=255, row='mango', revision=1403330743499910002))

### HQL

####  hql_query

The following code illustrates how to issue HQL commands with the [hql_query](../reference_manual/thrift_api.md#hqlquery) API. It also introduces the [HqlResult](../reference_manual/thrift_api.md#hqlresult) class.

    try:
      ns = client.namespace_open("test");

      result = client.hql_query(ns, "GET LISTING");
      for line in result.results:
        print line;

      result = client.hql_query(ns, "SELECT * from Fruits WHERE ROW = 'mango'");
      for cell in result.cells:
        print cell;

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Fruits
    TestTable
    ^TestTable
    ^^TestTable
    sub	(namespace)
    Cell(value='The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.', key=Key(column_family='description', column_qualifier='', timestamp=1402097236000000000, flag=255, row='mango', revision=1403331658160205004))
    Cell(value='Mangifera', key=Key(column_family='genus', column_qualifier='', timestamp=1402097235000000000, flag=255, row='mango', revision=1403331658160205001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='sweet', timestamp=1402097235000000000, flag=255, row='mango', revision=1403331658160205002))

####  hql_query_as_arrays

The following code illustrates how to issue an HQL query with the [hql_query_as_arrays](../reference_manual/thrift_api.md#hqlqueryasarrays) API. It also introduces the [HqlResultAsArrays](../reference_manual/thrift_api.md#hqlresultasarrays) class. The code also makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](python.md#appendix---helper-functions).

    try:
      ns = client.namespace_open("test");

      result_as_arrays = \
          client.hql_query_as_arrays(ns, "SELECT * from Fruits WHERE ROW = 'lemon'");
      for cell_as_array in result_as_arrays.cells:
        print_cell_as_array(cell_as_array);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    ['lemon', 'description', '', 'The lemon (Citrus x limon) is a small evergreen tree native to Asia.']
    ['lemon', 'genus', '', 'Citrus']
    ['lemon', 'tag', 'bitter', '']

####  hql_exec (mutator)

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a mutator.

    try:
      ns = client.namespace_open("test");

      result = \
          client.hql_exec(ns, "INSERT INTO Fruits VALUES ('strawberry', 'genus',"
                          "'Fragaria'), ('strawberry', 'tag:fibrous', ''), "
                          "('strawberry', 'description', 'The garden strawberry "
                          "is a widely grown hybrid species of the genus "
                          "Fragaria')", True, False);
      cells = [];

      key = Key(row = "pineapple", column_family = "genus");
      cell = Cell(key, "Anans");
      cells.append(cell);

      key = Key(row = "pineapple", column_family = "tag", column_qualifier = "acidic");
      cell = Cell(key, None);
      cells.append(cell);

      key = Key(row = "pineapple", column_family = "description");
      cell = Cell(key, "The pineapple (Ananas comosus) is a tropical plant with "
                  "edible multiple fruit consisting of coalesced berries.");
      cells.append(cell);

      client.mutator_set_cells(result.mutator, cells);
      client.mutator_flush(result.mutator);
      client.mutator_close(result.mutator);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

####  hql_exec (scanner}

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a scanner.

    try:
      ns = client.namespace_open("test");

      result = client.hql_exec(ns, "SELECT * from Fruits", False, True);

      while True:
        cells = client.scanner_get_cells(result.scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(result.scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.\x00', key=Key(column_family='description', column_qualifier='', timestamp=0, flag=255, row='canteloupe', revision=1403331655459870002))
    Cell(value='Cucumis\x00', key=Key(column_family='genus', column_qualifier='', timestamp=0, flag=255, row='canteloupe', revision=1403331655459870001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='juicy', timestamp=0, flag=255, row='canteloupe', revision=1403331655459870003))
    Cell(value='The lemon (Citrus x limon) is a small evergreen tree native to Asia.', key=Key(column_family='description', column_qualifier='', timestamp=1403331658114622003, flag=255, row='lemon', revision=1403331658114622003))
    Cell(value='Citrus', key=Key(column_family='genus', column_qualifier='', timestamp=1403331658114622001, flag=255, row='lemon', revision=1403331658114622001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='bitter', timestamp=1403331658114622002, flag=255, row='lemon', revision=1403331658114622002))
    Cell(value='The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.', key=Key(column_family='description', column_qualifier='', timestamp=1402097236000000000, flag=255, row='mango', revision=1403331658160205004))
    Cell(value='Mangifera', key=Key(column_family='genus', column_qualifier='', timestamp=1402097235000000000, flag=255, row='mango', revision=1403331658160205001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='sweet', timestamp=1402097235000000000, flag=255, row='mango', revision=1403331658160205002))
    Cell(value='The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus x sinensis in the family Rutaceae.', key=Key(column_family='description', column_qualifier='', timestamp=1403331655426717002, flag=255, row='orange', revision=1403331655426717002))
    Cell(value='Citrus', key=Key(column_family='genus', column_qualifier='', timestamp=1403331655426717001, flag=255, row='orange', revision=1403331655426717001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='juicy', timestamp=1403331655426717003, flag=255, row='orange', revision=1403331655426717003))
    Cell(value='The pineapple (Ananas comosus) is a tropical plant with edible multiple fruit consisting of coalesced berries.', key=Key(column_family='description', column_qualifier='', timestamp=1403331658231869003, flag=255, row='pineapple', revision=1403331658231869003))
    Cell(value='Anans', key=Key(column_family='genus', column_qualifier='', timestamp=1403331658231869001, flag=255, row='pineapple', revision=1403331658231869001))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='acidic', timestamp=1403331658231869002, flag=255, row='pineapple', revision=1403331658231869002))
    Cell(value='The garden strawberry is a widely grown hybrid species of the genus Fragaria', key=Key(column_family='description', column_qualifier='', timestamp=1403331658231869006, flag=255, row='strawberry', revision=1403331658231869006))
    Cell(value='Fragaria', key=Key(column_family='genus', column_qualifier='', timestamp=1403331658231869004, flag=255, row='strawberry', revision=1403331658231869004))
    Cell(value=None, key=Key(column_family='tag', column_qualifier='fibrous', timestamp=1403331658231869005, flag=255, row='strawberry', revision=1403331658231869005))

### Secondary indices

This section describes how to query tables using secondary indices. APIs introduced include the [ColumnPredicate](../reference_manual/thrift_api.md#column_predicate) class and the _column_predicates_ and the _and_column_predicates_ members of the [ScanSpec](../reference_manual/thrift_api.md#scanspec) class. The examples assume that the table products has been created and loaded with the following HQL commands.

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

    LOAD DATA INFILE 'indices_test_products.tsv' INTO TABLE products;

####  Value index (exact match)

The following HQL query which leverages the value index of the _section_ column:

    SELECT title FROM products WHERE section = 'books';

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      column_predicate = ColumnPredicate("section", None,
                                         ColumnPredicateOperation.EXACT_MATCH,
                                         "books");
      columns = [ "title" ];
      ss = ScanSpec(column_predicates = [column_predicate], columns = columns);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='The Shining Mass Market Paperback', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123001, flag=255, row='0307743659', revision=1403332931847123001))
    Cell(value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123008, flag=255, row='0321321928', revision=1403332931847123008))
    Cell(value="C++ Primer Plus (6th Edition) (Developer's Library)", key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123019, flag=255, row='0321776402', revision=1403332931847123019))

####  Value index (exact match with qualifier)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title FROM products WHERE info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      column_predicate = ColumnPredicate("info", "actor",
                                         ColumnPredicateOperation.EXACT_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "Jack Nicholson");
      columns = [ "title" ];
      ss = ScanSpec(column_predicates = [column_predicate], columns = columns);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='Five Easy Pieces (1970)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123030, flag=255, row='B00002VWE0', revision=1403332931847123030))
    Cell(value='The Shining (1980)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123049, flag=255, row='B002VWNIDG', revision=1403332931847123049))

####  Value index (prefix match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =^ 'Addison-Wesley';

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      column_predicate = ColumnPredicate("info", "publisher",
                                         ColumnPredicateOperation.PREFIX_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "Addison-Wesley");
      columns = ["title", "info:publisher"];
      ss = ScanSpec(column_predicates = [column_predicate], columns = columns);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123008, flag=255, row='0321321928', revision=1403332931847123008))
    Cell(value='Addison-Wesley Professional; 1 edition (March 10, 2005)', key=Key(column_family='info', column_qualifier='publisher', timestamp=1403332931768799000, flag=255, row='0321321928', revision=1403332931847123013))
    Cell(value="C++ Primer Plus (6th Edition) (Developer's Library)", key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123019, flag=255, row='0321776402', revision=1403332931847123019))
    Cell(value='Addison-Wesley Professional; 6 edition (October 28, 2011)', key=Key(column_family='info', column_qualifier='publisher', timestamp=1403332931768403000, flag=255, row='0321776402', revision=1403332931847123024))

####  Value index (regex match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =~ /^Addison-Wesley/;

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      column_predicate = ColumnPredicate("info", "publisher",
                                         ColumnPredicateOperation.REGEX_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "^Addison-Wesley");
      columns = ["title", "info:publisher"];
      ss = ScanSpec(column_predicates = [column_predicate], columns = columns);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123008, flag=255, row='0321321928', revision=1403332931847123008))
    Cell(value='Addison-Wesley Professional; 1 edition (March 10, 2005)', key=Key(column_family='info', column_qualifier='publisher', timestamp=1403332931768799000, flag=255, row='0321321928', revision=1403332931847123013))
    Cell(value="C++ Primer Plus (6th Edition) (Developer's Library)", key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123019, flag=255, row='0321776402', revision=1403332931847123019))
    Cell(value='Addison-Wesley Professional; 6 edition (October 28, 2011)', key=Key(column_family='info', column_qualifier='publisher', timestamp=1403332931768403000, flag=255, row='0321776402', revision=1403332931847123024))

####  Qualifier index (exists)

The following HQL query which leverages the qualifier index of the _info_ column:

    SELECT title FROM products WHERE Exists(info:studio);

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      column_predicate = ColumnPredicate("info", "studio",
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         None);
      columns = ["title"];
      ss = ScanSpec(column_predicates = [column_predicate], columns = columns);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='Five Easy Pieces (1970)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123030, flag=255, row='B00002VWE0', revision=1403332931847123030))
    Cell(value='2001: A Space Odyssey [Blu-ray]', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123039, flag=255, row='B000Q66J1M', revision=1403332931847123039))
    Cell(value='The Shining (1980)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123049, flag=255, row='B002VWNIDG', revision=1403332931847123049))

####  Qualifier index (exists regex prefix match)

The following HQL query which leverages the qualifier index of the _category_ column:

    SELECT title FROM products WHERE Exists(category:/^\/Movies/);

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      column_predicate = ColumnPredicate("category", "^/Movies",
                                         ColumnPredicateOperation.QUALIFIER_REGEX_MATCH,
                                         None);
      columns = ["title"];
      ss = ScanSpec(column_predicates = [column_predicate], columns = columns);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='Five Easy Pieces (1970)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123030, flag=255, row='B00002VWE0', revision=1403332931847123030))
    Cell(value='2001: A Space Odyssey [Blu-ray]', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123039, flag=255, row='B000Q66J1M', revision=1403332931847123039))
    Cell(value='The Shining (1980)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123049, flag=255, row='B002VWNIDG', revision=1403332931847123049))

####  Value index (OR query)

The following HQL query performs a boolean _OR_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen P/ OR info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      predicates = [];
      column_predicate = ColumnPredicate("info", "author",
                                         ColumnPredicateOperation.REGEX_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "^Stephen P");
      predicates.append(column_predicate);
      column_predicate = ColumnPredicate("info", "publisher",
                                         ColumnPredicateOperation.PREFIX_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "Anchor");
      predicates.append(column_predicate);

      columns = ["title"];
      ss = ScanSpec(column_predicates = predicates, columns = columns);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='The Shining Mass Market Paperback', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123001, flag=255, row='0307743659', revision=1403332931847123001))
    Cell(value="C++ Primer Plus (6th Edition) (Developer's Library)", key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123019, flag=255, row='0321776402', revision=1403332931847123019))

####  Value index (AND query)

The following HQL query performs a boolean _AND_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      predicates = [];
      column_predicate = ColumnPredicate("info", "author",
                                         ColumnPredicateOperation.REGEX_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "^Stephen [PK]");
      predicates.append(column_predicate);
      column_predicate = ColumnPredicate("info", "publisher",
                                         ColumnPredicateOperation.PREFIX_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "Anchor");
      predicates.append(column_predicate);

      columns = ["title"];
      ss = ScanSpec(column_predicates = predicates, columns = columns,
                    and_column_predicates = True);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='The Shining Mass Market Paperback', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123001, flag=255, row='0307743659', revision=1403332931847123001))

####  Value index (AND row interval)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW interval:

    SELECT title
      FROM products
      WHERE ROW > 'B00002VWE0' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      row_interval = RowInterval("B00002VWE0", False, None, True);
      column_predicate = ColumnPredicate("info", "actor",
                                         ColumnPredicateOperation.EXACT_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "Jack Nicholson");

      ss = ScanSpec(row_intervals = [row_interval],
                    column_predicates = [column_predicate],
                    columns = ["title"], and_column_predicates = True);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='The Shining (1980)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123049, flag=255, row='B002VWNIDG', revision=1403332931847123049))

####  Value index (AND row prefix)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW prefix interval:

    SELECT title
      FROM products
      WHERE ROW =^ 'B' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try:
      ns = client.namespace_open("test");

      row_interval = RowInterval("B", True, "C", False);
      column_predicate = ColumnPredicate("info", "actor",
                                         ColumnPredicateOperation.EXACT_MATCH |
                                         ColumnPredicateOperation.QUALIFIER_EXACT_MATCH,
                                         "Jack Nicholson");

      ss = ScanSpec(row_intervals = [row_interval],
                    column_predicates = [column_predicate],
                    columns = ["title"], and_column_predicates = True);

      scanner = client.scanner_open(ns, "products", ss);

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='Five Easy Pieces (1970)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123030, flag=255, row='B00002VWE0', revision=1403332931847123030))
    Cell(value='The Shining (1980)', key=Key(column_family='title', column_qualifier='', timestamp=1403332931847123049, flag=255, row='B002VWNIDG', revision=1403332931847123049))

### Asynchronous APIs

This section describes how to use the asynchronous APIs. The examples assume that tables _Profile_ and _Session_ are created and loaded with the following HQL commands.

    CREATE TABLE Profile (info, last_access MAX_VERSIONS 1);

    CREATE TABLE Session (user_id, page_hit);

    INSERT INTO Profile
      VALUES ('1', 'info:name', 'Joe'), ('2', 'info:name', 'Sue');

####  Async mutator

The code snippet below illustrates how to insert cells into multiple tables simultaneously using an asynchronous mutator. The APIs introduced include the [future_open](../reference_manual/thrift_api.md#futureopen), [future_get_result](../reference_manual/thrift_api.md#futuregetresult), [future_close](../reference_manual/thrift_api.md#futureclose), [async_mutator_open](../reference_manual/thrift_api.md#asyncmutatoropen), [async_mutator_set_cells](../reference_manual/thrift_api.md#asyncmutatorsetcells), [async_mutator_flush](../reference_manual/thrift_api.md#asyncmutatorflush), and [async_mutator_close](../reference_manual/thrift_api.md#asyncmutatorclose) functions and the [Result](../reference_manual/thrift_api.md#result) class.

    try:
      ns = client.namespace_open("test");
      ff = client.future_open(0);
      profile_mutator = client.async_mutator_open(ns, "Profile", ff, 0);
      session_mutator = client.async_mutator_open(ns, "Session", ff, 0);

      cells = [];

      key = Key(row = "1", column_family = "last_access");
      cell = Cell(key, "2014-06-13 16:06:09");
      cells.append(cell);

      key = Key(row = "2", column_family = "last_access");
      cell = Cell(key, "2014-06-13 16:06:10");
      cells.append(cell);

      client.async_mutator_set_cells(profile_mutator, cells);

      cells = [];

      key = Key(row = "0001-200238", column_family = "user_id",
                column_qualifier = "1");
      cell = Cell(key, None);
      cells.append(cell);

      key = Key(row = "0001-200238", column_family = "page_hit");
      cell = Cell(key, "/index.html");
      cells.append(cell);

      key = Key(row = "0002-383049", column_family = "user_id",
                column_qualifier = "2");
      cell = Cell(key, None);
      cells.append(cell);

      key = Key(row = "0002-383049", column_family = "page_hit");
      cell = Cell(key, "/foo/bar.html");
      cells.append(cell);

      client.async_mutator_set_cells(session_mutator, cells);

      client.async_mutator_flush(profile_mutator);
      client.async_mutator_flush(session_mutator);

      result_count = 0;
      while True:
        result = client.future_get_result(ff, 0);
        if result.is_empty:
          break;
        result_count += 1;
        if result.is_error:
          print "Async mutator error:  {0}".format(result.error_msg);
          sys.exit(1);
        if result.id == profile_mutator:
          print "Result is from Profile mutation";
        elif result.id == session_mutator:
          print "Result is from Session mutation";

      print "result count = {0}".format(result_count);

      client.async_mutator_close(profile_mutator);
      client.async_mutator_close(session_mutator);
      client.future_close(ff);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Result is from Profile mutation
    Result is from Session mutation
    result count = 2

####  Async scanner (Result)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [Result](../reference_manual/thrift_api.md#result) object. The APIs introduced include the [async_scanner_open](../reference_manual/thrift_api.md#asyncscanneropen) and [async_scanner_close](../reference_manual/thrift_api.md#asyncscannerclose) functions.

    try:
      ns = client.namespace_open("test");
      ff = client.future_open(0);

      row_intervals = [ RowInterval("1", True, "1", True) ];
      ss = ScanSpec(row_intervals = row_intervals);
      profile_scanner = client.async_scanner_open(ns, "Profile", ff, ss);

      row_intervals = [ RowInterval("0001-200238", True, "0001-200238", True) ];
      ss = ScanSpec(row_intervals = row_intervals);
      session_scanner = client.async_scanner_open(ns, "Session", ff, ss);

      while True:
        result = client.future_get_result(ff, 0);

        if result.is_empty:
          break;

        if result.is_error:
          print "Async scanner error:  {0}".format(result.error_msg);
          sys.exit(1);

        assert result.is_scan;
        assert result.id == profile_scanner or result.id == session_scanner;

        if result.id == profile_scanner:
          print "Result is from Profile scan";
        elif result.id == session_scanner:
          print "Result is from Session scan";

        for cell in result.cells:
          print cell;

      client.async_scanner_close(profile_scanner);
      client.async_scanner_close(session_scanner);
      client.future_close(ff);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Result is from Profile scan
    Cell(value='Joe', key=Key(column_family='info', column_qualifier='name', timestamp=1403333645117794001, flag=255, row='1', revision=1403333645117794001))
    Cell(value='2014-06-13 16:06:09', key=Key(column_family='last_access', column_qualifier='', timestamp=1403333645176577001, flag=255, row='1', revision=1403333645176577001))
    Result is from Session scan
    Cell(value=None, key=Key(column_family='user_id', column_qualifier='1', timestamp=1403333645177109001, flag=255, row='0001-200238', revision=1403333645177109001))
    Cell(value='/index.html', key=Key(column_family='page_hit', column_qualifier='', timestamp=1403333645177109002, flag=255, row='0001-200238', revision=1403333645177109002))

####  Async scanner (ResultSerialized)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultSerialized](../reference_manual/thrift_api.md#resultserialized) object. This example introduces the [future_get_result_serialized](../reference_manual/thrift_api.md#futuregetresultserialized) API.

    try:
      ns = client.namespace_open("test");
      ff = client.future_open(0);

      row_intervals = [ RowInterval("1", True, "1", True) ];
      ss = ScanSpec(row_intervals = row_intervals);
      profile_scanner = client.async_scanner_open(ns, "Profile", ff, ss);

      row_intervals = [ RowInterval("0001-200238", True, "0001-200238", True) ];
      ss = ScanSpec(row_intervals = row_intervals);
      session_scanner = client.async_scanner_open(ns, "Session", ff, ss);

      while True:
        result_serialized = client.future_get_result_serialized(ff, 0);

        if result_serialized.is_empty:
          break;

        if result_serialized.is_error:
          print "Async scanner error:  {0}".format(result_serialized.error_msg);
          sys.exit(1);

        assert result_serialized.is_scan;
        assert result_serialized.id == profile_scanner or result_serialized.id == session_scanner;

        if result_serialized.id == profile_scanner:
          print "Result is from Profile scan";
        elif result_serialized.id == session_scanner:
          print "Result is from Session scan";

        reader = libHyperPython.SerializedCellsReader(result_serialized.cells, len(result_serialized.cells))
        while reader.has_next():
          cell = reader.get_cell();
          print cell;

      client.async_scanner_close(profile_scanner);
      client.async_scanner_close(session_scanner);
      client.future_close(ff);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Result is from Profile scan
    {Cell: key='1' cf='info' cq='name' val='Joe' len=3 ts=1403333645117794001 flag=FLAG_INSERT}
    {Cell: key='1' cf='last_access' cq='' val='2014-06-13 16:06:09' len=19 ts=1403333645176577001 flag=FLAG_INSERT}
    Result is from Session scan
    {Cell: key='0001-200238' cf='user_id' cq='1' val=[NULL] len=0 ts=1403333645177109001 flag=FLAG_INSERT}
    {Cell: key='0001-200238' cf='page_hit' cq='' val='/index.html' len=11 ts=1403333645177109002 flag=FLAG_INSERT}

####  Async scanner (ResultAsArrays)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultAsArrays](../reference_manual/thrift_api.md#resultasarrays) object. This example introduces the [future_get_result_as_arrays](../reference_manual/thrift_api.md#futuregetresultasarrays) API and makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](python.md#appendix---helper-functions).

    try:
      ns = client.namespace_open("test");
      ff = client.future_open(0);

      row_intervals = [ RowInterval("1", True, "1", True) ];
      ss = ScanSpec(row_intervals = row_intervals);
      profile_scanner = client.async_scanner_open(ns, "Profile", ff, ss);

      row_intervals = [ RowInterval("0001-200238", True, "0001-200238", True) ];
      ss = ScanSpec(row_intervals = row_intervals);
      session_scanner = client.async_scanner_open(ns, "Session", ff, ss);

      while True:
        result_as_arrays = client.future_get_result_as_arrays(ff, 0);

        if result_as_arrays.is_empty:
          break;

        if result_as_arrays.is_error:
          print "Async scanner error:  {0}".format(result_as_arrays.error_msg);
          sys.exit(1);

        assert result_as_arrays.is_scan;
        assert result_as_arrays.id == profile_scanner or result_as_arrays.id == session_scanner;

        if result_as_arrays.id == profile_scanner:
          print "Result is from Profile scan";
        elif result_as_arrays.id == session_scanner:
          print "Result is from Session scan";

        for cell_as_array in result_as_arrays.cells:
          print_cell_as_array(cell_as_array);

      client.async_scanner_close(profile_scanner);
      client.async_scanner_close(session_scanner);
      client.future_close(ff);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Result is from Profile scan
    ['1', 'info', 'name', 'Joe']
    ['1', 'last_access', '', '2014-06-13 16:06:09']
    Result is from Session scan
    ['0001-200238', 'user_id', '1', '']
    ['0001-200238', 'page_hit', '', '/index.html']

### Atomic counters

This section describes how to use atomic counters. The examples assume that a  _Hits_ table has been created with the following HQL command.

    CREATE TABLE Hits (count COUNTER);

####  Increment

The code snippet below illustrates how to increment per-second hit counts for pages of a website.

    try:
      ns = client.namespace_open("test");

      cells = [];
      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:18");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:18");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/foo/bar.html", column_family = "count", column_qualifier = "2014-06-14 07:31:18");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/foo/bar.html", column_family = "count", column_qualifier = "2014-06-14 07:31:18");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/foo/bar.html", column_family = "count", column_qualifier = "2014-06-14 07:31:18");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:19");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:19");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:19");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:19");
      cell = Cell(key, "1");
      cells.append(cell);

      key = Key(row = "/foo/bar.html", column_family = "count", column_qualifier = "2014-06-14 07:31:19");
      cell = Cell(key, "1");
      cells.append(cell);

      mutator = client.mutator_open(ns, "Hits", 0, 0);
      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);

      scanner = client.scanner_open(ns, "Hits", ScanSpec());

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);
      client.mutator_close(mutator);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='3', key=Key(column_family='count', column_qualifier='2014-06-14 07:31:18', timestamp=1403366745214994003, flag=255, row='/foo/bar.html', revision=1403366745214994003))
    Cell(value='1', key=Key(column_family='count', column_qualifier='2014-06-14 07:31:19', timestamp=1403366745214994004, flag=255, row='/foo/bar.html', revision=1403366745214994004))
    Cell(value='2', key=Key(column_family='count', column_qualifier='2014-06-14 07:31:18', timestamp=1403366745214994006, flag=255, row='/index.html', revision=1403366745214994006))
    Cell(value='4', key=Key(column_family='count', column_qualifier='2014-06-14 07:31:19', timestamp=1403366745214994010, flag=255, row='/index.html', revision=1403366745214994010))

####  Reset and subtraction

The code snippet below illustrates how to reset and subtract from counters.

    try:
      ns = client.namespace_open("test");

      cells = [];
      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:18");
      cell = Cell(key, "=0");
      cells.append(cell);

      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:18");
      cell = Cell(key, "7");
      cells.append(cell);

      key = Key(row = "/foo/bar.html", column_family = "count", column_qualifier = "2014-06-14 07:31:18");
      cell = Cell(key, "-1");
      cells.append(cell);

      key = Key(row = "/index.html", column_family = "count", column_qualifier = "2014-06-14 07:31:19");
      cell = Cell(key, "-2");
      cells.append(cell);

      key = Key(row = "/foo/bar.html", column_family = "count", column_qualifier = "2014-06-14 07:31:19");
      cell = Cell(key, "=19");
      cells.append(cell);

      mutator = client.mutator_open(ns, "Hits", 0, 0);
      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);

      scanner = client.scanner_open(ns, "Hits", ScanSpec());

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell;

      client.scanner_close(scanner);
      client.mutator_close(mutator);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message
      sys.exit(1);

The following is example output produced by the above code snippet.

    Cell(value='2', key=Key(column_family='count', column_qualifier='2014-06-14 07:31:18', timestamp=1403366745282952001, flag=255, row='/foo/bar.html', revision=1403366745282952001))
    Cell(value='19', key=Key(column_family='count', column_qualifier='2014-06-14 07:31:19', timestamp=1403366745282952002, flag=255, row='/foo/bar.html', revision=1403366745282952002))
    Cell(value='7', key=Key(column_family='count', column_qualifier='2014-06-14 07:31:18', timestamp=1403366745282952004, flag=255, row='/index.html', revision=1403366745282952004))
    Cell(value='2', key=Key(column_family='count', column_qualifier='2014-06-14 07:31:19', timestamp=1403366745282952005, flag=255, row='/index.html', revision=1403366745282952005))

### Creating unique keys

This section illustrates how to create unique keys using the [create_cell_unique](../reference_manual/thrift_api.md#createcellunique) API. The example show how you can create unique user IDs for an application. The code assumes that a _User_ table has been created with the following HQL command.

    CREATE TABLE User (info, id TIME_ORDER desc MAX_VERSIONS 1);

The example code snippet is as follows.

    try:
      ns = client.namespace_open("test");

      key = Key(row = "joe1987", column_family = "id");
      ret = client.create_cell_unique(ns, "User", key, "");

      key = Key(row = "mary.bellweather", column_family = "id");
      ret = client.create_cell_unique(ns, "User", key, "");

      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

    try:
      ns = client.namespace_open("test");

      key = Key(row = "joe1987", column_family = "id");
      ret = client.create_cell_unique(ns, "User", key, "");

      client.namespace_close(ns);

    except ClientException as e:
      if e.code == 48:  # ALREADY_EXISTS
        print "User name '{0}' is already taken".format(key.row);
        client.namespace_close(ns);
      else:
        print e.message;
        sys.exit(1);

    try:
      ns = client.namespace_open("test");
      scanner = client.scanner_open(ns, "User", ScanSpec());

      while True:
        cells = client.scanner_get_cells(scanner);
        if not cells:
          break;
        for cell in cells:
          print cell.key;

      client.scanner_close(scanner);
      client.namespace_close(ns);

    except ClientException as e:
      print e.message;
      sys.exit(1);

The following is example output produced by the above code snippet.

    User name 'joe1987' is already taken
    Key(column_family='id', column_qualifier='', timestamp=1403366745973630001, flag=255, row='joe1987', revision=1403366745973630001)
    Key(column_family='id', column_qualifier='', timestamp=1403366746014419001, flag=255, row='mary.bellweather', revision=1403366746014419001)

### Appendix - helper functions

The following helper function is used in the examples in this document.

    def print_cell_as_array(cell):
      "Prints a cell as array without the timestamp"
      print cell[0:4];
