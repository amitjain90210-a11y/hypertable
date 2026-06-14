# Ruby

## Table of Contents

### Introduction

This document presents example Ruby code that excercises the Thrift API. To quickly get Hypertable up and running on a single machine so that you can try out these examples, see [Hypertable Standalone Installation](../installation/quick_start_standalone.md). The source code for all of the examples in this document, along with the build and run scripts, can be found in [hypertable_api_example.tgz](http://hypertable.com/pub/hypertable_api_example.tgz).

### Environment setup and running

To execute our ruby script, we need to tell the ruby interpreter where to find the Hypertable thrift client library scripts. To do that, we pass a -I argument to the ruby interpreter. The script also needs to know where to find the thrift_client.rb file and for that it consults the _HYPERTABLE_HOME_ environment variable. The following bash script illustrates how to setup the environment and run a Hypertable ruby thrift client script.

    HYPERTABLE_HOME=/opt/hypertable/current

    export HYPERTABLE_HOME

    ruby -I ${HYPERTABLE_HOME}/lib/rb hypertable_api_test.rb

### Program boilerplate

The following statements are required at the top of the script for the code examples in this document.

    require 'rubygems'
    require ENV['HYPERTABLE_HOME'] + '/lib/rb/hypertable/thrift_client'
    require 'time'
    include Hypertable::ThriftGen

### Creating a thrift client

All of the examples in this document reference a pointer to a Thrift client object. The following code snippets illustrate how to create a Thrift client object connected to a ThriftBroker listening on the default port (15867) on localhost. A ThriftClient object can be allocated directly, or via the with_thrift_client method of the Hypertable module. To change the ThriftBroker location, just change "localhost" to the domain name of the machine on which the ThriftBroker is running.

    begin
      client = Hypertable::ThriftClient.new("localhost", 15867)
    rescue TException => e
      puts e.message
      exit 1
    end

    # alternatively ...

    Hypertable.with_thrift_client("localhost", 15867) do |client|
      ...
    end

### Basics

The following code snippet illustrates the basics of working with namespaces and tables. The APIs introduced include [namespace_exists](../reference_manual/thrift_api.md#namespaceexists), [namespace_create](../reference_manual/thrift_api.md#namespacecreate), [namespace_open](../reference_manual/thrift_api.md#namespaceopen), [namespace_get_listing](../reference_manual/thrift_api.md#namespacegetlisting), [namespace_close](../reference_manual/thrift_api.md#namespaceclose), [table_drop](../reference_manual/thrift_api.md#tabledrop), and [table_create](../reference_manual/thrift_api.md#tablecreate).

    begin

      if !client.namespace_exists("test")
        client.namespace_create("test")
      end

      ns = client.namespace_open("test")

      if_exists = true
      client.table_drop(ns, "Fruits", if_exists)

      cf_specs = Hash.new

      cf = ColumnFamilySpec.new
      cf.name = "genus"
      cf_specs["genus"] = cf

      cf = ColumnFamilySpec.new
      cf.name = "description"
      cf_specs["description"] = cf

      cf = ColumnFamilySpec.new
      cf.name = "tag"
      cf_specs["tag"] = cf

      schema = Schema.new

      schema.column_families = cf_specs

      client.table_create(ns, "Fruits", schema)

      client.namespace_create("/test/sub")

      listing = client.namespace_get_listing(ns)

      listing.each do |entry|
        if entry.is_namespace
          puts "%s\t(dir)" % entry.name
        else
          puts entry.name
        end
      end

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    Fruits
    sub	(dir)

### Convenience APIs

####  set_cells

The following code snippet illustrates how to create [Cell](../reference_manual/thrift_api.md#cell) objects and insert them with the [set_cells](../reference_manual/thrift_api.md#setcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    begin
      ns = client.namespace_open("test")

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "apple"
      cell.key.column_family = "genus"
      cell.value = "Malus"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "apple"
      cell.key.column_family = "description"
      cell.value = "The apple is the pomaceous fruit of the apple tree."
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "apple"
      cell.key.column_family = "tag"
      cell.key.column_qualifier = "crunchy"
      cells.push(cell)

      client.set_cells(ns, "Fruits", cells)

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

####  get_cells

The following code snippet illustrates how to fetch cells with the [get_cells](../reference_manual/thrift_api.md#getcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new
      ss.columns = Array[ "description" ]

      cells = client.get_cells(ns, "Fruits", ss)

      cells.each { |cell| puts cell }

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=apple column_family=description column_qualifier= flag=255} value=The apple is the pomaceous fruit of the apple tree.}

####  set_cells_as_arrays

The following code snippet illustrates how to create [CellAsArray](../reference_manual/thrift_api.md#cellasarray) objects and insert them with the [set_cells_as_arrays](../reference_manual/thrift_api.md#setcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    begin
      ns = client.namespace_open("test")

      cells_as_arrays = Array.new

      cell_as_array = Array["orange", "genus", "", "Citrus"]
      cells_as_arrays.push(cell_as_array)

      cell_as_array = Array["orange", "description", "", "The orange (specifically," +
                            "the sweet orange) is the fruit of the citrus species" +
                            "Citrus × sinensis in the family Rutaceae.""Citrus"]
      cells_as_arrays.push(cell_as_array)

      cell_as_array = Array["orange", "tag", "juicy", ""]
      cells_as_arrays.push(cell_as_array)

      client.set_cells_as_arrays(ns, "Fruits", cells_as_arrays)

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

####  get_cells_as_arrays

The following code snippet illustrates how to fetch cells with the [get_cells_as_arrays](../reference_manual/thrift_api.md#getcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example and makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](ruby.md#appendix---helper-functions).

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new
      ss.columns = Array[ "description" ]

      cells_as_arrays = client.get_cells_as_arrays(ns, "Fruits", ss)

      cells_as_arrays.each { |cell_as_array| print_cell_as_array(cell_as_array) }

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {CellAsArray key={Key row=apple column_family=description column_qualifier=} value=The apple is the pomaceous fruit of the apple tree.}
    {CellAsArray key={Key row=orange column_family=description column_qualifier=} value=The orange (specifically,the sweet orange) is the fruit of the citrus speciesCitrus × sinensis in the family Rutaceae.Citrus}

### Creating a table

The following code snippet illustrates how to create a table with the [table_create](../reference_manual/thrift_api.md#tablecreate) API. It introduces the API classes [Schema](../reference_manual/thrift_api.md#schema), [AccessGroupSpec](../reference_manual/thrift_api.md#accessgroupspec), [AccessGroupOptions](../reference_manual/thrift_api.md#accessgroupoptions), [ColumnFamilySpec](../reference_manual/thrift_api.md#columnfamilyspec), and [ColumnFamilyOptions](../reference_manual/thrift_api.md#columnfamilyoptions).

    begin
      ns = client.namespace_open("test")

      schema = Schema.new

      schema.access_groups = Hash.new
      schema.column_families = Hash.new

      # Set table defaults
      schema.access_group_defaults = AccessGroupOptions.new
      schema.access_group_defaults.blocksize = 65536
      schema.column_family_defaults = ColumnFamilyOptions.new
      schema.column_family_defaults.max_versions = 1

      # Access group "ag_normal"
      ag_spec = AccessGroupSpec.new
      ag_spec.defaults = ColumnFamilyOptions.new
      ag_spec.defaults.max_versions = 2
      ag_spec.name = "ag_normal"
      schema.access_groups["ag_normal"] = ag_spec

      # Column "a"
      cf_spec = ColumnFamilySpec.new
      cf_spec.name = "a"
      cf_spec.access_group = "ag_normal"
      cf_spec.value_index = true
      cf_spec.qualifier_index = true
      schema.column_families["a"] = cf_spec

      # Column "b"
      cf_spec = ColumnFamilySpec.new
      cf_spec.options = ColumnFamilyOptions.new
      cf_spec.options.max_versions = 3
      cf_spec.name = "b"
      cf_spec.access_group = "ag_normal"
      schema.column_families["b"] = cf_spec

      # Access group "ag_fast"
      ag_spec = AccessGroupSpec.new
      ag_spec.options = AccessGroupOptions.new
      ag_spec.options.in_memory = true
      ag_spec.options.blocksize = 131072
      ag_spec.name = "ag_fast"
      schema.access_groups["ag_fast"] = ag_spec

      # Column "c"
      cf_spec = ColumnFamilySpec.new
      cf_spec.name = "c"
      cf_spec.access_group = "ag_fast"
      schema.column_families["c"] = cf_spec

      # Access group "ag_secure"
      ag_spec = AccessGroupSpec.new
      ag_spec.options = AccessGroupOptions.new
      ag_spec.options.replication = 5
      ag_spec.name = "ag_secure"
      schema.access_groups["ag_secure"] = ag_spec

      # Column "d"
      cf_spec = ColumnFamilySpec.new
      cf_spec.name = "d"
      cf_spec.access_group = "ag_secure"
      schema.column_families["d"] = cf_spec

      # Access group "ag_counter"
      ag_spec = AccessGroupSpec.new
      ag_spec.defaults = ColumnFamilyOptions.new
      ag_spec.defaults.counter = true
      ag_spec.defaults.max_versions = 0
      ag_spec.name = "ag_counter"
      schema.access_groups["ag_counter"] = ag_spec

      # Column "e"
      cf_spec = ColumnFamilySpec.new
      cf_spec.name = "e"
      cf_spec.access_group = "ag_counter"
      schema.column_families["e"] = cf_spec

      # Column "f"
      cf_spec = ColumnFamilySpec.new
      cf_spec.options = ColumnFamilyOptions.new
      cf_spec.options.counter = false
      cf_spec.name = "f"
      cf_spec.access_group = "ag_counter"
      schema.column_families["f"] = cf_spec

      client.table_create(ns, "TestTable", schema)

      result = client.hql_query(ns, "SHOW CREATE TABLE TestTable")

      if (!result.results.empty?)
        puts result.results[0]
      end

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

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

The following code snippet illustrates how to alter a table with the [table_alter](../reference_manual/thrift_api.md#tablealter) API. It assumes that the table _TestTable_ has been created as in the [Creating a table](http://hypertable.com/documentation/developer_guide/c4343/#creating-a-table) example.

    begin
      ns = client.namespace_open("test")

      schema = client.get_schema(ns, "TestTable")

      # Rename column "b" to "z"
      cf_spec = schema.column_families["b"]
      schema.column_families.delete("b")
      cf_spec.name = "z"
      schema.column_families["z"] = cf_spec

      # Add column "g"
      cf_spec = ColumnFamilySpec.new
      cf_spec.name = "g"
      cf_spec.access_group = "ag_counter"
      schema.column_families["g"] = cf_spec

      client.table_alter(ns, "TestTable", schema)

      result = client.hql_query(ns, "SHOW CREATE TABLE TestTable")

      if (!result.results.empty?)
        puts result.results[0]
      end

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

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

    begin
      ns = client.namespace_open("test")

      mutator = client.mutator_open(ns, "Fruits", 0, 0)

      # Auto-assigned timestamps

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "lemon"
      cell.key.column_family = "genus"
      cell.value = "Citrus"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "lemon"
      cell.key.column_family = "tag"
      cell.key.column_qualifier = "bitter"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "lemon"
      cell.key.column_family = "description"
      cell.value = "The lemon (Citrus × limon) is a small evergreen tree native to Asia."
      cells.push(cell)

      client.mutator_set_cells(mutator, cells)
      client.mutator_flush(mutator)

      # Explicitly-supplied timestamps

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "mango"
      cell.key.column_family = "genus"
      cell.key.timestamp = Time.parse("2014-06-06 16:27:15").to_i * 1000000000
      cell.value = "Mangifera"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "mango"
      cell.key.column_family = "tag"
      cell.key.column_qualifier = "sweet"
      cell.key.timestamp = Time.parse("2014-06-06 16:27:15").to_i * 1000000000
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "mango"
      cell.key.column_family = "description"
      cell.key.timestamp = Time.parse("2014-06-06 16:27:15").to_i * 1000000000
      cell.value = "Mango is one of the delicious seasonal fruits grown in the tropics."
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "mango"
      cell.key.column_family = "description"
      cell.key.timestamp = Time.parse("2014-06-06 16:27:16").to_i * 1000000000
      cell.value = "The mango is a juicy stone fruit belonging to the genus " +
        "Mangifera, consisting of numerous tropical fruiting trees, that are" +
        " cultivated mostly for edible fruits."
      cells.push(cell)

      client.mutator_set_cells(mutator, cells)
      client.mutator_flush(mutator)

      # Delete cells

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "apple"
      cell.key.flag = Hypertable::ThriftGen::KeyFlag::DELETE_ROW
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "mango"
      cell.key.column_family = "description"
      cell.key.timestamp = Time.parse("2014-06-06 16:27:15").to_i * 1000000000
      cell.key.flag = Hypertable::ThriftGen::KeyFlag::DELETE_CELL
      cells.push(cell)

      client.mutator_set_cells(mutator, cells)
      client.mutator_flush(mutator)
      client.mutator_close(mutator)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

### Scanner

The following examples illustrate how to query a table using a scanner. The APIs introduced include the [scanner_open](../reference_manual/thrift_api.md#scanneropen), [scanner_get_cells](../reference_manual/thrift_api.md#scannergetcells), and [scanner_close](../reference_manual/thrift_api.md#scannerclose) functions, and the [ScanSpec](../reference_manual/thrift_api.md#scanspec) and [RowInterval](../reference_manual/thrift_api.md#rowinterval) classes.

####  Full table scan

The following code illustrates how to do a full table scan using the scanner APIs.

    begin
      ns = client.namespace_open("test")

      scanner = client.scanner_open(ns, "Fruits", ScanSpec.new)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=lemon column_family=description column_qualifier= flag=255} value=The lemon (Citrus × limon) is a small evergreen tree native to Asia.}
    {Cell key={Key row=lemon column_family=genus column_qualifier= flag=255} value=Citrus}
    {Cell key={Key row=lemon column_family=tag column_qualifier=bitter flag=255} value=}
    {Cell key={Key row=mango column_family=description column_qualifier= flag=255} value=The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.}
    {Cell key={Key row=mango column_family=genus column_qualifier= flag=255} value=Mangifera}
    {Cell key={Key row=mango column_family=tag column_qualifier=sweet flag=255} value=}
    {Cell key={Key row=orange column_family=description column_qualifier= flag=255} value=The orange (specifically,the sweet orange) is the fruit of the citrus speciesCitrus × sinensis in the family Rutaceae.Citrus}
    {Cell key={Key row=orange column_family=genus column_qualifier= flag=255} value=Citrus}
    {Cell key={Key row=orange column_family=tag column_qualifier=juicy flag=255} value=}

####  Restricted scan with ScanSpec

The following code illustrates how to do a table scan using a ScanSpec.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      # Return row range [lemon..orange)
      ri = RowInterval.new
      ri.start_row = "lemon"
      ri.start_inclusive = true
      ri.end_row = "orange"
      ri.end_inclusive = false
      ss.row_intervals = Array[ ri ]

      # Return columns "genus", "tag:bitter", "tag:sweet"
      ss.columns = Array["genus", "tag:bitter", "tag:sweet"]

      # Return only most recent version of each cell
      ss.versions = 1

      scanner = client.scanner_open(ns, "Fruits", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=lemon column_family=genus column_qualifier= flag=255} value=Citrus}
    {Cell key={Key row=lemon column_family=tag column_qualifier=bitter flag=255} value=}
    {Cell key={Key row=mango column_family=genus column_qualifier= flag=255} value=Mangifera}
    {Cell key={Key row=mango column_family=tag column_qualifier=sweet flag=255} value=}

### HQL

####  hql_query

The following code illustrates how to issue HQL commands with the [hql_query](../reference_manual/thrift_api.md#hqlquery) API. It also introduces the [HqlResult](../reference_manual/thrift_api.md#hqlresult) class.

    begin
      ns = client.namespace_open("test")

      result = client.hql_query(ns, "GET LISTING")

      result.results.each { |str| puts str }

      result = client.hql_query(ns, "SELECT * FROM Fruits WHERE ROW = 'mango'")

      result.cells.each { |cell| puts cell }

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    Fruits
    TestTable
    ^TestTable
    ^^TestTable
    sub	(namespace)
    {Cell key={Key row=mango column_family=description column_qualifier= flag=255} value=The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.}
    {Cell key={Key row=mango column_family=genus column_qualifier= flag=255} value=Mangifera}
    {Cell key={Key row=mango column_family=tag column_qualifier=sweet flag=255} value=}

####  hql_query_as_arrays

The following code illustrates how to issue an HQL query with the [hql_query_as_arrays](../reference_manual/thrift_api.md#hqlqueryasarrays) API. It introduces the [HqlResultAsArrays](../reference_manual/thrift_api.md#hqlresultasarrays) class and makes use of the function _print_cell_as_array_ defined in [Appendix - helper functions](ruby.md#appendix---helper-functions).

    begin
      ns = client.namespace_open("test")

      result_as_arrays =
        client.hql_query_as_arrays(ns, "SELECT * FROM Fruits WHERE ROW = 'lemon'")

      result_as_arrays.cells.each { |cell_as_array| print_cell_as_array(cell_as_array) }

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {CellAsArray key={Key row=lemon column_family=description column_qualifier=} value=The lemon (Citrus × limon) is a small evergreen tree native to Asia.}
    {CellAsArray key={Key row=lemon column_family=genus column_qualifier=} value=Citrus}
    {CellAsArray key={Key row=lemon column_family=tag column_qualifier=bitter} value=}

####  hql_exec (mutator)

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a mutator.

    begin
      ns = client.namespace_open("test")

      result = client.hql_exec(ns, "INSERT INTO Fruits VALUES ('strawberry', " +
                               "'genus', 'Fragaria'), ('strawberry', 'tag:fibrous', '')," +
                               " ('strawberry', 'description', 'The garden strawberry is" +
                               " a widely grown hybrid species of the genus Fragaria')",
                               true, false)

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "pineapple"
      cell.key.column_family = "genus"
      cell.value = "Ananas"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "pineapple"
      cell.key.column_family = "tag"
      cell.key.column_qualifier = "acidic"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "pineapple"
      cell.key.column_family = "description"
      cell.value = "The pineapple (Ananas comosus) is a tropical plant with " +
        "edible multiple fruit consisting of coalesced berries."
      cells.push(cell)

      client.mutator_set_cells(result.mutator, cells)
      client.mutator_flush(result.mutator)
      client.mutator_close(result.mutator)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

####  hql_exec (scanner}

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a scanner.

    begin
      ns = client.namespace_open("test")

      result = client.hql_exec(ns, "SELECT * FROM Fruits", false, true)

      cells = client.scanner_get_cells(result.scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(result.scanner)
      end

      client.scanner_close(result.scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=lemon column_family=description column_qualifier= flag=255} value=The lemon (Citrus × limon) is a small evergreen tree native to Asia.}
    {Cell key={Key row=lemon column_family=genus column_qualifier= flag=255} value=Citrus}
    {Cell key={Key row=lemon column_family=tag column_qualifier=bitter flag=255} value=}
    {Cell key={Key row=mango column_family=description column_qualifier= flag=255} value=The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.}
    {Cell key={Key row=mango column_family=genus column_qualifier= flag=255} value=Mangifera}
    {Cell key={Key row=mango column_family=tag column_qualifier=sweet flag=255} value=}
    {Cell key={Key row=orange column_family=description column_qualifier= flag=255} value=The orange (specifically,the sweet orange) is the fruit of the citrus speciesCitrus × sinensis in the family Rutaceae.Citrus}
    {Cell key={Key row=orange column_family=genus column_qualifier= flag=255} value=Citrus}
    {Cell key={Key row=orange column_family=tag column_qualifier=juicy flag=255} value=}
    {Cell key={Key row=pineapple column_family=description column_qualifier= flag=255} value=The pineapple (Ananas comosus) is a tropical plant with edible multiple fruit consisting of coalesced berries.}
    {Cell key={Key row=pineapple column_family=genus column_qualifier= flag=255} value=Ananas}
    {Cell key={Key row=pineapple column_family=tag column_qualifier=acidic flag=255} value=}
    {Cell key={Key row=strawberry column_family=description column_qualifier= flag=255} value=The garden strawberry is a widely grown hybrid species of the genus Fragaria}
    {Cell key={Key row=strawberry column_family=genus column_qualifier= flag=255} value=Fragaria}
    {Cell key={Key row=strawberry column_family=tag column_qualifier=fibrous flag=255} value=}

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

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      column_predicate = ColumnPredicate.new

      column_predicate.column_family = "section"
      column_predicate.operation = ColumnPredicateOperation::EXACT_MATCH
      column_predicate.value = "books"
      ss.column_predicates = Array[ column_predicate ]

      ss.columns = Array[ "title" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=0307743659 column_family=title column_qualifier= flag=255} value=The Shining Mass Market Paperback}
    {Cell key={Key row=0321321928 column_family=title column_qualifier= flag=255} value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]}
    {Cell key={Key row=0321776402 column_family=title column_qualifier= flag=255} value=C++ Primer Plus (6th Edition) (Developer's Library)}

####  Value index (exact match with qualifier)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title FROM products WHERE info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      column_predicate = ColumnPredicate.new

      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "actor"
      column_predicate.operation = ColumnPredicateOperation::EXACT_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "Jack Nicholson"
      ss.column_predicates = Array[ column_predicate ]

      ss.columns = Array[ "title" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=B00002VWE0 column_family=title column_qualifier= flag=255} value=Five Easy Pieces (1970)}
    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier= flag=255} value=The Shining (1980)}

####  Value index (prefix match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =^ 'Addison-Wesley';

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      column_predicate = ColumnPredicate.new

      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "publisher"
      column_predicate.operation = ColumnPredicateOperation::PREFIX_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "Addison-Wesley"
      ss.column_predicates = Array[ column_predicate ]

      ss.columns = Array[ "title", "info:publisher" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=0321321928 column_family=title column_qualifier= flag=255} value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]}
    {Cell key={Key row=0321321928 column_family=info column_qualifier=publisher flag=255} value=Addison-Wesley Professional; 1 edition (March 10, 2005)}
    {Cell key={Key row=0321776402 column_family=title column_qualifier= flag=255} value=C++ Primer Plus (6th Edition) (Developer's Library)}
    {Cell key={Key row=0321776402 column_family=info column_qualifier=publisher flag=255} value=Addison-Wesley Professional; 6 edition (October 28, 2011)}

####  Value index (regex match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =~ /^Addison-Wesley/;

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      column_predicate = ColumnPredicate.new

      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "publisher"
      column_predicate.operation = ColumnPredicateOperation::REGEX_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "^Addison-Wesley"
      ss.column_predicates = Array[ column_predicate ]

      ss.columns = Array[ "title", "info:publisher" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=0321321928 column_family=title column_qualifier= flag=255} value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]}
    {Cell key={Key row=0321321928 column_family=info column_qualifier=publisher flag=255} value=Addison-Wesley Professional; 1 edition (March 10, 2005)}
    {Cell key={Key row=0321776402 column_family=title column_qualifier= flag=255} value=C++ Primer Plus (6th Edition) (Developer's Library)}
    {Cell key={Key row=0321776402 column_family=info column_qualifier=publisher flag=255} value=Addison-Wesley Professional; 6 edition (October 28, 2011)}

####  Qualifier index (exists)

The following HQL query which leverages the qualifier index of the _info_ column:

    SELECT title FROM products WHERE Exists(info:studio);

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      column_predicate = ColumnPredicate.new

      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "studio"
      column_predicate.operation = ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      ss.column_predicates = Array[ column_predicate ]

      ss.columns = Array[ "title" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=B00002VWE0 column_family=title column_qualifier= flag=255} value=Five Easy Pieces (1970)}
    {Cell key={Key row=B000Q66J1M column_family=title column_qualifier= flag=255} value=2001: A Space Odyssey [Blu-ray]}
    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier= flag=255} value=The Shining (1980)}

