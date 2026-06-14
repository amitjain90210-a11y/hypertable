# Java

## Table of Contents

### Introduction

This document presents example Java code that excercises the Thrift API. To quickly get Hypertable up and running on a single machine so that you can try out these examples, see [Hypertable Standalone Installation](../installation/quick_start_standalone.md). The source code for all of the examples in this document, along with the build and run scripts, can be found in [hypertable_api_example.tgz](http://hypertable.com/pub/hypertable_api_example.tgz).

### Compiling and running

The following bash script illustrates how to compile and run a Hypertable java thrift client program.

    HYPERTABLE_HOME=/opt/hypertable/current

    VERSION=`$HYPERTABLE_HOME/bin/ht version | head -1 | cut -f1 -d' '`

    JARS=`ls -1 $HYPERTABLE_HOME/lib/java/libthrift-*.jar`
    JARS=$JARS:$HYPERTABLE_HOME/lib/java/cdh4/hypertable-$VERSION.jar
    JARS=$JARS:.

    # Compile
    javac -classpath "$JARS" HypertableApiTest.java

    # Run
    CLASSPATH=$HYPERTABLE_HOME/lib/java/*:$HYPERTABLE_HOME/lib/java/cdh4/*:.
    java -ea -classpath $CLASSPATH HypertableApiTest

### Program boilerplate

The following import statements are required for the code examples in this document.

    import java.io.UnsupportedEncodingException;
    import java.nio.ByteBuffer;
    import java.text.DateFormat;
    import java.text.ParseException;
    import java.text.SimpleDateFormat;
    import java.util.Date;
    import java.util.List;
    import java.util.ArrayList;
    import java.util.Map;
    import java.util.HashMap;
    import org.apache.thrift.TException;
    import org.apache.thrift.transport.TTransportException;
    import org.hypertable.thrift.*;
    import org.hypertable.thriftgen.*;

### Creating a thrift client

All of the examples in this document reference a pointer to a Thrift client object. The following code snippet illustrates how to create a Thrift client object connected to a ThriftBroker listening on the default port (15867) on localhost. To change the ThriftBroker location, just change "localhost" to the domain name of the machine on which the ThriftBroker is running.

    ThriftClient client = null;

    try {
      client = ThriftClient.create("localhost", 15867);
    }
    catch (TException e) {
      System.out.println(e);
      System.exit(1);
    }

### Basics

The following code snippet illustrates the basics of working with namespaces and tables. The APIs introduced include [namespace_exists](../reference_manual/thrift_api.md#namespaceexists), [namespace_create](../reference_manual/thrift_api.md#namespacecreate), [namespace_open](../reference_manual/thrift_api.md#namespaceopen), [namespace_get_listing](../reference_manual/thrift_api.md#namespacegetlisting), [namespace_close](../reference_manual/thrift_api.md#namespaceclose), [table_drop](../reference_manual/thrift_api.md#tabledrop), and [table_create](../reference_manual/thrift_api.md#tablecreate).

    try {

      if (!client.namespace_exists("test"))
        client.namespace_create("test");

      long ns = client.namespace_open("test");

      boolean if_exists = true;
      client.table_drop(ns, "Fruits", if_exists);

      Schema schema = new Schema();

      Map column_families = new HashMap();

      ColumnFamilySpec cf = new ColumnFamilySpec();
      cf.setName("genus");
      column_families.put("genus", cf);

      cf = new ColumnFamilySpec();
      cf.setName("description");
      column_families.put("description", cf);

      cf = new ColumnFamilySpec();
      cf.setName("tag");
      column_families.put("tag", cf);

      schema.setColumn_families(column_families);

      client.table_create(ns, "Fruits", schema);

      client.namespace_create("/test/sub");

      List listing;

      listing = client.namespace_get_listing(ns);

      for (NamespaceListing entry : listing)
        System.out.println(entry);

      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    NamespaceListing(name:Fruits, is_namespace:false)
    NamespaceListing(name:sub, is_namespace:true)

### Convenience APIs

####  set_cells

The following code snippet illustrates how to create [Cell](../reference_manual/thrift_api.md#cell) objects and insert them with the [set_cells](../reference_manual/thrift_api.md#setcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](java.md#basics) example.

    try {
      long ns = client.namespace_open("test");

      List cells = new ArrayList();
      Key key = null;
      Cell cell = null;

      key = new Key();
      key.setRow("apple");
      key.setColumn_family("genus");
      cell = new Cell();
      cell.setKey(key);
      cell.setValue("Malus".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key();
      key.setRow("apple");
      key.setColumn_family("description");
      cell = new Cell();
      cell.setKey(key);
      cell.setValue("The apple is the pomaceous fruit of the apple tree.".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key();
      key.setRow("apple");
      key.setColumn_family("tag");
      key.setColumn_qualifier("crunchy");
      cell = new Cell();
      cell.setKey(key);
      cells.add(cell);

      client.set_cells(ns, "Fruits", cells);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

####  get_cells

The following code snippet illustrates how to fetch cells with the [get_cells](../reference_manual/thrift_api.md#getcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();
      List columns = new ArrayList();
      columns.add("description");
      ss.setColumns(columns);

      List cells = client.get_cells(ns, "Fruits", ss);

      for (Cell cell : cells) {
        String value = null;
        if (cell.value != null)
          value = new String(cell.value.array(), cell.value.position(), cell.value.remaining(), "UTF-8");
        System.out.println(cell.key + " value=" + value);
      }
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:apple, column_family:description, column_qualifier:, timestamp:1403317495735021002, revision:1403317495735021002, flag:INSERT) value=The apple is the pomaceous fruit of the apple tree.

####  set_cells_as_arrays

The following code snippet illustrates how to create [CellAsArray](../reference_manual/thrift_api.md#cellasarray) objects and insert them with the [set_cells_as_arrays](../reference_manual/thrift_api.md#setcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    try {
      long ns = client.namespace_open("test");
      List> cells_as_arrays = new ArrayList>();
      List cell_as_array = null;

      cell_as_array = new ArrayList();
      cell_as_array.add("orange");
      cell_as_array.add("genus");
      cell_as_array.add("");
      cell_as_array.add("Citrus");
      cells_as_arrays.add(cell_as_array);

      cell_as_array = new ArrayList();
      cell_as_array.add("orange");
      cell_as_array.add("description");
      cell_as_array.add("");
      cell_as_array.add("The orange (specifically, the sweet orange) is" +
                        "the fruit of the citrus species Citrus x " +
                        "sinensis in the family Rutaceae.");
      cells_as_arrays.add(cell_as_array);

      cell_as_array = new ArrayList();
      cell_as_array.add("orange");
      cell_as_array.add("tag");
      cell_as_array.add("juicy");
      cells_as_arrays.add(cell_as_array);

      client.set_cells_as_arrays(ns, "Fruits", cells_as_arrays);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

####  get_cells_as_arrays

The following code snippet illustrates how to fetch cells with the [get_cells_as_arrays](../reference_manual/thrift_api.md#getcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();
      List columns = new ArrayList();
      columns.add("description");
      ss.setColumns(columns);

      List> cells_as_arrays = client.get_cells_as_arrays(ns, "Fruits", ss);

      for (List cell_as_array : cells_as_arrays)
        System.out.println(cell_as_array.subList(0, 4));

      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    [apple, description, , The apple is the pomaceous fruit of the apple tree.]
    [orange, description, , The orange (specifically, the sweet orange) isthe fruit of the citrus species Citrus x sinensis in the family Rutaceae.]

####  set_cells_serialized

The following code snippet illustrates how to insert cells with the [set_cells_serialized](../reference_manual/thrift_api.md#setcellsserialized) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    try {
      long ns = client.namespace_open("test");
      SerializedCellsWriter scw = new SerializedCellsWriter(1024);

      String valueStr = null;
      ByteBuffer valueBuf = null;

      valueStr = "Cucumis";
      valueBuf = ByteBuffer.wrap(valueStr.getBytes("UTF-8"));
      scw.add("canteloupe", "genus", "", SerializedCellsFlag.AUTO_ASSIGN,
              valueBuf);

      valueStr = "Canteloupe refers to a variety of Cucumis melo, a species in "+
        "the family Cucurbitaceae.";
      valueBuf = ByteBuffer.wrap(valueStr.getBytes("UTF-8"));
      scw.add("canteloupe", "description", "", SerializedCellsFlag.AUTO_ASSIGN,
              valueBuf);

      scw.add("canteloupe", "tag", "juicy", SerializedCellsFlag.AUTO_ASSIGN,
              ByteBuffer.allocate(0));

      scw.finalize((byte)0);

      client.set_cells_serialized(ns, "Fruits", scw.buffer());

      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

####  get_cells_serialized

The following code snippet illustrates how to fetch cells with the [get_cells_serialized](../reference_manual/thrift_api.md#getcellsserialized) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    try {
      long ns = client.namespace_open("test");

      ScanSpec ss = new ScanSpec();

      List columns = new ArrayList();
      columns.add("description");
      ss.setColumns(columns);

      ByteBuffer cells = client.get_cells_serialized(ns, "Fruits", ss);

      SerializedCellsReader reader = new SerializedCellsReader(cells);

      while (reader.next()) {
        String row = new String(reader.get_row(), "UTF-8");
        String column_family = new String(reader.get_column_family(), "UTF-8");
        String column_qualifier = "";
        String value = null;
        if (reader.get_column_qualifier() != null)
          column_qualifier = ":" + new String(reader.get_column_qualifier(), "UTF-8");
        if (reader.get_value() != null)
          value = new String(reader.get_value(), "UTF-8");
        System.out.println(row + "\t" + column_family + column_qualifier + "\t" + value);
      }
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    apple	description	The apple is the pomaceous fruit of the apple tree.
    canteloupe	description	Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.
    orange	description	The orange (specifically, the sweet orange) isthe fruit of the citrus species Citrus x sinensis in the family Rutaceae.

### Creating a table

The following code snippet illustrates how to create a table with the [table_create](../reference_manual/thrift_api.md#tablecreate) API. It introduces the API classes [Schema](../reference_manual/thrift_api.md#schema), [AccessGroupSpec](../reference_manual/thrift_api.md#accessgroupspec), [AccessGroupOptions](../reference_manual/thrift_api.md#accessgroupoptions), [ColumnFamilySpec](../reference_manual/thrift_api.md#columnfamilyspec), and [ColumnFamilyOptions](../reference_manual/thrift_api.md#columnfamilyoptions).

    try {
      long ns = client.namespace_open("test");

      Schema schema = new Schema();

      Map ag_specs = new HashMap();
      Map cf_specs = new HashMap();

      // Set table defaults
      {
        AccessGroupOptions ag_options = new AccessGroupOptions();
        ColumnFamilyOptions cf_options = new ColumnFamilyOptions();
        ag_options.setBlocksize(65536);
        schema.setAccess_group_defaults(ag_options);
        cf_options.setMax_versions(1);
        schema.setColumn_family_defaults(cf_options);
      }

      // Access group "ag_normal"
      {
        AccessGroupSpec ag = new AccessGroupSpec();
        ColumnFamilyOptions cf_options = new ColumnFamilyOptions();
        cf_options.setMax_versions(2);
        ag.setName("ag_normal");
        ag.setDefaults(cf_options);
        ag_specs.put("ag_normal", ag);
      }

      // Column "a"
      {
        ColumnFamilySpec cf = new ColumnFamilySpec();
        cf.setName("a");
        cf.setAccess_group("ag_normal");
        cf.setValue_index(true);
        cf.setQualifier_index(true);
        cf_specs.put("a", cf);
      }

      // Column "b"
      {
        ColumnFamilySpec cf = new ColumnFamilySpec();
        ColumnFamilyOptions cf_options = new ColumnFamilyOptions();
        cf.setName("b");
        cf.setAccess_group("ag_normal");
        cf_options.setMax_versions(3);
        cf.setOptions(cf_options);
        cf_specs.put("b", cf);
      }

      // Access group "ag_fast"
      {
        AccessGroupSpec ag = new AccessGroupSpec();
        AccessGroupOptions ag_options = new AccessGroupOptions();
        ag.setName("ag_fast");
        ag_options.setIn_memory(true);
        ag_options.setBlocksize(131072);
        ag.setOptions(ag_options);
        ag_specs.put("ag_fast", ag);
      }

      // Column "c"
      {
        ColumnFamilySpec cf = new ColumnFamilySpec();
        cf.setName("c");
        cf.setAccess_group("ag_fast");
        cf_specs.put("c", cf);
      }

      // Access group "ag_secure"
      {
        AccessGroupSpec ag = new AccessGroupSpec();
        AccessGroupOptions ag_options = new AccessGroupOptions();
        ag.setName("ag_secure");
        ag_options.setReplication((short)5);
        ag.setOptions(ag_options);
        ag_specs.put("ag_secure", ag);
      }

      // Column "d"
      {
        ColumnFamilySpec cf = new ColumnFamilySpec();
        cf.setName("d");
        cf.setAccess_group("ag_secure");
        cf_specs.put("d", cf);
      }

      // Access group "ag_counter"
      {
        AccessGroupSpec ag = new AccessGroupSpec();
        ColumnFamilyOptions cf_options = new ColumnFamilyOptions();
        ag.setName("ag_counter");
        cf_options.setCounter(true);
        cf_options.setMax_versions(0);
        ag.setDefaults(cf_options);
        ag_specs.put("ag_counter", ag);
      }

      // Column "e"
      {
        ColumnFamilySpec cf = new ColumnFamilySpec();
        cf.setName("e");
        cf.setAccess_group("ag_counter");
        cf_specs.put("e", cf);
      }

      // Column "f"
      {
        ColumnFamilySpec cf = new ColumnFamilySpec();
        ColumnFamilyOptions cf_options = new ColumnFamilyOptions();
        cf.setName("f");
        cf.setAccess_group("ag_counter");
        cf_options.setCounter(false);
        cf.setOptions(cf_options);
        cf_specs.put("f", cf);
      }

      schema.setAccess_groups(ag_specs);
      schema.setColumn_families(cf_specs);

      client.table_create(ns, "TestTable", schema);

      HqlResult result = client.hql_query(ns, "SHOW CREATE TABLE TestTable");

      if (!result.results.isEmpty())
        System.out.println(result.results.get(0));

      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

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

The following code snippet illustrates how to alter a table with the [table_alter](../reference_manual/thrift_api.md#tablealter) API. It assumes that the table _TestTable_ has been created as in the [Creating a table](java.md#creating-a-table) example.

    try {
      long ns = client.namespace_open("test");

      Schema schema = client.get_schema(ns, "TestTable");

      // Rename column "b" to "z"
      {
        ColumnFamilySpec cf_spec = schema.column_families.get("b");
        assert cf_spec != null;
        schema.column_families.remove("b");
        cf_spec.setName("z");
        schema.column_families.put("z", cf_spec);
      }

      // Add column "g"
      {
        ColumnFamilySpec cf_spec = new ColumnFamilySpec();
        cf_spec.setName("g");
        cf_spec.setAccess_group("ag_counter");
        schema.column_families.put("g", cf_spec);
      }

      client.table_alter(ns, "TestTable", schema);

      HqlResult result = client.hql_query(ns, "SHOW CREATE TABLE TestTable");

      if (!result.results.isEmpty())
        System.out.println(result.results.get(0));

      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

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

The code snippet below illustrates how to insert cells into a table using a mutator. The APIs introduced include [mutator_open](../reference_manual/thrift_api.md#mutatoropen), [mutator_set_cells](../reference_manual/thrift_api.md#mutatorsetcells), [mutator_flush](../reference_manual/thrift_api.md#mutatorflush), and [mutator_close](../reference_manual/thrift_api.md#mutatorclose). This example also makes use of the _datetime_to_ns_since_epoch_ function defined in [Appendix - helper functions](java.md#appendix---helper-functions).

    try {
      long ns = client.namespace_open("test");

      List cells = new ArrayList();
      Key key = null;
      Cell cell = null;
      String valueStr = null;

      long mutator = client.mutator_open(ns, "Fruits", 0, 0);

      // Auto-assigned timestamps

      key = new Key("lemon", "genus", null, KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("Citrus".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("lemon", "tag", "bitter", KeyFlag.INSERT);
      cell = new Cell(key);
      cells.add(cell);

      key = new Key("lemon", "description", null, KeyFlag.INSERT);
      cell = new Cell(key);
      valueStr = "The lemon (Citrus × limon) is a small evergreen tree native" +
        " to Asia.";
      cell.setValue(valueStr.getBytes("UTF-8"));
      cells.add(cell);

      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);

      // Explicitly-supplied timestamps

      cells.clear();

      key = new Key("mango", "genus", null, KeyFlag.INSERT);
      key.setTimestamp(datetime_to_ns_since_epoch("2014-06-06 16:27:15"));
      cell = new Cell(key);
      cell.setValue("Mangifera".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("mango", "tag", "sweet", KeyFlag.INSERT);
      key.setTimestamp(datetime_to_ns_since_epoch("2014-06-06 16:27:15"));
      cell = new Cell(key);
      cells.add(cell);

      key = new Key("mango", "description", null, KeyFlag.INSERT);
      key.setTimestamp(datetime_to_ns_since_epoch("2014-06-06 16:27:15"));
      cell = new Cell(key);
      valueStr = "Mango is one of the delicious seasonal fruits grown in the" +
        " tropics.";
      cell.setValue(valueStr.getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("mango", "description", null, KeyFlag.INSERT);
      key.setTimestamp(datetime_to_ns_since_epoch("2014-06-06 16:27:16"));
      cell = new Cell(key);
      valueStr = "The mango is a juicy stone fruit belonging to the genus " +
        "Mangifera, consisting of numerous tropical fruiting trees, that are" +
        " cultivated mostly for edible fruits.";
      cell.setValue(valueStr.getBytes("UTF-8"));
      cells.add(cell);

      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);

      // Delete cells

      cells.clear();

      key = new Key("apple", null, null, KeyFlag.DELETE_ROW);
      cell = new Cell(key);
      cells.add(cell);

      key = new Key("mango", "description", null, KeyFlag.DELETE_CELL);
      key.setTimestamp(datetime_to_ns_since_epoch("2014-06-06 16:27:15"));
      cell = new Cell(key);
      cells.add(cell);

      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);
      client.mutator_close(mutator);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

### Scanner

The following examples illustrate how to query a table using a scanner. The APIs introduced include the [scanner_open](../reference_manual/thrift_api.md#scanneropen), [scanner_get_cells](../reference_manual/thrift_api.md#scannergetcells), and [scanner_close](../reference_manual/thrift_api.md#scannerclose) functions, and the [ScanSpec](../reference_manual/thrift_api.md#scanspec) and [RowInterval](../reference_manual/thrift_api.md#rowinterval) classes.

####  Full table scan

The following code illustrates how to do a full table scan using the scanner APIs.

    try {
      long ns = client.namespace_open("test");

      System.out.println("[scanner - full table scan]");

      long scanner = client.scanner_open(ns, "Fruits", new ScanSpec());
      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      };
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    [scanner - full table scan]
    Key(row:canteloupe, column_family:description, column_qualifier:, timestamp:1403319340015500002, revision:1403319340015500002, flag:INSERT) value=Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.
    Key(row:canteloupe, column_family:genus, column_qualifier:, timestamp:1403319340015500001, revision:1403319340015500001, flag:INSERT) value=Cucumis
    Key(row:canteloupe, column_family:tag, column_qualifier:juicy, timestamp:1403319340015500003, revision:1403319340015500003, flag:INSERT) value=null
    Key(row:lemon, column_family:description, column_qualifier:, timestamp:1403319342652538003, revision:1403319342652538003, flag:INSERT) value=The lemon (Citrus × limon) is a small evergreen tree native to Asia.
    Key(row:lemon, column_family:genus, column_qualifier:, timestamp:1403319342652538001, revision:1403319342652538001, flag:INSERT) value=Citrus
    Key(row:lemon, column_family:tag, column_qualifier:bitter, timestamp:1403319342652538002, revision:1403319342652538002, flag:INSERT) value=null
    Key(row:mango, column_family:description, column_qualifier:, timestamp:1402097236000000000, revision:1403319342697849004, flag:INSERT) value=The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.
    Key(row:mango, column_family:genus, column_qualifier:, timestamp:1402097235000000000, revision:1403319342697849001, flag:INSERT) value=Mangifera
    Key(row:mango, column_family:tag, column_qualifier:sweet, timestamp:1402097235000000000, revision:1403319342697849002, flag:INSERT) value=null
    Key(row:orange, column_family:description, column_qualifier:, timestamp:1403319339964232002, revision:1403319339964232002, flag:INSERT) value=The orange (specifically, the sweet orange) isthe fruit of the citrus species Citrus x sinensis in the family Rutaceae.
    Key(row:orange, column_family:genus, column_qualifier:, timestamp:1403319339964232001, revision:1403319339964232001, flag:INSERT) value=Citrus
    Key(row:orange, column_family:tag, column_qualifier:juicy, timestamp:1403319339964232003, revision:1403319339964232003, flag:INSERT) value=null

####  Restricted scan with ScanSpec

The following code illustrates how to do a table scan using a ScanSpec.

    try {
      long ns = client.namespace_open("test");

      ScanSpec ss = new ScanSpec();
      List row_intervals = new ArrayList();

      // Row range [lemon..orange)
      RowInterval ri = new RowInterval();
      ri.setStart_row("lemon");
      ri.setStart_inclusive(true);
      ri.setEnd_row("orange");
      ri.setEnd_inclusive(false);
      row_intervals.add(ri);
      ss.setRow_intervals(row_intervals);

      // Return columns "genus", "tag:bitter", "tag:sweet"
      List columns = new ArrayList();
      columns.add("genus");
      columns.add("tag:bitter");
      columns.add("tag:sweet");
      ss.setColumns(columns);

      // Return only most recent version of each cell
      ss.setVersions(1);

      long scanner = client.scanner_open(ns, "Fruits", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      };
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:lemon, column_family:genus, column_qualifier:, timestamp:1403319342652538001, revision:1403319342652538001, flag:INSERT) value=Citrus
    Key(row:lemon, column_family:tag, column_qualifier:bitter, timestamp:1403319342652538002, revision:1403319342652538002, flag:INSERT) value=null
    Key(row:mango, column_family:genus, column_qualifier:, timestamp:1402097235000000000, revision:1403319342697849001, flag:INSERT) value=Mangifera
    Key(row:mango, column_family:tag, column_qualifier:sweet, timestamp:1402097235000000000, revision:1403319342697849002, flag:INSERT) value=null

### HQL

####  hql_query

The following code illustrates how to issue HQL commands with the [hql_query](../reference_manual/thrift_api.md#hqlquery) API. It also introduces the [HqlResult](../reference_manual/thrift_api.md#hqlresult) class.

    try {
      long ns = client.namespace_open("test");

      HqlResult result = client.hql_query(ns, "get listing");
      for (String entry : result.results)
        System.out.println(entry);

      result = client.hql_query(ns, "SELECT * from Fruits WHERE ROW = 'pear'");
      for (Cell cell : result.cells) {
        String value = null;
        if (cell.value != null)
          value = new String(cell.value.array(), cell.value.position(),
                             cell.value.remaining(), "UTF-8");
        System.out.println(cell.key + " value=" + value);
      }

      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Fruits
    TestTable
    ^TestTable
    ^^TestTable
    sub	(namespace)

####  hql_query_as_arrays

The following code illustrates how to issue an HQL query with the [hql_query_as_arrays](../reference_manual/thrift_api.md#hqlqueryasarrays) API. It also introduces the [HqlResultAsArrays](../reference_manual/thrift_api.md#hqlresultasarrays) class.

    try {
      long ns = client.namespace_open("test");
      HqlResultAsArrays result_as_arrays =
        client.hql_query_as_arrays(ns, "SELECT * from Fruits WHERE ROW = 'lemon'");
      for (List cell_as_array : result_as_arrays.cells)
        System.out.println(cell_as_array.subList(0, 4));
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    [lemon, description, , The lemon (Citrus × limon) is a small evergreen tree native to Asia.]
    [lemon, genus, , Citrus]
    [lemon, tag, bitter, ]

####  hql_exec (mutator)

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a mutator.

    try {
      long ns = client.namespace_open("test");
      HqlResult result =
        client.hql_exec(ns, "INSERT INTO Fruits VALUES ('strawberry'," +
                        " 'genus', 'Fragaria'), ('strawberry', 'tag:fibrous'," +
                        " ''), ('strawberry', 'description', 'The garden " +
                        "strawberry is a widely grown hybrid species of the " +
                        "genus Fragaria')", true, false);
      List cells = new ArrayList();
      Cell cell = null;
      Key key = null;

      key = new Key("pineapple", "genus", null, KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("Ananas".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("pineapple", "tag", "acidic", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("Ananas".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("pineapple", "description", null, KeyFlag.INSERT);
      cell = new Cell(key);
      String valueStr =
        "The pineapple (Ananas comosus) is a tropical plant with " +
        "edible multiple fruit consisting of coalesced berries.";
      cell.setValue(valueStr.getBytes("UTF-8"));
      cells.add(cell);

      client.mutator_set_cells(result.mutator, cells);
      client.mutator_flush(result.mutator);
      client.mutator_close(result.mutator);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

####  hql_exec (scanner}

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a scanner.

    try {
      long ns = client.namespace_open("test");
      HqlResult result = client.hql_exec(ns, "SELECT * from Fruits", false, true);

      while (true) {
        List cells = client.scanner_get_cells(result.scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(result.scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:canteloupe, column_family:description, column_qualifier:, timestamp:1403319661205526002, revision:1403319661205526002, flag:INSERT) value=Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.
    Key(row:canteloupe, column_family:genus, column_qualifier:, timestamp:1403319661205526001, revision:1403319661205526001, flag:INSERT) value=Cucumis
    Key(row:canteloupe, column_family:tag, column_qualifier:juicy, timestamp:1403319661205526003, revision:1403319661205526003, flag:INSERT) value=null
    Key(row:lemon, column_family:description, column_qualifier:, timestamp:1403319664253694003, revision:1403319664253694003, flag:INSERT) value=The lemon (Citrus × limon) is a small evergreen tree native to Asia.
    Key(row:lemon, column_family:genus, column_qualifier:, timestamp:1403319664253694001, revision:1403319664253694001, flag:INSERT) value=Citrus
    Key(row:lemon, column_family:tag, column_qualifier:bitter, timestamp:1403319664253694002, revision:1403319664253694002, flag:INSERT) value=null
    Key(row:mango, column_family:description, column_qualifier:, timestamp:1402097236000000000, revision:1403319664294189004, flag:INSERT) value=The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.
    Key(row:mango, column_family:genus, column_qualifier:, timestamp:1402097235000000000, revision:1403319664294189001, flag:INSERT) value=Mangifera
    Key(row:mango, column_family:tag, column_qualifier:sweet, timestamp:1402097235000000000, revision:1403319664294189002, flag:INSERT) value=null
    Key(row:orange, column_family:description, column_qualifier:, timestamp:1403319661140883002, revision:1403319661140883002, flag:INSERT) value=The orange (specifically, the sweet orange) isthe fruit of the citrus species Citrus x sinensis in the family Rutaceae.
    Key(row:orange, column_family:genus, column_qualifier:, timestamp:1403319661140883001, revision:1403319661140883001, flag:INSERT) value=Citrus
    Key(row:orange, column_family:tag, column_qualifier:juicy, timestamp:1403319661140883003, revision:1403319661140883003, flag:INSERT) value=null
    Key(row:pineapple, column_family:description, column_qualifier:, timestamp:1403319664448375003, revision:1403319664448375003, flag:INSERT) value=The pineapple (Ananas comosus) is a tropical plant with edible multiple fruit consisting of coalesced berries.
    Key(row:pineapple, column_family:genus, column_qualifier:, timestamp:1403319664448375001, revision:1403319664448375001, flag:INSERT) value=Ananas
    Key(row:pineapple, column_family:tag, column_qualifier:acidic, timestamp:1403319664448375002, revision:1403319664448375002, flag:INSERT) value=Ananas
    Key(row:strawberry, column_family:description, column_qualifier:, timestamp:1403319664448375006, revision:1403319664448375006, flag:INSERT) value=The garden strawberry is a widely grown hybrid species of the genus Fragaria
    Key(row:strawberry, column_family:genus, column_qualifier:, timestamp:1403319664448375004, revision:1403319664448375004, flag:INSERT) value=Fragaria
    Key(row:strawberry, column_family:tag, column_qualifier:fibrous, timestamp:1403319664448375005, revision:1403319664448375005, flag:INSERT) value=null

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

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List column_predicates = new ArrayList();
      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("section");
      column_predicate.setOperation(ColumnPredicateOperation.EXACT_MATCH.getValue());
      column_predicate.setValue("books");
      column_predicates.add(column_predicate);
      ss.setColumn_predicates(column_predicates);

      List columns = new ArrayList();
      columns.add("title");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:0307743659, column_family:title, column_qualifier:, timestamp:1403320553816367001, revision:1403320553816367001, flag:INSERT) value=The Shining Mass Market Paperback
    Key(row:0321321928, column_family:title, column_qualifier:, timestamp:1403320553816367008, revision:1403320553816367008, flag:INSERT) value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    Key(row:0321776402, column_family:title, column_qualifier:, timestamp:1403320553816367019, revision:1403320553816367019, flag:INSERT) value=C++ Primer Plus (6th Edition) (Developer's Library)

####  Value index (exact match with qualifier)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title FROM products WHERE info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List column_predicates = new ArrayList();
      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("actor");
      int operation = ColumnPredicateOperation.EXACT_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("Jack Nicholson");
      column_predicates.add(column_predicate);
      ss.setColumn_predicates(column_predicates);

      List columns = new ArrayList();
      columns.add("title");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:B00002VWE0, column_family:title, column_qualifier:, timestamp:1403320553816367030, revision:1403320553816367030, flag:INSERT) value=Five Easy Pieces (1970)
    Key(row:B002VWNIDG, column_family:title, column_qualifier:, timestamp:1403320553816367049, revision:1403320553816367049, flag:INSERT) value=The Shining (1980)

####  Value index (prefix match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =^ 'Addison-Wesley';

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List column_predicates = new ArrayList();
      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("publisher");
      int operation = ColumnPredicateOperation.PREFIX_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("Addison-Wesley");
      column_predicates.add(column_predicate);
      ss.setColumn_predicates(column_predicates);

      List columns = new ArrayList();
      columns.add("title");
      columns.add("info:publisher");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:0321321928, column_family:title, column_qualifier:, timestamp:1403320553816367008, revision:1403320553816367008, flag:INSERT) value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    Key(row:0321321928, column_family:info, column_qualifier:publisher, timestamp:1403320553738502000, revision:1403320553816367013, flag:INSERT) value=Addison-Wesley Professional; 1 edition (March 10, 2005)
    Key(row:0321776402, column_family:title, column_qualifier:, timestamp:1403320553816367019, revision:1403320553816367019, flag:INSERT) value=C++ Primer Plus (6th Edition) (Developer's Library)
    Key(row:0321776402, column_family:info, column_qualifier:publisher, timestamp:1403320553738081000, revision:1403320553816367024, flag:INSERT) value=Addison-Wesley Professional; 6 edition (October 28, 2011)

####  Value index (regex match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =~ /^Addison-Wesley/;

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List column_predicates = new ArrayList();
      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("publisher");
      int operation = ColumnPredicateOperation.REGEX_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("^Addison-Wesley");
      column_predicates.add(column_predicate);
      ss.setColumn_predicates(column_predicates);

      List columns = new ArrayList();
      columns.add("title");
      columns.add("info:publisher");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:0321321928, column_family:title, column_qualifier:, timestamp:1403320553816367008, revision:1403320553816367008, flag:INSERT) value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    Key(row:0321321928, column_family:info, column_qualifier:publisher, timestamp:1403320553738502000, revision:1403320553816367013, flag:INSERT) value=Addison-Wesley Professional; 1 edition (March 10, 2005)
    Key(row:0321776402, column_family:title, column_qualifier:, timestamp:1403320553816367019, revision:1403320553816367019, flag:INSERT) value=C++ Primer Plus (6th Edition) (Developer's Library)
    Key(row:0321776402, column_family:info, column_qualifier:publisher, timestamp:1403320553738081000, revision:1403320553816367024, flag:INSERT) value=Addison-Wesley Professional; 6 edition (October 28, 2011)

####  Qualifier index (exists)

The following HQL query which leverages the qualifier index of the _info_ column:

    SELECT title FROM products WHERE Exists(info:studio);

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List column_predicates = new ArrayList();
      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("studio");
      column_predicate.setOperation(ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue());
      column_predicates.add(column_predicate);
      ss.setColumn_predicates(column_predicates);

      List columns = new ArrayList();
      columns.add("title");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:B00002VWE0, column_family:title, column_qualifier:, timestamp:1403320553816367030, revision:1403320553816367030, flag:INSERT) value=Five Easy Pieces (1970)
    Key(row:B000Q66J1M, column_family:title, column_qualifier:, timestamp:1403320553816367039, revision:1403320553816367039, flag:INSERT) value=2001: A Space Odyssey [Blu-ray]
    Key(row:B002VWNIDG, column_family:title, column_qualifier:, timestamp:1403320553816367049, revision:1403320553816367049, flag:INSERT) value=The Shining (1980)

####  Qualifier index (exists regex prefix match)

The following HQL query which leverages the qualifier index of the _category_ column:

    SELECT title FROM products WHERE Exists(category:/^\/Movies/);

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List column_predicates = new ArrayList();
      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("category");
      column_predicate.setColumn_qualifier("^/Movies");
      column_predicate.setOperation(ColumnPredicateOperation.QUALIFIER_REGEX_MATCH.getValue());
      column_predicates.add(column_predicate);
      ss.setColumn_predicates(column_predicates);

      List columns = new ArrayList();
      columns.add("title");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:B00002VWE0, column_family:title, column_qualifier:, timestamp:1403320553816367030, revision:1403320553816367030, flag:INSERT) value=Five Easy Pieces (1970)
    Key(row:B000Q66J1M, column_family:title, column_qualifier:, timestamp:1403320553816367039, revision:1403320553816367039, flag:INSERT) value=2001: A Space Odyssey [Blu-ray]
    Key(row:B002VWNIDG, column_family:title, column_qualifier:, timestamp:1403320553816367049, revision:1403320553816367049, flag:INSERT) value=The Shining (1980)

####  Value index (OR query)

The following HQL query performs a boolean _OR_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen P/ OR info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List column_predicates = new ArrayList();

      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("author");
      int operation = ColumnPredicateOperation.REGEX_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("^Stephen P");
      column_predicates.add(column_predicate);

      column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("publisher");
      operation = ColumnPredicateOperation.PREFIX_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("Anchor");
      column_predicates.add(column_predicate);

      ss.setColumn_predicates(column_predicates);

      List columns = new ArrayList();
      columns.add("title");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:0307743659, column_family:title, column_qualifier:, timestamp:1403320553816367001, revision:1403320553816367001, flag:INSERT) value=The Shining Mass Market Paperback
    Key(row:0321776402, column_family:title, column_qualifier:, timestamp:1403320553816367019, revision:1403320553816367019, flag:INSERT) value=C++ Primer Plus (6th Edition) (Developer's Library)

####  Value index (AND query)

The following HQL query performs a boolean _AND_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List column_predicates = new ArrayList();

      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("author");
      int operation = ColumnPredicateOperation.REGEX_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("^Stephen [PK]");
      column_predicates.add(column_predicate);

      column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("publisher");
      operation = ColumnPredicateOperation.PREFIX_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("Anchor");
      column_predicates.add(column_predicate);

      ss.setColumn_predicates(column_predicates);

      // AND predicates together
      ss.setAnd_column_predicates(true);

      List columns = new ArrayList();
      columns.add("title");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:0307743659, column_family:title, column_qualifier:, timestamp:1403320553816367001, revision:1403320553816367001, flag:INSERT) value=The Shining Mass Market Paperback

####  Value index (AND row interval)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW interval:

    SELECT title
      FROM products
      WHERE ROW > 'B00002VWE0' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List row_intervals = new ArrayList();
      RowInterval ri = new RowInterval();;
      ri.setStart_row("B00002VWE0");
      ri.setStart_inclusive(false);
      row_intervals.add(ri);
      ss.setRow_intervals(row_intervals);

      List column_predicates = new ArrayList();

      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("actor");
      int operation = ColumnPredicateOperation.EXACT_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("Jack Nicholson");
      column_predicates.add(column_predicate);

      ss.setColumn_predicates(column_predicates);

      ss.setAnd_column_predicates(true);

      List columns = new ArrayList();
      columns.add("title");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:B002VWNIDG, column_family:title, column_qualifier:, timestamp:1403320553816367049, revision:1403320553816367049, flag:INSERT) value=The Shining (1980)

####  Value index (AND row prefix)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW prefix interval:

    SELECT title
      FROM products
      WHERE ROW =^ 'B' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      long ns = client.namespace_open("test");
      ScanSpec ss = new ScanSpec();

      List row_intervals = new ArrayList();
      RowInterval ri = new RowInterval();;
      ri.setStart_row("B");
      ri.setStart_inclusive(true);
      ri.setEnd_row("C");
      ri.setEnd_inclusive(false);
      row_intervals.add(ri);
      ss.setRow_intervals(row_intervals);

      List column_predicates = new ArrayList();

      ColumnPredicate column_predicate = new ColumnPredicate();
      column_predicate.setColumn_family("info");
      column_predicate.setColumn_qualifier("actor");
      int operation = ColumnPredicateOperation.EXACT_MATCH.getValue() |
        ColumnPredicateOperation.QUALIFIER_EXACT_MATCH.getValue();
      column_predicate.setOperation(operation);
      column_predicate.setValue("Jack Nicholson");
      column_predicates.add(column_predicate);

      ss.setColumn_predicates(column_predicates);

      ss.setAnd_column_predicates(true);

      List columns = new ArrayList();
      columns.add("title");
      ss.setColumns(columns);

      long scanner = client.scanner_open(ns, "products", ss);

      while (true) {
        List cells = client.scanner_get_cells(scanner);
        if (cells.isEmpty())
          break;
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:B00002VWE0, column_family:title, column_qualifier:, timestamp:1403320553816367030, revision:1403320553816367030, flag:INSERT) value=Five Easy Pieces (1970)
    Key(row:B002VWNIDG, column_family:title, column_qualifier:, timestamp:1403320553816367049, revision:1403320553816367049, flag:INSERT) value=The Shining (1980)

### Asynchronous APIs

This section describes how to use the asynchronous APIs. The examples assume that tables _Profile_ and _Session_ are created and loaded with the following HQL commands.

    CREATE TABLE Profile (info, last_access MAX_VERSIONS 1);

    CREATE TABLE Session (user_id, page_hit);

    INSERT INTO Profile
      VALUES ('1', 'info:name', 'Joe'), ('2', 'info:name', 'Sue');

####  Async mutator

The code snippet below illustrates how to insert cells into multiple tables simultaneously using an asynchronous mutator. The APIs introduced include the [future_open](../reference_manual/thrift_api.md#futureopen), [future_get_result](../reference_manual/thrift_api.md#futuregetresult), [future_close](../reference_manual/thrift_api.md#futureclose), [async_mutator_open](../reference_manual/thrift_api.md#asyncmutatoropen), [async_mutator_set_cells](../reference_manual/thrift_api.md#asyncmutatorsetcells), [async_mutator_flush](../reference_manual/thrift_api.md#asyncmutatorflush), and [async_mutator_close](../reference_manual/thrift_api.md#asyncmutatorclose) functions and the [Result](../reference_manual/thrift_api.md#result) class.

    try {
      long ns = client.namespace_open("test");
      long ff = client.future_open(0);
      long profile_mutator = client.async_mutator_open(ns, "Profile", ff, 0);
      long session_mutator = client.async_mutator_open(ns, "Session", ff, 0);
      List cells = new ArrayList();
      Key key;
      Cell cell;

      key = new Key("1", "last_access", null, KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("2014-06-13 16:06:09".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("2", "last_access", null, KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("2014-06-13 16:06:10".getBytes("UTF-8"));
      cells.add(cell);

      client.async_mutator_set_cells(profile_mutator, cells);

      cells.clear();

      key = new Key("0001-200238", "user_id", "1", KeyFlag.INSERT);
      cell = new Cell(key);
      cells.add(cell);

      key = new Key("0001-200238", "page_hit", null, KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("/index.html".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("0002-383049", "user_id", "2", KeyFlag.INSERT);
      cell = new Cell(key);
      cells.add(cell);

      key = new Key("0002-383049", "page_hit", null, KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("/foo/bar.html".getBytes("UTF-8"));
      cells.add(cell);

      client.async_mutator_set_cells(session_mutator, cells);

      client.async_mutator_flush(profile_mutator);
      client.async_mutator_flush(session_mutator);

      int result_count = 0;
      while (true) {
        Result result = client.future_get_result(ff, 0);
        if (result.is_empty)
          break;
        result_count++;
        if (result.is_error) {
          System.out.println("Async mutator error:  " + result.error_msg);
          System.exit(1);
        }
        if (result.id == profile_mutator)
          System.out.println("Result is from Profile mutation");
        else if (result.id == session_mutator)
          System.out.println("Result is from Session mutation");
      }

      System.out.println("result count = " + result_count);

      client.async_mutator_close(profile_mutator);
      client.async_mutator_close(session_mutator);
      client.future_close(ff);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile mutation
    Result is from Session mutation
    result count = 2

####  Async scanner (Result)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [Result](../reference_manual/thrift_api.md#result) object. The APIs introduced include the [async_scanner_open](../reference_manual/thrift_api.md#asyncscanneropen) and [async_scanner_close](../reference_manual/thrift_api.md#asyncscannerclose) functions.

    try {
      long ns = client.namespace_open("test");
      long profile_scanner;
      long session_scanner;
      long ff = client.future_open(0);

      {
        ScanSpec ss = new ScanSpec();
        List row_intervals = new ArrayList();
        RowInterval ri = new RowInterval();
        ri.setStart_row("1");
        ri.setStart_inclusive(true);
        ri.setEnd_row("1");
        ri.setEnd_inclusive(true);
        row_intervals.add(ri);
        ss.setRow_intervals(row_intervals);
        profile_scanner = client.async_scanner_open(ns, "Profile", ff, ss);
      }

      {
        ScanSpec ss = new ScanSpec();
        List row_intervals = new ArrayList();
        RowInterval ri = new RowInterval();
        ri.setStart_row("0001-200238");
        ri.setStart_inclusive(true);
        ri.setEnd_row("0001-200238");
        ri.setEnd_inclusive(true);
        row_intervals.add(ri);
        ss.setRow_intervals(row_intervals);
        session_scanner = client.async_scanner_open(ns, "Session", ff, ss);
      }

      while (true) {

        Result result = client.future_get_result(ff, 0);

        if (result.is_empty)
          break;

        if (result.is_error) {
          System.out.println("Async scanner error:  " + result.error_msg);
          System.exit(1);
        }

        assert result.is_scan;
        assert result.id == profile_scanner || result.id == session_scanner;

        if (result.id == profile_scanner)
          System.out.println("Result is from Profile scan");
        else if (result.id == session_scanner)
          System.out.println("Result is from Session scan");

        for (Cell cell : result.cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      }

      client.async_scanner_close(profile_scanner);
      client.async_scanner_close(session_scanner);
      client.future_close(ff);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile scan
    Key(row:1, column_family:info, column_qualifier:name, timestamp:1403321077084350001, revision:1403321077084350001, flag:INSERT) value=Joe
    Key(row:1, column_family:last_access, column_qualifier:, timestamp:1403321077166867001, revision:1403321077166867001, flag:INSERT) value=2014-06-13 16:06:09
    Result is from Session scan
    Key(row:0001-200238, column_family:user_id, column_qualifier:1, timestamp:1403321077169863001, revision:1403321077169863001, flag:INSERT) value=null
    Key(row:0001-200238, column_family:page_hit, column_qualifier:, timestamp:1403321077169863002, revision:1403321077169863002, flag:INSERT) value=/index.html

####  Async scanner (ResultSerialized)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultSerialized](../reference_manual/thrift_api.md#resultserialized) object. This example introduces the [future_get_result_serialized](../reference_manual/thrift_api.md#futuregetresultserialized) API.

    try {
      long profile_scanner;
      long session_scanner;
      long ns = client.namespace_open("test");
      long ff = client.future_open(0);

      {
        ScanSpec ss = new ScanSpec();
        List row_intervals = new ArrayList();
        RowInterval ri = new RowInterval();
        ri.setStart_row("1");
        ri.setStart_inclusive(true);
        ri.setEnd_row("1");
        ri.setEnd_inclusive(true);
        row_intervals.add(ri);
        ss.setRow_intervals(row_intervals);
        profile_scanner = client.async_scanner_open(ns, "Profile", ff, ss);
      }

      {
        ScanSpec ss = new ScanSpec();
        List row_intervals = new ArrayList();
        RowInterval ri = new RowInterval();
        ri.setStart_row("0001-200238");
        ri.setStart_inclusive(true);
        ri.setEnd_row("0001-200238");
        ri.setEnd_inclusive(true);
        row_intervals.add(ri);
        ss.setRow_intervals(row_intervals);
        session_scanner = client.async_scanner_open(ns, "Session", ff, ss);
      }

      while (true) {

        ResultSerialized result_serialized =
          client.future_get_result_serialized(ff, 0);

        if (result_serialized.is_empty)
          break;

        if (result_serialized.is_error) {
          System.out.println("Async scanner error:  " + result_serialized.error_msg);
          System.exit(1);
        }

        assert(result_serialized.is_scan);
        assert(result_serialized.id == profile_scanner || result_serialized.id == session_scanner);

        if (result_serialized.id == profile_scanner)
          System.out.println("Result is from Profile scan");
        else if (result_serialized.id == session_scanner)
          System.out.println("Result is from Session scan");

        SerializedCellsReader reader =
          new SerializedCellsReader(result_serialized.cells);

        while (reader.next()) {
          String row = new String(reader.get_row(), "UTF-8");
          String column_family = new String(reader.get_column_family(), "UTF-8");
          String column_qualifier = "";
          String value = null;
          if (reader.get_column_qualifier() != null)
            column_qualifier = ":" + new String(reader.get_column_qualifier(), "UTF-8");
          if (reader.get_value() != null)
            value = new String(reader.get_value(), "UTF-8");
          System.out.println(row + "\t" + column_family + column_qualifier + "\t" + value);
        }

      }
      client.async_scanner_close(profile_scanner);
      client.async_scanner_close(session_scanner);
      client.future_close(ff);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile scan
    1	info:name	Joe
    1	last_access	2014-06-13 16:06:09
    Result is from Session scan
    0001-200238	user_id:1	null
    0001-200238	page_hit	/index.html

####  Async scanner (ResultAsArrays)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultAsArrays](../reference_manual/thrift_api.md#resultasarrays) object. This example introduces the [future_get_result_as_arrays](../reference_manual/thrift_api.md#futuregetresultasarrays) API.

    try {
      long profile_scanner;
      long session_scanner;
      long ns = client.namespace_open("test");
      long ff = client.future_open(0);

      {
        ScanSpec ss = new ScanSpec();
        List row_intervals = new ArrayList();
        RowInterval ri = new RowInterval();
        ri.setStart_row("1");
        ri.setStart_inclusive(true);
        ri.setEnd_row("1");
        ri.setEnd_inclusive(true);
        row_intervals.add(ri);
        ss.setRow_intervals(row_intervals);
        profile_scanner = client.async_scanner_open(ns, "Profile", ff, ss);
      }

      {
        ScanSpec ss = new ScanSpec();
        List row_intervals = new ArrayList();
        RowInterval ri = new RowInterval();
        ri.setStart_row("0001-200238");
        ri.setStart_inclusive(true);
        ri.setEnd_row("0001-200238");
        ri.setEnd_inclusive(true);
        row_intervals.add(ri);
        ss.setRow_intervals(row_intervals);
        session_scanner = client.async_scanner_open(ns, "Session", ff, ss);
      }

      while (true) {

        ResultAsArrays result_as_arrays =
          client.future_get_result_as_arrays(ff, 0);

        if (result_as_arrays.is_empty)
          break;

        if (result_as_arrays.is_error) {
          System.out.println("Async scanner error:  " + result_as_arrays.error_msg);
          System.exit(1);
        }

        assert result_as_arrays.is_scan;
        assert result_as_arrays.id == profile_scanner ||
          result_as_arrays.id == session_scanner;

        if (result_as_arrays.id == profile_scanner)
          System.out.println("Result is from Profile scan");
        else if (result_as_arrays.id == session_scanner)
          System.out.println("Result is from Session scan");

        for (List cell_as_array : result_as_arrays.cells)
          System.out.println(cell_as_array.subList(0, 4));
      }

      client.async_scanner_close(profile_scanner);
      client.async_scanner_close(session_scanner);
      client.future_close(ff);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile scan
    [1, info, name, Joe]
    [1, last_access, , 2014-06-13 16:06:09]
    Result is from Session scan
    [0001-200238, user_id, 1, ]
    [0001-200238, page_hit, , /index.html]

### Atomic Counters

This section describes how to use atomic counters. The examples assume that a  _Hits_ table has been created with the following HQL command.

    CREATE TABLE Hits (count COUNTER);

####  Increment

The code snippet below illustrates how to increment per-second hit counts for pages of a website.

    try {
      long ns = client.namespace_open("test");
      long mutator = client.mutator_open(ns, "Hits", 0, 0);

      Key key;
      Cell cell;
      List cells = new ArrayList();

      key = new Key("/index.html", "count", "2014-06-14 07:31:18", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/index.html", "count", "2014-06-14 07:31:18", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/foo/bar.html", "count", "2014-06-14 07:31:18", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/foo/bar.html", "count", "2014-06-14 07:31:18", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/foo/bar.html", "count", "2014-06-14 07:31:18", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/index.html", "count", "2014-06-14 07:31:19", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/index.html", "count", "2014-06-14 07:31:19", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/index.html", "count", "2014-06-14 07:31:19", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/index.html", "count", "2014-06-14 07:31:19", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/foo/bar.html", "count", "2014-06-14 07:31:19", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("1".getBytes("UTF-8"));
      cells.add(cell);

      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);

      long scanner = client.scanner_open(ns, "Hits", new ScanSpec());

      do {
        cells = client.scanner_get_cells(scanner);
        for (Cell cell2 : cells) {
          String value = null;
          if (cell2.value != null)
            value = new String(cell2.value.array(), cell2.value.position(),
                               cell2.value.remaining(), "UTF-8");
          System.out.println(cell2.key + " value=" + value);
        }
      } while (!cells.isEmpty());

      client.scanner_close(scanner);
      client.mutator_close(mutator);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:/foo/bar.html, column_family:count, column_qualifier:2014-06-14 07:31:18, timestamp:1403321992314486003, revision:1403321992314486003, flag:INSERT) value=3
    Key(row:/foo/bar.html, column_family:count, column_qualifier:2014-06-14 07:31:19, timestamp:1403321992314486004, revision:1403321992314486004, flag:INSERT) value=1
    Key(row:/index.html, column_family:count, column_qualifier:2014-06-14 07:31:18, timestamp:1403321992314486006, revision:1403321992314486006, flag:INSERT) value=2
    Key(row:/index.html, column_family:count, column_qualifier:2014-06-14 07:31:19, timestamp:1403321992314486010, revision:1403321992314486010, flag:INSERT) value=4

####  Reset and subtraction

The code snippet below illustrates how to reset and subtract from counters.

    try {
      long ns = client.namespace_open("test");
      long mutator = client.mutator_open(ns, "Hits", 0, 0);

      Key key;
      Cell cell;
      List cells = new ArrayList();

      key = new Key("/index.html", "count", "2014-06-14 07:31:18", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("=0".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/index.html", "count", "2014-06-14 07:31:18", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("7".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/foo/bar.html", "count", "2014-06-14 07:31:18", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("-1".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/index.html", "count", "2014-06-14 07:31:19", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("-2".getBytes("UTF-8"));
      cells.add(cell);

      key = new Key("/foo/bar.html", "count", "2014-06-14 07:31:19", KeyFlag.INSERT);
      cell = new Cell(key);
      cell.setValue("=19".getBytes("UTF-8"));
      cells.add(cell);

      client.mutator_set_cells(mutator, cells);
      client.mutator_flush(mutator);

      long scanner = client.scanner_open(ns, "Hits", new ScanSpec());

      do {
        cells = client.scanner_get_cells(scanner);
        for (Cell cell2 : cells) {
          String value = null;
          if (cell2.value != null)
            value = new String(cell2.value.array(), cell2.value.position(),
                               cell2.value.remaining(), "UTF-8");
          System.out.println(cell2.key + " value=" + value);
        }
      } while (!cells.isEmpty());

      client.scanner_close(scanner);
      client.mutator_close(mutator);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    Key(row:/foo/bar.html, column_family:count, column_qualifier:2014-06-14 07:31:18, timestamp:1403321992370474001, revision:1403321992370474001, flag:INSERT) value=2
    Key(row:/foo/bar.html, column_family:count, column_qualifier:2014-06-14 07:31:19, timestamp:1403321992370474002, revision:1403321992370474002, flag:INSERT) value=19
    Key(row:/index.html, column_family:count, column_qualifier:2014-06-14 07:31:18, timestamp:1403321992370474004, revision:1403321992370474004, flag:INSERT) value=7
    Key(row:/index.html, column_family:count, column_qualifier:2014-06-14 07:31:19, timestamp:1403321992370474005, revision:1403321992370474005, flag:INSERT) value=2

### Creating unique keys

This section illustrates how to create unique keys using the [create_cell_unique](../reference_manual/thrift_api.md#createcellunique) API. The example show how you can create unique user IDs for an application. The code assumes that a _User_ table has been created with the following HQL command.

    CREATE TABLE User (info, id TIME_ORDER desc MAX_VERSIONS 1);

The example code snippet is as follows.

    try {
      Key key;
      String ret;
      long ns = client.namespace_open("test");
      key = new Key();
      key.setColumn_family("id");
      key.setRow("joe1987");
      ret = client.create_cell_unique(ns, "User", key, null);
      key = new Key();
      key.setColumn_family("id");
      key.setRow("mary.bellweather");
      ret = client.create_cell_unique(ns, "User", key, null);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

    Key key = new Key();
    try {
      long ns = client.namespace_open("test");
      key = new Key();
      key.setColumn_family("id");
      key.setRow("joe1987");
      String ret = client.create_cell_unique(ns, "User", key, null);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      if (e.code == org.hypertable.Common.Error.ALREADY_EXISTS)
        System.out.println("User name '" + key.row + "' is already taken");
      else {
        System.out.println(e.message);
        System.exit(1);
      }
    }

    try {
      long ns = client.namespace_open("test");
      long scanner = client.scanner_open(ns, "User", new ScanSpec());
      List cells;
      do {
        cells = client.scanner_get_cells(scanner);
        for (Cell cell : cells) {
          String value = null;
          if (cell.value != null)
            value = new String(cell.value.array(), cell.value.position(),
                               cell.value.remaining(), "UTF-8");
          System.out.println(cell.key + " value=" + value);
        }
      } while (!cells.isEmpty());
      client.scanner_close(scanner);
      client.namespace_close(ns);
    }
    catch (ClientException e) {
      System.out.println(e.message);
      System.exit(1);
    }

The following is example output produced by the above code snippet.

    User name 'joe1987' is already taken
    Key(row:joe1987, column_family:id, column_qualifier:, timestamp:1403322524534105001, revision:1403322524534105001, flag:INSERT) value=3e53c5d7-0e8d-40c4-a1ad-aa0bb939b942
    Key(row:mary.bellweather, column_family:id, column_qualifier:, timestamp:1403322524589873001, revision:1403322524589873001, flag:INSERT) value=8159982a-d14b-4837-b385-33892a649c57

### Appendix - helper functions

The following helper functions are used in the examples in this document.

    public static long datetime_to_ns_since_epoch(String dateStr) throws ParseException {
      DateFormat format = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
      Date datem = format.parse(dateStr);
      return datem.getTime() * 1000000L;
    }