####  Qualifier index (exists regex prefix match)

The following HQL query which leverages the qualifier index of the _category_ column:

    SELECT title FROM products WHERE Exists(category:/^\/Movies/);

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      column_predicate = ColumnPredicate.new

      column_predicate.column_family = "category"
      column_predicate.column_qualifier = "^/Movies"
      column_predicate.operation = ColumnPredicateOperation::QUALIFIER_REGEX_MATCH
      ss.column_predicates = Array[ column_predicate ]

      ss.columns = Array[ "title" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=B00002VWE0 column_family=title column_qualifier= flag=255} value=Five Easy Pieces (1970)}
    {Cell key={Key row=B000Q66J1M column_family=title column_qualifier= flag=255} value=2001: A Space Odyssey [Blu-ray]}
    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier= flag=255} value=The Shining (1980)}

####  Value index (OR query)

The following HQL query performs a boolean _OR_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen P/ OR info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new
      ss.column_predicates = Array.new

      column_predicate = ColumnPredicate.new
      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "author"
      column_predicate.operation = ColumnPredicateOperation::REGEX_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "^Stephen P"
      ss.column_predicates.push(column_predicate)

      column_predicate = ColumnPredicate.new
      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "publisher"
      column_predicate.operation = ColumnPredicateOperation::PREFIX_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "Anchor"
      ss.column_predicates.push(column_predicate)

      ss.columns = Array[ "title" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=0307743659 column_family=title column_qualifier= flag=255} value=The Shining Mass Market Paperback}
    {Cell key={Key row=0321776402 column_family=title column_qualifier= flag=255} value=C++ Primer Plus (6th Edition) (Developer's Library)}

####  Value index (AND query)

The following HQL query performs a boolean _AND_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new
      ss.column_predicates = Array.new

      column_predicate = ColumnPredicate.new
      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "author"
      column_predicate.operation = ColumnPredicateOperation::REGEX_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "^Stephen [PK]"
      ss.column_predicates.push(column_predicate)

      column_predicate = ColumnPredicate.new
      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "publisher"
      column_predicate.operation = ColumnPredicateOperation::PREFIX_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "Anchor"
      ss.column_predicates.push(column_predicate)

      ss.and_column_predicates = true

      ss.columns = Array[ "title" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=0307743659 column_family=title column_qualifier= flag=255} value=The Shining Mass Market Paperback}

####  Value index (AND row interval)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW interval:

    SELECT title
      FROM products
      WHERE ROW > 'B00002VWE0' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      # ROW > 'B00002VWE0'
      ri = RowInterval.new
      ri.start_row = "B00002VWE0"
      ri.start_inclusive = false
      ss.row_intervals = Array[ ri ]

      # info:actor = 'Jack Nicholson'
      column_predicate = ColumnPredicate.new
      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "actor"
      column_predicate.operation = ColumnPredicateOperation::EXACT_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "Jack Nicholson"
      ss.column_predicates = Array[ column_predicate ]

      ss.and_column_predicates = true

      ss.columns = Array[ "title" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier= flag=255} value=The Shining (1980)}

####  Value index (AND row prefix)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW prefix interval:

    SELECT title
      FROM products
      WHERE ROW =^ 'B' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    begin
      ns = client.namespace_open("test")

      ss = ScanSpec.new

      # ROW =^ 'B'
      ri = RowInterval.new
      ri.start_row = "B"
      ri.start_inclusive = true
      ri.end_row = "C"
      ri.end_inclusive = false
      ss.row_intervals = Array[ ri ]

      # info:actor = 'Jack Nicholson'
      column_predicate = ColumnPredicate.new
      column_predicate.column_family = "info"
      column_predicate.column_qualifier = "actor"
      column_predicate.operation = ColumnPredicateOperation::EXACT_MATCH |
        ColumnPredicateOperation::QUALIFIER_EXACT_MATCH
      column_predicate.value = "Jack Nicholson"
      ss.column_predicates = Array[ column_predicate ]

      ss.and_column_predicates = true

      ss.columns = Array[ "title" ]

      scanner = client.scanner_open(ns, "products", ss)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=B00002VWE0 column_family=title column_qualifier= flag=255} value=Five Easy Pieces (1970)}
    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier= flag=255} value=The Shining (1980)}

### Asynchronous APIs

This section describes how to use the asynchronous APIs. The examples assume that tables _Profile_ and _Session_ are created and loaded with the following HQL commands.

    CREATE TABLE Profile (info, last_access MAX_VERSIONS 1);

    CREATE TABLE Session (user_id, page_hit);

    INSERT INTO Profile
      VALUES ('1', 'info:name', 'Joe'), ('2', 'info:name', 'Sue');

####  Async mutator

The code snippet below illustrates how to insert cells into multiple tables simultaneously using an asynchronous mutator. The APIs introduced include the [future_open](../reference_manual/thrift_api.md#futureopen), [future_get_result](../reference_manual/thrift_api.md#futuregetresult), [future_close](../reference_manual/thrift_api.md#futureclose), [async_mutator_open](../reference_manual/thrift_api.md#asyncmutatoropen), [async_mutator_set_cells](../reference_manual/thrift_api.md#asyncmutatorsetcells), [async_mutator_flush](../reference_manual/thrift_api.md#asyncmutatorflush), and [async_mutator_close](../reference_manual/thrift_api.md#asyncmutatorclose) functions and the [Result](../reference_manual/thrift_api.md#result) class.

    begin
      ns = client.namespace_open("test")
      ff = client.future_open(0)
      profile_mutator = client.async_mutator_open(ns, "Profile", ff, 0)
      session_mutator = client.async_mutator_open(ns, "Session", ff, 0)

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "1"
      cell.key.column_family = "last_access"
      cell.value = "2014-06-13 16:06:09"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "2"
      cell.key.column_family = "last_access"
      cell.value = "2014-06-13 16:06:10"
      cells.push(cell)

      client.async_mutator_set_cells(profile_mutator, cells)

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "0001-200238"
      cell.key.column_family = "user_id"
      cell.key.column_qualifier = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "0001-200238"
      cell.key.column_family = "page_hit"
      cell.value = "/index.html"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "0002-383049"
      cell.key.column_family = "user_id"
      cell.key.column_qualifier = "2"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "0002-383049"
      cell.key.column_family = "page_hit"
      cell.value = "/foo/bar.html"
      cells.push(cell)
      client.async_mutator_set_cells(session_mutator, cells)

      client.async_mutator_flush(profile_mutator)
      client.async_mutator_flush(session_mutator)

      result_count = 0
      while true do
        result = client.future_get_result(ff, 0)
        if result.is_empty
          break
        end
        result_count += 1
        if result.is_error
          puts "Async mutator error:  " + result.error_msg
          exit 1
        end
        if result.id == profile_mutator
          puts "Result is from Profile mutation"
        elsif result.id == session_mutator
          puts "Result is from Session mutation"
        end
      end

      puts "result count = %d" % result_count

      client.async_mutator_close(profile_mutator)
      client.async_mutator_close(session_mutator)
      client.future_close(ff)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    Result is from Profile mutation
    Result is from Session mutation
    result count = 2

####  Async scanner (Result)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [Result](../reference_manual/thrift_api.md#result) object. The APIs introduced include the [async_scanner_open](../reference_manual/thrift_api.md#asyncscanneropen) and [async_scanner_close](../reference_manual/thrift_api.md#asyncscannerclose) functions.

    begin
      ns = client.namespace_open("test")
      ff = client.future_open(0)

      ss = ScanSpec.new
      ri = RowInterval.new
      ri.start_row = "1"
      ri.start_inclusive = true
      ri.end_row = "1"
      ri.end_inclusive = true
      ss.row_intervals = Array[ ri ]
      profile_scanner = client.async_scanner_open(ns, "Profile", ff, ss)

      ss = ScanSpec.new
      ri = RowInterval.new
      ri.start_row = "0001-200238"
      ri.start_inclusive = true
      ri.end_row = "0001-200238"
      ri.end_inclusive = true
      ss.row_intervals = Array[ ri ]
      session_scanner = client.async_scanner_open(ns, "Session", ff, ss)

      while true do
        result = client.future_get_result(ff, 0)
        if result.is_empty
          break
        end
        if result.is_error
          puts "Async mutator error:  " + result.error_msg
          exit 1
        end
        if result.id == profile_scanner
          puts "Result is from Profile scan"
        elsif result.id == session_scanner
          puts "Result is from Session scan"
        end
        result.cells.each { |cell| puts cell }
      end

      client.async_scanner_close(profile_scanner)
      client.async_scanner_close(session_scanner)
      client.future_close(ff)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    Result is from Profile scan
    {Cell key={Key row=1 column_family=info column_qualifier=name flag=255} value=Joe}
    {Cell key={Key row=1 column_family=last_access column_qualifier= flag=255} value=2014-06-13 16:06:09}
    Result is from Session scan
    {Cell key={Key row=0001-200238 column_family=user_id column_qualifier=1 flag=255} value=}
    {Cell key={Key row=0001-200238 column_family=page_hit column_qualifier= flag=255} value=/index.html}

####  Async scanner (ResultAsArrays)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultAsArrays](../reference_manual/thrift_api.md#resultasarrays) object. This example introduces the [future_get_result_as_arrays](../reference_manual/thrift_api.md#futuregetresultasarrays) API and makes use of the function _print_cell_as_array_ defined in [Appendix - helper functions](ruby.md#appendix---helper-functions).

    begin
      ns = client.namespace_open("test")
      ff = client.future_open(0)

      ss = ScanSpec.new
      ri = RowInterval.new
      ri.start_row = "1"
      ri.start_inclusive = true
      ri.end_row = "1"
      ri.end_inclusive = true
      ss.row_intervals = Array[ ri ]
      profile_scanner = client.async_scanner_open(ns, "Profile", ff, ss)

      ss = ScanSpec.new
      ri = RowInterval.new
      ri.start_row = "0001-200238"
      ri.start_inclusive = true
      ri.end_row = "0001-200238"
      ri.end_inclusive = true
      ss.row_intervals = Array[ ri ]
      session_scanner = client.async_scanner_open(ns, "Session", ff, ss)

      while true do
        result_as_arrays = client.future_get_result_as_arrays(ff, 0)
        if result_as_arrays.is_empty
          break
        end
        if result_as_arrays.is_error
          puts "Async mutator error:  " + result_as_arrays.error_msg
          exit 1
        end
        if result_as_arrays.id == profile_scanner
          puts "Result is from Profile scan"
        elsif result_as_arrays.id == session_scanner
          puts "Result is from Session scan"
        end
        result_as_arrays.cells.each { |cell_as_array| print_cell_as_array(cell_as_array) }
      end

      client.async_scanner_close(profile_scanner)
      client.async_scanner_close(session_scanner)
      client.future_close(ff)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    Result is from Profile scan
    {CellAsArray key={Key row=1 column_family=info column_qualifier=name} value=Joe}
    {CellAsArray key={Key row=1 column_family=last_access column_qualifier=} value=2014-06-13 16:06:09}
    Result is from Session scan
    {CellAsArray key={Key row=0001-200238 column_family=user_id column_qualifier=1} value=}
    {CellAsArray key={Key row=0001-200238 column_family=page_hit column_qualifier=} value=/index.html}

### Atomic counters

This section describes how to use atomic counters. The examples assume that a  _Hits_ table has been created with the following HQL command.

    CREATE TABLE Hits (count COUNTER);

####  Increment

The code snippet below illustrates how to increment per-second hit counts for pages of a website.

    begin
      ns = client.namespace_open("test")

      mutator = client.mutator_open(ns, "Hits", 0, 0)

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:18"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:18"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/foo/bar.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:18"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/foo/bar.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:18"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/foo/bar.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:18"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:19"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:19"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:19"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:19"
      cell.value = "1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/foo/bar.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:19"
      cell.value = "1"
      cells.push(cell)

      client.mutator_set_cells(mutator, cells)
      client.mutator_flush(mutator)

      scanner = client.scanner_open(ns, "Hits", ScanSpec.new)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.mutator_close(mutator)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=/foo/bar.html column_family=count column_qualifier=2014-06-14 07:31:18 flag=255} value=3}
    {Cell key={Key row=/foo/bar.html column_family=count column_qualifier=2014-06-14 07:31:19 flag=255} value=1}
    {Cell key={Key row=/index.html column_family=count column_qualifier=2014-06-14 07:31:18 flag=255} value=2}
    {Cell key={Key row=/index.html column_family=count column_qualifier=2014-06-14 07:31:19 flag=255} value=4}

####  Reset and subtraction

The code snippet below illustrates how to reset and subtract from counters.

    begin
      ns = client.namespace_open("test")

      mutator = client.mutator_open(ns, "Hits", 0, 0)

      cells = Array.new

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:18"
      cell.value = "=0"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:18"
      cell.value = "7"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/foo/bar.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:18"
      cell.value = "-1"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/index.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:19"
      cell.value = "-2"
      cells.push(cell)

      cell = Cell.new
      cell.key = Key.new
      cell.key.row = "/foo/bar.html"
      cell.key.column_family = "count"
      cell.key.column_qualifier = "2014-06-14 07:31:19"
      cell.value = "=19"
      cells.push(cell)

      client.mutator_set_cells(mutator, cells)
      client.mutator_flush(mutator)

      scanner = client.scanner_open(ns, "Hits", ScanSpec.new)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.mutator_close(mutator)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    {Cell key={Key row=/foo/bar.html column_family=count column_qualifier=2014-06-14 07:31:18 flag=255} value=2}
    {Cell key={Key row=/foo/bar.html column_family=count column_qualifier=2014-06-14 07:31:19 flag=255} value=19}
    {Cell key={Key row=/index.html column_family=count column_qualifier=2014-06-14 07:31:18 flag=255} value=7}
    {Cell key={Key row=/index.html column_family=count column_qualifier=2014-06-14 07:31:19 flag=255} value=2}

### Creating unique keys

This section illustrates how to create unique keys using the [create_cell_unique](../reference_manual/thrift_api.md#createcellunique) API. The example show how you can create unique user IDs for an application. The code assumes that a _User_ table has been created with the following HQL command.

    CREATE TABLE User (info, id TIME_ORDER desc MAX_VERSIONS 1);

The example code snippet is as follows.

    begin
      ns = client.namespace_open("test")

      key = Key.new
      key.column_family = "id"
      key.row = "joe1987"
      client.create_cell_unique(ns, "User", key, "")

      key = Key.new
      key.column_family = "id"
      key.row = "mary.bellweather"
      client.create_cell_unique(ns, "User", key, "")

      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

    begin
      ns = client.namespace_open("test")

      key = Key.new
      key.column_family = "id"
      key.row = "joe1987"
      client.create_cell_unique(ns, "User", key, "")

      client.namespace_close(ns)

    rescue ClientException => e
      if e.code == 48
        puts "User name '%s' is already taken" % key.row
        client.namespace_close(ns)
      else
        puts "exception caught on line %d: %s" % [__LINE__, e.message]
        exit 1
      end
    end

    begin
      ns = client.namespace_open("test")

      scanner = client.scanner_open(ns, "User", ScanSpec.new)

      cells = client.scanner_get_cells(scanner)
      while !cells.empty? do
        cells.each { |cell| puts cell }
        cells = client.scanner_get_cells(scanner)
      end

      client.scanner_close(scanner)
      client.namespace_close(ns)

    rescue ClientException => e
      puts "exception caught on line %d: %s" % [__LINE__, e.message]
      exit 1
    end

The following is example output produced by the above code snippet.

    User name 'joe1987' is already taken
    {Cell key={Key row=joe1987 column_family=id column_qualifier= flag=255} value=4156ed74-2abd-4b35-bada-cf3f35553622}
    {Cell key={Key row=mary.bellweather column_family=id column_qualifier= flag=255} value=eb61bdeb-9890-4928-bb1a-dee43b1d1bd6}

### Appendix - helper functions

The following helper function is used in the examples in this document.

    def print_cell_as_array(cell_as_array)
      puts "{CellAsArray key={Key row=%s column_family=%s column_qualifier=%s} value=%s}" %
        [cell_as_array[0], cell_as_array[1], cell_as_array[2], cell_as_array[3]]
    end
