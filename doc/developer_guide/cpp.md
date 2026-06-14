# C++

## Table of Contents

### Introduction

This document presents example C++ code that excercises the Thrift API. To quickly get Hypertable up and running on a single machine so that you can try out these examples, see [Hypertable Standalone Installation](../installation/quick_start_standalone.md). The source code for all of the examples in this document, along with the build and run scripts, can be found in [hypertable_api_example.tgz](http://hypertable.com/pub/hypertable_api_example.tgz).

### Makefile

In order to build a C++ program that uses the Hypertable Thrift interface, you need to tell the compiler what libraries and header files to use and where to find them. The following Makefile illustrates how to do this.

    HT_HOME=/opt/hypertable/current
    LIBSIGAR=-lsigar-amd64-linux
    CC=g++
    CFLAGS=-c -g -Wall -D_REENTRANT -std=c++11 -I$(HT_HOME)/include \
           -I$(HT_HOME)/include/thrift
    LDFLAGS=-g -rdynamic -L$(HT_HOME)/lib -lHyperThrift -lHyperCommon -lHypertable \
    	-lthrift -levent -lboost_system -lboost_program_options \
    	-lboost_filesystem $(LIBSIGAR) -lre2 -lcurses -ltcmalloc_minimal

    all: hypertable_api_test

    hypertable_api_test: hypertable_api_test.o
    	$(CC) hypertable_api_test.o $(LDFLAGS) -o hypertable_api_test

    hypertable_api_test.o: hypertable_api_test.cc
    	$(CC) $(CFLAGS) hypertable_api_test.cc

    clean:
    	rm -rf *.o hypertable_api_test

### Program boilerplate

The following header includes and using directives are required for the code examples in this document.

    #include <Common/Compat.h>
    #include <Common/Logger.h>
    #include <Common/System.h>

    #include <Hypertable/Lib/Key.h>
    #include <Hypertable/Lib/KeySpec.h>

    #include <ThriftBroker/Client.h>
    #include <ThriftBroker/gen-cpp/Client_types.h>
    #include <ThriftBroker/gen-cpp/HqlService.h>
    #include <ThriftBroker/ThriftHelper.h>
    #include <ThriftBroker/SerializedCellsReader.h>
    #include <ThriftBroker/SerializedCellsWriter.h>

    #include <cstdlib>
    #include <iostream>
    #include <fstream>

    using namespace Hypertable;
    using namespace Hypertable::ThriftGen;
    using namespace std;

### Creating a thrift client

All of the examples in this document reference a pointer to a Thrift client object. The following code snippet illustrates how to create a Thrift client object connected to a ThriftBroker listening on the default port (15867) on localhost. To change the ThriftBroker location, just change localhost to the domain name of the machine on which the ThriftBroker is running.

    Thrift::Client *client = nullptr;

    try {
      client = new Thrift::Client("localhost", 15867);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

### Basics

The following code snippet illustrates the basics of working with namespaces and tables. The APIs introduced include [namespace_exists](../reference_manual/thrift_api.md#namespaceexists), [namespace_create](../reference_manual/thrift_api.md#namespacecreate), [namespace_open](../reference_manual/thrift_api.md#namespaceopen), [namespace_get_listing](../reference_manual/thrift_api.md#namespacegetlisting), [namespace_close](../reference_manual/thrift_api.md#namespaceclose), [table_drop](../reference_manual/thrift_api.md#tabledrop), and [table_create](../reference_manual/thrift_api.md#tablecreate).

    try {

      if (!client->namespace_exists("test"))
        client->namespace_create("test");

      ThriftGen::Namespace ns = client->namespace_open("test");

      bool if_exists = true;
      client->table_drop(ns, "Fruits", if_exists);

      ThriftGen::Schema schema;
      map<string, ThriftGen::ColumnFamilySpec> cf_specs;
      ThriftGen::ColumnFamilySpec cf;

      cf.__set_name("genus");
      cf_specs["genus"] = cf;
      cf.__set_name("description");
      cf_specs["description"] = cf;
      cf.__set_name("tag");
      cf_specs["tag"] = cf;
      schema.__set_column_families(cf_specs);

      client->table_create(ns, "Fruits", schema);

      client->namespace_create("/test/sub");

      vector<ThriftGen::NamespaceListing> listing;

      client->namespace_get_listing(listing, ns);

      for (auto entry : listing)
        cout << entry.name << (entry.is_namespace ? "\t(dir)" : "") << endl;

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Fruits
    sub	(dir)

### Convenience APIs

####  set_cells

The following code snippet illustrates how to create [Cell](../reference_manual/thrift_api.md#cell) objects and insert them with the [set_cells](../reference_manual/thrift_api.md#setcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](cpp.md#basics) example.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      vector<ThriftGen::Cell> cells;
      ThriftGen::Cell cell;

      cell.key.__set_timestamp(AUTO_ASSIGN);
      cell.key.__set_flag(ThriftGen::KeyFlag::INSERT);

      cell.key.__set_row("apple");
      cell.key.__set_column_family("genus");
      cell.__set_value("Malus");
      cells.push_back(cell);

      cell.key.__set_row("apple");
      cell.key.__set_column_family("description");
      cell.__set_value("The apple is the pomaceous fruit of the apple tree.");
      cells.push_back(cell);

      cell.key.__set_row("apple");
      cell.key.__set_column_family("tag");
      cell.key.__set_column_qualifier("crunchy");
      cells.push_back(cell);

      client->set_cells(ns, "Fruits", cells);

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

####  get_cells

The following code snippet illustrates how to fetch cells with the [get_cells](../reference_manual/thrift_api.md#getcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](cpp.md#basics) example.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;
      vector<ThriftGen::Cell> cells;
      vector<string> columns;

      columns.push_back("description");
      ss.__set_columns(columns);

      client->get_cells(cells, ns, "Fruits", ss);

      for (auto & cell : cells)
        cout << cell << endl;

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=apple, column_family=description, column_qualifier=, timestamp=1424041587327874002, revision=1424041587327874002, flag=255), value=The apple
     is the pomaceous fruit of the apple tree.)

####  set_cells_as_arrays

The following code snippet illustrates how to create [CellAsArray](../reference_manual/thrift_api.md#cellasarray) objects and insert them with the [set_cells_as_arrays](../reference_manual/thrift_api.md#setcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](cpp.md#basics) example.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      vector<CellAsArray> cells_as_arrays;
      CellAsArray cell_as_array;

      cell_as_array.clear();
      cell_as_array.push_back("orange");
      cell_as_array.push_back("genus");
      cell_as_array.push_back("");
      cell_as_array.push_back("Citrus");
      cells_as_arrays.push_back(cell_as_array);

      cell_as_array.clear();
      cell_as_array.push_back("orange");
      cell_as_array.push_back("description");
      cell_as_array.push_back("");
      cell_as_array.push_back("The orange (specifically, the sweet orange) is the"
                              " fruit of the citrus species Citrus × sinensis in "
                              "the family Rutaceae.");
      cells_as_arrays.push_back(cell_as_array);

      cell_as_array.clear();
      cell_as_array.push_back("orange");
      cell_as_array.push_back("tag");
      cell_as_array.push_back("juicy");
      cells_as_arrays.push_back(cell_as_array);

      client->set_cells_as_arrays(ns, "Fruits", cells_as_arrays);

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

####  get_cells_as_arrays

The following code snippet illustrates how to fetch cells with the [get_cells_as_arrays](../reference_manual/thrift_api.md#getcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](cpp.md#basics) example and makes use of the _convert_cell_as_array_ function defined in [Appendix - helper functions](cpp.md#appendix---helper-functions).

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;
      vector<CellAsArray> cells_as_arrays;
      vector<string> columns;

      columns.push_back("description");
      ss.__set_columns(columns);

      client->get_cells_as_arrays(cells_as_arrays, ns, "Fruits", ss);

      for (auto & cell_as_array : cells_as_arrays)
        cout << convert_cell_as_array(cell_as_array) << endl;

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=apple, column_family=description, column_qualifier=, timestamp=1424041587327874002, revision=<null>, flag=255), value=The apple is the pomac
    eous fruit of the apple tree.)
    Cell(key=Key(row=orange, column_family=description, column_qualifier=, timestamp=1424041587398215002, revision=<null>, flag=255), value=The orange (specifica
    lly, the sweet orange) is the fruit of the citrus species Citrus × sinensis in the family Rutaceae.)

####  set_cells_serialized

The following code snippet illustrates how to insert cells with the [set_cells_serialized](../reference_manual/thrift_api.md#setcellsserialized) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](cpp.md#basics) example.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      SerializedCellsWriter writer(1024);
      ThriftGen::CellsSerialized cells;

      writer.add("canteloupe", "genus", "", AUTO_ASSIGN, "Cucumis", 7, FLAG_INSERT);

      writer.add("canteloupe", "description", "", AUTO_ASSIGN,
                 "Canteloupe refers to a variety of Cucumis melo, a species in "
                 "the family Cucurbitaceae.", 86, FLAG_INSERT);

      writer.add("canteloupe", "tag", "juicy", AUTO_ASSIGN, "", 0, FLAG_INSERT);

      writer.finalize(0);

      cells.append((const char *)writer.get_buffer(), writer.get_buffer_length());

      client->set_cells_serialized(ns, "Fruits", cells);

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

####  get_cells_serialized

The following code snippet illustrates how to fetch cells with the [get_cells_serialized](../reference_manual/thrift_api.md#getcellsserialized) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](cpp.md#basics) example and makes use of the _convert_cell_ function defined in [Appendix - helper functions](cpp.md#appendix---helper-functions).

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;
      ThriftGen::CellsSerialized cells;
      vector<string> columns;

      columns.push_back("description");
      ss.__set_columns(columns);

      client->get_cells_serialized(cells, ns, "Fruits", ss);

      SerializedCellsReader reader(cells.data(), cells.size());

      Hypertable::Cell hcell;
      while (reader.next()) {
        reader.get(hcell);
        cout << convert_cell(hcell) << endl;
      }

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=apple, column_family=description, column_qualifier=, timestamp=1424041587327874002, revision=-9223372036854775806, flag=255), value=The appl
    e is the pomaceous fruit of the apple tree.)
    Cell(key=Key(row=canteloupe, column_family=description, column_qualifier=, timestamp=1424041587429147002, revision=-9223372036854775806, flag=255), value=Can
    teloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.)
    Cell(key=Key(row=orange, column_family=description, column_qualifier=, timestamp=1424041587398215002, revision=-9223372036854775806, flag=255), value=The ora
    nge (specifically, the sweet orange) is the fruit of the citrus species Citrus × sinensis in the family Rutaceae.)

### Creating a table

The following code snippet illustrates how to create a table with the [table_create](../reference_manual/thrift_api.md#tablecreate) API. It introduces the API classes [Schema](../reference_manual/thrift_api.md#schema), [AccessGroupSpec](../reference_manual/thrift_api.md#accessgroupspec), [AccessGroupOptions](../reference_manual/thrift_api.md#accessgroupoptions), [ColumnFamilySpec](../reference_manual/thrift_api.md#columnfamilyspec), and [ColumnFamilyOptions](../reference_manual/thrift_api.md#columnfamilyoptions).

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::Schema schema;

      map<string, ThriftGen::AccessGroupSpec> ag_specs;
      map<string, ThriftGen::ColumnFamilySpec> cf_specs;

      // Set table defaults
      {
        ThriftGen::AccessGroupOptions ag_options;
        ThriftGen::ColumnFamilyOptions cf_options;
        ag_options.__set_blocksize(65536);
        schema.__set_access_group_defaults(ag_options);
        cf_options.__set_max_versions(1);
        schema.__set_column_family_defaults(cf_options);
      }

      // Access group "ag_normal"
      {
        ThriftGen::AccessGroupSpec ag;
        ThriftGen::ColumnFamilyOptions cf_options;
        cf_options.__set_max_versions(2);
        ag.__set_name("ag_normal");
        ag.__set_defaults(cf_options);
        ag_specs["ag_normal"] = ag;
      }

      // Column "a"
      {
        ThriftGen::ColumnFamilySpec cf;
        cf.__set_name("a");
        cf.__set_access_group("ag_normal");
        cf.__set_value_index(true);
        cf.__set_qualifier_index(true);
        cf_specs["a"] = cf;
      }

      // Column "b"
      {
        ThriftGen::ColumnFamilySpec cf;
        ThriftGen::ColumnFamilyOptions cf_options;
        cf.__set_name("b");
        cf.__set_access_group("ag_normal");
        cf_options.__set_max_versions(3);
        cf.__set_options(cf_options);
        cf_specs["b"] = cf;
      }

      // Access group "ag_fast"
      {
        ThriftGen::AccessGroupSpec ag;
        ThriftGen::AccessGroupOptions ag_options;
        ag.__set_name("ag_fast");
        ag_options.__set_in_memory(true);
        ag_options.__set_blocksize(131072);
        ag.__set_options(ag_options);
        ag_specs["ag_fast"] = ag;
      }

      // Column "c"
      {
        ThriftGen::ColumnFamilySpec cf;
        cf.__set_name("c");
        cf.__set_access_group("ag_fast");
        cf_specs["c"] = cf;
      }

      // Access group "ag_secure"
      {
        ThriftGen::AccessGroupSpec ag;
        ThriftGen::AccessGroupOptions ag_options;
        ag.__set_name("ag_secure");
        ag_options.__set_replication(5);
        ag.__set_options(ag_options);
        ag_specs["ag_secure"] = ag;
      }

      // Column "d"
      {
        ThriftGen::ColumnFamilySpec cf;
        cf.__set_name("d");
        cf.__set_access_group("ag_secure");
        cf_specs["d"] = cf;
      }

      // Access group "ag_counter"
      {
        ThriftGen::AccessGroupSpec ag;
        ThriftGen::ColumnFamilyOptions cf_options;
        ag.__set_name("ag_counter");
        cf_options.__set_counter(true);
        cf_options.__set_max_versions(0);
        ag.__set_defaults(cf_options);
        ag_specs["ag_counter"] = ag;
      }

      // Column "e"
      {
        ThriftGen::ColumnFamilySpec cf;
        cf.__set_name("e");
        cf.__set_access_group("ag_counter");
        cf_specs["e"] = cf;
      }

      // Column "f"
      {
        ThriftGen::ColumnFamilySpec cf;
        ThriftGen::ColumnFamilyOptions cf_options;
        cf.__set_name("f");
        cf.__set_access_group("ag_counter");
        cf_options.__set_counter(false);
        cf.__set_options(cf_options);
        cf_specs["f"] = cf;
      }

      schema.__set_access_groups(ag_specs);
      schema.__set_column_families(cf_specs);

      client->table_create(ns, "TestTable", schema);

      HqlResult result;
      client->hql_query(result, ns, "SHOW CREATE TABLE TestTable");

      if (!result.results.empty())
        cout << result.results[0] << endl;

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
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

The following code snippet illustrates how to alter a table with the [table_alter](../reference_manual/thrift_api.md#tablealter) API. It assumes that the table _TestTable_ has been created as in the [Creating a table](http://hypertable.com/documentation/developer_guide/c4343/#creating-a-table) example.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::Schema schema;

      client->get_schema(schema, ns, "TestTable");

      // Rename column "b" to "z"
      {
        auto iter = schema.column_families.find("b");
        assert(iter != schema.column_families.end());
        ThriftGen::ColumnFamilySpec cf_spec = iter->second;
        schema.column_families.erase(iter);
        cf_spec.__set_name("z");
        schema.column_families["z"] = cf_spec;
      }

      // Add column "g"
      {
        ThriftGen::ColumnFamilySpec cf_spec;
        cf_spec.__set_name("g");
        cf_spec.__set_access_group("ag_counter");
        schema.column_families["g"] = cf_spec;
      }

      client->table_alter(ns, "TestTable", schema);

      HqlResult result;
      client->hql_query(result, ns, "SHOW CREATE TABLE TestTable");

      if (!result.results.empty())
        cout << result.results[0] << endl;

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
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

The code snippet below illustrates how to insert cells into a table using a mutator. The APIs introduced include [mutator_open](../reference_manual/thrift_api.md#mutatoropen), [mutator_set_cells](../reference_manual/thrift_api.md#mutatorsetcells), [mutator_flush](../reference_manual/thrift_api.md#mutatorflush), and [mutator_close](../reference_manual/thrift_api.md#mutatorclose). The code assumes the following using declaration.

    using Hypertable::ThriftGen::make_cell;

The example is shown below.

    try {
      vector<ThriftGen::Cell> cells;

      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::Mutator mutator = client->mutator_open(ns, "Fruits", 0, 0);

      // Auto-assigned timestamps

      cells.clear();
      cells.push_back(make_cell("lemon", "genus", "", "Citrus"));
      cells.push_back(make_cell("lemon", "tag", "bitter", ""));
      cells.push_back(make_cell("lemon", "description", 0, "The lemon (Citrus × "
                                "limon) is a small evergreen tree native to Asia."));
      client->mutator_set_cells(mutator, cells);
      client->mutator_flush(mutator);

      // Explicitly-supplied timestamps

      cells.clear();
      cells.push_back(make_cell("mango", "genus", "", "Mangifera", "2014-06-06 16:27:15"));
      cells.push_back(make_cell("mango", "tag", "sweet", "", "2014-06-06 16:27:15"));
      cells.push_back(make_cell("mango", "description", 0, "Mango is one of the "
                                "delicious seasonal fruits grown in the tropics.",
                                "2014-06-06 16:27:15"));
      cells.push_back(make_cell("mango", "description", 0, "The mango is a juicy "
                                "stone fruit belonging to the genus Mangifera, "
                                "consisting of numerous tropical fruiting trees, "
                                "that are cultivated mostly for edible fruits. ",
                                "2014-06-06 16:27:16"));
      client->mutator_set_cells(mutator, cells);
      client->mutator_flush(mutator);

      // Delete cells

      cells.clear();
      cells.push_back(make_cell("apple", "", nullptr, "", nullptr, nullptr,
                                ThriftGen::KeyFlag::DELETE_ROW));
      cells.push_back(make_cell("mango", "description", nullptr, "",
                                "2014-06-06 16:27:15", nullptr,
                                ThriftGen::KeyFlag::DELETE_CELL));
      client->mutator_set_cells(mutator, cells);
      client->mutator_flush(mutator);
      client->mutator_close(mutator);

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    } 

### Scanner

The following examples illustrate how to query a table using a scanner. The APIs introduced include the [scanner_open](../reference_manual/thrift_api.md#scanneropen), [scanner_get_cells](../reference_manual/thrift_api.md#scannergetcells), and [scanner_close](../reference_manual/thrift_api.md#scannerclose) functions, and the [ScanSpec](../reference_manual/thrift_api.md#scanspec) and [RowInterval](../reference_manual/thrift_api.md#rowinterval) classes.

####  Full table scan

The following code illustrates how to do a full table scan using the scanner APIs.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::Scanner scanner = client->scanner_open(ns, "Fruits", ThriftGen::ScanSpec());

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=canteloupe, column_family=description, column_qualifier=, timestamp=1424041587429147002, revision=1424041587429147002, flag=255), value=Cant
    eloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.)
    Cell(key=Key(row=canteloupe, column_family=genus, column_qualifier=, timestamp=1424041587429147001, revision=1424041587429147001, flag=255), value=Cucumis)
    Cell(key=Key(row=canteloupe, column_family=tag, column_qualifier=juicy, timestamp=1424041587429147003, revision=1424041587429147003, flag=255), value=<null>)
    Cell(key=Key(row=lemon, column_family=description, column_qualifier=, timestamp=1424041589772228003, revision=1424041589772228003, flag=255), value=The lemon
     (Citrus × limon) is a small evergreen tree native to Asia.)
    Cell(key=Key(row=lemon, column_family=genus, column_qualifier=, timestamp=1424041589772228001, revision=1424041589772228001, flag=255), value=Citrus)
    Cell(key=Key(row=lemon, column_family=tag, column_qualifier=bitter, timestamp=1424041589772228002, revision=1424041589772228002, flag=255), value=<null>)
    Cell(key=Key(row=mango, column_family=description, column_qualifier=, timestamp=1402097236000000000, revision=1424041589820413004, flag=255), value=The mango
     is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits. )
    Cell(key=Key(row=mango, column_family=genus, column_qualifier=, timestamp=1402097235000000000, revision=1424041589820413001, flag=255), value=Mangifera)
    Cell(key=Key(row=mango, column_family=tag, column_qualifier=sweet, timestamp=1402097235000000000, revision=1424041589820413002, flag=255), value=<null>)
    Cell(key=Key(row=orange, column_family=description, column_qualifier=, timestamp=1424041587398215002, revision=1424041587398215002, flag=255), value=The oran
    ge (specifically, the sweet orange) is the fruit of the citrus species Citrus × sinensis in the family Rutaceae.)
    Cell(key=Key(row=orange, column_family=genus, column_qualifier=, timestamp=1424041587398215001, revision=1424041587398215001, flag=255), value=Citrus)
    Cell(key=Key(row=orange, column_family=tag, column_qualifier=juicy, timestamp=1424041587398215003, revision=1424041587398215003, flag=255), value=<null>)

####  Restricted scan with ScanSpec

The following code illustrates how to do a table scan using a ScanSpec.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      // Return row range [lemon..orange)
      ThriftGen::RowInterval ri;
      vector row_intervals;
      ri.__set_start_row("lemon");
      ri.__set_start_inclusive(true);
      ri.__set_end_row("orange");
      ri.__set_end_inclusive(false);
      row_intervals.push_back(ri);
      ss.__set_row_intervals(row_intervals);

      // Return columns "genus", "tag:bitter", "tag:sweet"
      vector columns;
      columns.push_back("genus");
      columns.push_back("tag:bitter");
      columns.push_back("tag:sweet");
      ss.__set_columns(columns);

      // Return only most recent version of each cell
      ss.__set_versions(1);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "Fruits", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=lemon, column_family=genus, column_qualifier=, timestamp=1424041589772228001, revision=1424041589772228001, flag=255), value=Citrus)
    Cell(key=Key(row=lemon, column_family=tag, column_qualifier=bitter, timestamp=1424041589772228002, revision=1424041589772228002, flag=255), value=<null>)
    Cell(key=Key(row=mango, column_family=genus, column_qualifier=, timestamp=1402097235000000000, revision=1424041589820413001, flag=255), value=Mangifera)
    Cell(key=Key(row=mango, column_family=tag, column_qualifier=sweet, timestamp=1402097235000000000, revision=1424041589820413002, flag=255), value=<null>)

### HQL

####  hql_query

The following code illustrates how to issue HQL commands with the [hql_query](../reference_manual/thrift_api.md#hqlquery) API. It also introduces the [HqlResult](../reference_manual/thrift_api.md#hqlresult) class.

    try {
      HqlResult result;

      ThriftGen::Namespace ns = client->namespace_open("test");

      client->hql_query(result, ns, "GET LISTING");

      for (auto & str: result.results)
        cout << str << endl;

      client->hql_query(result, ns, "SELECT * from Fruits WHERE ROW = 'mango'");

      for (auto & cell : result.cells)
        cout << cell << endl;

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Fruits
    TestTable
    ^TestTable
    ^^TestTable
    sub	(namespace)
    Cell(key=Key(row=mango, column_family=description, column_qualifier=, timestamp=1402097236000000000, revision=1424041589820413004, flag=255), value=The mango
     is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits. )
    Cell(key=Key(row=mango, column_family=genus, column_qualifier=, timestamp=1402097235000000000, revision=1424041589820413001, flag=255), value=Mangifera)
    Cell(key=Key(row=mango, column_family=tag, column_qualifier=sweet, timestamp=1402097235000000000, revision=1424041589820413002, flag=255), value=<null>)

####  hql_query_as_arrays

The following code illustrates how to issue an HQL query with the [hql_query_as_arrays](../reference_manual/thrift_api.md#hqlqueryasarrays) API. It also introduces the [HqlResultAsArrays](../reference_manual/thrift_api.md#hqlresultasarrays) class.

    try {
      HqlResultAsArrays result_as_arrays;

      ThriftGen::Namespace ns = client->namespace_open("test");

      client->hql_query_as_arrays(result_as_arrays, ns,
                                  "SELECT * from Fruits WHERE ROW = 'lemon'");

      for (auto & cell_as_array : result_as_arrays.cells)
        cout << cell_as_array << endl;

      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    CellAsArray( row='lemon' cf='description' cq='' value='The lemon (Citrus × limon) is a small evergreen tree native to Asia.' timestamp=1424041589772228003)
    CellAsArray( row='lemon' cf='genus' cq='' value='Citrus' timestamp=1424041589772228001)
    CellAsArray( row='lemon' cf='tag' cq='bitter' value='' timestamp=1424041589772228002)

####  hql_exec (mutator)

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a mutator.

    try {
      HqlResult result;
      vector cells;

      ThriftGen::Namespace ns = client->namespace_open("test");

      client->hql_exec(result, ns, "INSERT INTO Fruits VALUES ('strawberry', "
                       "'genus', 'Fragaria'), ('strawberry', 'tag:fibrous', ''),"
                       " ('strawberry', 'description', 'The garden strawberry is"
                       " a widely grown hybrid species of the genus Fragaria')",
                       true, false);
      cells.push_back(make_cell("pineapple", "genus", "", "Ananas"));
      cells.push_back(make_cell("pineapple", "tag", "acidic", ""));
      cells.push_back(make_cell("pineapple", "description", 0, "The pineapple "
                                "(Ananas comosus) is a tropical plant with "
                                "edible multiple fruit consisting of coalesced "
                                "berries."));
      client->mutator_set_cells(result.mutator, cells);
      client->mutator_flush(result.mutator);
      client->mutator_close(result.mutator);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

####  hql_exec (scanner}

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a scanner.

    try {
      HqlResult result;

      ThriftGen::Namespace ns = client->namespace_open("test");

      client->hql_exec(result, ns, "SELECT * from Fruits", false, true);

      vector cells;
      do {
        client->scanner_get_cells(cells, result.scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(result.scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=canteloupe, column_family=description, column_qualifier=, timestamp=1424041587429147002, revision=1424041587429147002, flag=255), value=Cant
    eloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.)
    Cell(key=Key(row=canteloupe, column_family=genus, column_qualifier=, timestamp=1424041587429147001, revision=1424041587429147001, flag=255), value=Cucumis)
    Cell(key=Key(row=canteloupe, column_family=tag, column_qualifier=juicy, timestamp=1424041587429147003, revision=1424041587429147003, flag=255), value=<null>)
    Cell(key=Key(row=lemon, column_family=description, column_qualifier=, timestamp=1424041589772228003, revision=1424041589772228003, flag=255), value=The lemon
     (Citrus × limon) is a small evergreen tree native to Asia.)
    Cell(key=Key(row=lemon, column_family=genus, column_qualifier=, timestamp=1424041589772228001, revision=1424041589772228001, flag=255), value=Citrus)
    Cell(key=Key(row=lemon, column_family=tag, column_qualifier=bitter, timestamp=1424041589772228002, revision=1424041589772228002, flag=255), value=<null>)
    Cell(key=Key(row=mango, column_family=description, column_qualifier=, timestamp=1402097236000000000, revision=1424041589820413004, flag=255), value=The mango
     is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits. )
    Cell(key=Key(row=mango, column_family=genus, column_qualifier=, timestamp=1402097235000000000, revision=1424041589820413001, flag=255), value=Mangifera)
    Cell(key=Key(row=mango, column_family=tag, column_qualifier=sweet, timestamp=1402097235000000000, revision=1424041589820413002, flag=255), value=<null>)
    Cell(key=Key(row=orange, column_family=description, column_qualifier=, timestamp=1424041587398215002, revision=1424041587398215002, flag=255), value=The oran
    ge (specifically, the sweet orange) is the fruit of the citrus species Citrus × sinensis in the family Rutaceae.)
    Cell(key=Key(row=orange, column_family=genus, column_qualifier=, timestamp=1424041587398215001, revision=1424041587398215001, flag=255), value=Citrus)
    Cell(key=Key(row=orange, column_family=tag, column_qualifier=juicy, timestamp=1424041587398215003, revision=1424041587398215003, flag=255), value=<null>)
    Cell(key=Key(row=pineapple, column_family=description, column_qualifier=, timestamp=1424041589871285003, revision=1424041589871285003, flag=255), value=The p
    ineapple (Ananas comosus) is a tropical plant with edible multiple fruit consisting of coalesced berries.)
    Cell(key=Key(row=pineapple, column_family=genus, column_qualifier=, timestamp=1424041589871285001, revision=1424041589871285001, flag=255), value=Ananas)
    Cell(key=Key(row=pineapple, column_family=tag, column_qualifier=acidic, timestamp=1424041589871285002, revision=1424041589871285002, flag=255), value=<null>)
    Cell(key=Key(row=strawberry, column_family=description, column_qualifier=, timestamp=1424041589871285006, revision=1424041589871285006, flag=255), value=The
    garden strawberry is a widely grown hybrid species of the genus Fragaria)
    Cell(key=Key(row=strawberry, column_family=genus, column_qualifier=, timestamp=1424041589871285004, revision=1424041589871285004, flag=255), value=Fragaria)
    Cell(key=Key(row=strawberry, column_family=tag, column_qualifier=fibrous, timestamp=1424041589871285005, revision=1424041589871285005, flag=255), value=<null
    >)

### Secondary Indices

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
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      vector column_predicates;
      column_predicate.__set_column_family("section");
      column_predicate.__set_operation(ColumnPredicateOperation::EXACT_MATCH);
      column_predicate.__set_value("books");
      column_predicates.push_back(column_predicate);
      ss.__set_column_predicates(column_predicates);

      vector columns;
      columns.push_back("title");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=0307743659, column_family=title, column_qualifier=, timestamp=1424041591979977001, revision=1424041591979977001, flag=255), value=The Shinin
    g Mass Market Paperback)
    Cell(key=Key(row=0321321928, column_family=title, column_qualifier=, timestamp=1424041591979977008, revision=1424041591979977008, flag=255), value=C++ Common
     Knowledge: Essential Intermediate Programming [Paperback])
    Cell(key=Key(row=0321776402, column_family=title, column_qualifier=, timestamp=1424041591979977019, revision=1424041591979977019, flag=255), value=C++ Primer
     Plus (6th Edition) (Developer's Library))

####  Value index (exact match with qualifier)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title FROM products WHERE info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;
      vector column_predicates;
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("actor");
      int operation = (int)ColumnPredicateOperation::EXACT_MATCH |
                      (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("Jack Nicholson");
      column_predicates.push_back(column_predicate);
      ss.__set_column_predicates(column_predicates);

      vector columns;
      columns.push_back("title");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=B00002VWE0, column_family=title, column_qualifier=, timestamp=1424041591979977030, revision=1424041591979977030, flag=255), value=Five Easy
    Pieces (1970))
    Cell(key=Key(row=B002VWNIDG, column_family=title, column_qualifier=, timestamp=1424041591979977049, revision=1424041591979977049, flag=255), value=The Shinin
    g (1980))

####  Value index (prefix match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =^ 'Addison-Wesley';

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      vector column_predicates;
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("publisher");
      int operation = (int)ColumnPredicateOperation::PREFIX_MATCH |
                      (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("Addison-Wesley");
      column_predicates.push_back(column_predicate);
      ss.__set_column_predicates(column_predicates);

      vector columns;
      columns.push_back("title");
      columns.push_back("info:publisher");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=0321321928, column_family=title, column_qualifier=, timestamp=1424041591979977008, revision=1424041591979977008, flag=255), value=C++ Common
     Knowledge: Essential Intermediate Programming [Paperback])
    Cell(key=Key(row=0321321928, column_family=info, column_qualifier=publisher, timestamp=1424041591903572000, revision=1424041591979977013, flag=255), value=Ad
    dison-Wesley Professional; 1 edition (March 10, 2005))
    Cell(key=Key(row=0321776402, column_family=title, column_qualifier=, timestamp=1424041591979977019, revision=1424041591979977019, flag=255), value=C++ Primer
     Plus (6th Edition) (Developer's Library))
    Cell(key=Key(row=0321776402, column_family=info, column_qualifier=publisher, timestamp=1424041591903423000, revision=1424041591979977024, flag=255), value=Ad
    dison-Wesley Professional; 6 edition (October 28, 2011))

####  Value index (regex match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =~ /^Addison-Wesley/;

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      vector column_predicates;
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("publisher");
      int operation = (int)ColumnPredicateOperation::REGEX_MATCH |
                      (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("^Addison-Wesley");
      column_predicates.push_back(column_predicate);
      ss.__set_column_predicates(column_predicates);

      vector columns;
      columns.push_back("title");
      columns.push_back("info:publisher");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=0321321928, column_family=title, column_qualifier=, timestamp=1424041591979977008, revision=1424041591979977008, flag=255), value=C++ Common
     Knowledge: Essential Intermediate Programming [Paperback])
    Cell(key=Key(row=0321321928, column_family=info, column_qualifier=publisher, timestamp=1424041591903572000, revision=1424041591979977013, flag=255), value=Ad
    dison-Wesley Professional; 1 edition (March 10, 2005))
    Cell(key=Key(row=0321776402, column_family=title, column_qualifier=, timestamp=1424041591979977019, revision=1424041591979977019, flag=255), value=C++ Primer
     Plus (6th Edition) (Developer's Library))
    Cell(key=Key(row=0321776402, column_family=info, column_qualifier=publisher, timestamp=1424041591903423000, revision=1424041591979977024, flag=255), value=Ad
    dison-Wesley Professional; 6 edition (October 28, 2011))

####  Qualifier index (exists)

The following HQL query which leverages the qualifier index of the _info_ column:

    SELECT title FROM products WHERE Exists(info:studio);

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      vector column_predicates;
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("studio");
      column_predicate.__set_operation(ColumnPredicateOperation::QUALIFIER_EXACT_MATCH);
      column_predicates.push_back(column_predicate);
      ss.__set_column_predicates(column_predicates);

      vector columns;
      columns.push_back("title");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=B00002VWE0, column_family=title, column_qualifier=, timestamp=1424041591979977030, revision=1424041591979977030, flag=255), value=Five Easy
    Pieces (1970))
    Cell(key=Key(row=B000Q66J1M, column_family=title, column_qualifier=, timestamp=1424041591979977039, revision=1424041591979977039, flag=255), value=2001: A Sp
    ace Odyssey [Blu-ray])
    Cell(key=Key(row=B002VWNIDG, column_family=title, column_qualifier=, timestamp=1424041591979977049, revision=1424041591979977049, flag=255), value=The Shinin
    g (1980))

####  Qualifier index (exists regex prefix match)

The following HQL query which leverages the qualifier index of the _category_ column:

    SELECT title FROM products WHERE Exists(category:/^\/Movies/);

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      vector column_predicates;
      column_predicate.__set_column_family("category");
      column_predicate.__set_column_qualifier("^/Movies");
      column_predicate.__set_operation(ColumnPredicateOperation::QUALIFIER_REGEX_MATCH);
      column_predicates.push_back(column_predicate);
      ss.__set_column_predicates(column_predicates);

      vector columns;
      columns.push_back("title");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=B00002VWE0, column_family=title, column_qualifier=, timestamp=1424041591979977030, revision=1424041591979977030, flag=255), value=Five Easy
    Pieces (1970))
    Cell(key=Key(row=B000Q66J1M, column_family=title, column_qualifier=, timestamp=1424041591979977039, revision=1424041591979977039, flag=255), value=2001: A Sp
    ace Odyssey [Blu-ray])
    Cell(key=Key(row=B002VWNIDG, column_family=title, column_qualifier=, timestamp=1424041591979977049, revision=1424041591979977049, flag=255), value=The Shinin
    g (1980))

####  Value index (OR query)

The following HQL query performs a boolean _OR_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen P/ OR info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      vector column_predicates;
      // info:author =~ /^Stephen P/
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("author");
      int operation = (int)ColumnPredicateOperation::REGEX_MATCH |
                      (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("^Stephen P");
      column_predicates.push_back(column_predicate);
      // info:publisher =^ "Anchor"
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("publisher");
      operation = (int)ColumnPredicateOperation::PREFIX_MATCH |
                  (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("Anchor");
      column_predicates.push_back(column_predicate);

      ss.__set_column_predicates(column_predicates);

      vector columns;
      columns.push_back("title");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=0307743659, column_family=title, column_qualifier=, timestamp=1424041591979977001, revision=1424041591979977001, flag=255), value=The Shinin
    g Mass Market Paperback)
    Cell(key=Key(row=0321776402, column_family=title, column_qualifier=, timestamp=1424041591979977019, revision=1424041591979977019, flag=255), value=C++ Primer
     Plus (6th Edition) (Developer's Library))

####  Value index (AND query)

The following HQL query performs a boolean _AND_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      vector column_predicates;
      // info:author =~ /^Stephen [PK]/
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("author");
      int operation = (int)ColumnPredicateOperation::REGEX_MATCH |
                      (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("^Stephen [PK]");
      column_predicates.push_back(column_predicate);
      // info:publisher =^ "Anchor"
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("publisher");
      operation = (int)ColumnPredicateOperation::PREFIX_MATCH |
                  (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("Anchor");
      column_predicates.push_back(column_predicate);

      ss.__set_column_predicates(column_predicates);

      // AND the predicates together
      ss.__set_and_column_predicates(true);

      vector columns;
      columns.push_back("title");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=0307743659, column_family=title, column_qualifier=, timestamp=1424041591979977001, revision=1424041591979977001, flag=255), value=The Shinin
    g Mass Market Paperback)

####  Value index (AND row interval)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW interval:

    SELECT title
      FROM products
      WHERE ROW > 'B00002VWE0' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      // ROW > 'B00002VWE0'
      vector row_intervals;
      ThriftGen::RowInterval ri;
      ri.__set_start_row("B00002VWE0");
      ri.__set_start_inclusive(false);
      row_intervals.push_back(ri);
      ss.__set_row_intervals(row_intervals);

      // info:actor = 'Jack Nicholson'
      vector column_predicates;
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("actor");
      int operation = (int)ColumnPredicateOperation::EXACT_MATCH |
                      (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("Jack Nicholson");
      column_predicates.push_back(column_predicate);
      ss.__set_column_predicates(column_predicates);

      // AND the predicates together
      ss.__set_and_column_predicates(true);

      vector columns;
      columns.push_back("title");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=B002VWNIDG, column_family=title, column_qualifier=, timestamp=1424041591979977049, revision=1424041591979977049, flag=255), value=The Shinin
    g (1980))

####  Value index (AND row prefix)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW prefix interval:

    SELECT title
      FROM products
      WHERE ROW =^ 'B' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");

      ThriftGen::ScanSpec ss;

      // ROW > 'B00002VWE0'
      vector row_intervals;
      ThriftGen::RowInterval ri;
      ri.__set_start_row("B");
      ri.__set_start_inclusive(true);
      ri.__set_end_row("C");
      ri.__set_end_inclusive(false);
      row_intervals.push_back(ri);
      ss.__set_row_intervals(row_intervals);

      // info:actor = 'Jack Nicholson'
      vector column_predicates;
      column_predicate.__set_column_family("info");
      column_predicate.__set_column_qualifier("actor");
      int operation = (int)ColumnPredicateOperation::EXACT_MATCH |
                      (int)ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      column_predicate.__set_operation((ColumnPredicateOperation::type)operation);
      column_predicate.__set_value("Jack Nicholson");
      column_predicates.push_back(column_predicate);
      ss.__set_column_predicates(column_predicates);

      // AND the predicates together
      ss.__set_and_column_predicates(true);

      vector columns;
      columns.push_back("title");
      ss.__set_columns(columns);

      ThriftGen::Scanner scanner = client->scanner_open(ns, "products", ss);

      vector cells;
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());

      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=B00002VWE0, column_family=title, column_qualifier=, timestamp=1424041591979977030, revision=1424041591979977030, flag=255), value=Five Easy
    Pieces (1970))
    Cell(key=Key(row=B002VWNIDG, column_family=title, column_qualifier=, timestamp=1424041591979977049, revision=1424041591979977049, flag=255), value=The Shinin
    g (1980))

### Asynchronous APIs

This section describes how to use the asynchronous APIs. The examples assume that tables _Profile_ and _Session_ are created and loaded with the following HQL commands.

    CREATE TABLE Profile (info, last_access MAX_VERSIONS 1);

    CREATE TABLE Session (user_id, page_hit);

    INSERT INTO Profile
      VALUES ('1', 'info:name', 'Joe'), ('2', 'info:name', 'Sue');

####  Async mutator

The code snippet below illustrates how to insert cells into multiple tables simultaneously using an asynchronous mutator. The APIs introduced include the [future_open](../reference_manual/thrift_api.md#futureopen), [future_get_result](../reference_manual/thrift_api.md#futuregetresult), [future_close](../reference_manual/thrift_api.md#futureclose), [async_mutator_open](../reference_manual/thrift_api.md#asyncmutatoropen), [async_mutator_set_cells](../reference_manual/thrift_api.md#asyncmutatorsetcells), [async_mutator_flush](../reference_manual/thrift_api.md#asyncmutatorflush), and [async_mutator_close](../reference_manual/thrift_api.md#asyncmutatorclose) functions and the [Result](../reference_manual/thrift_api.md#result) class.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");
      Future ff = client->future_open(0);
      MutatorAsync profile_mutator = client->async_mutator_open(ns, "Profile", ff, 0);
      MutatorAsync session_mutator = client->async_mutator_open(ns, "Session", ff, 0);

      vector cells;

      cells.push_back(make_cell("1", "last_access", 0, "2014-06-13 16:06:09"));
      cells.push_back(make_cell("2", "last_access", 0, "2014-06-13 16:06:10"));
      client->async_mutator_set_cells(profile_mutator, cells);

      cells.clear();
      cells.push_back(make_cell("0001-200238", "user_id", "1", ""));
      cells.push_back(make_cell("0001-200238", "page_hit", 0, "/index.html"));
      cells.push_back(make_cell("0002-383049", "user_id", "2", ""));
      cells.push_back(make_cell("0002-383049", "page_hit", 0, "/foo/bar.html"));
      client->async_mutator_set_cells(session_mutator, cells);

      client->async_mutator_flush(profile_mutator);
      client->async_mutator_flush(session_mutator);

      ThriftGen::Result result;
      size_t result_count = 0;
      while (true) {
        client->future_get_result(result, ff, 0);
        if (result.is_empty)
          break;
        result_count++;
        if (result.is_error) {
          cout << "Async mutator error:  " << result.error_msg << endl;
          _exit(1);
        }
        if (result.id == profile_mutator)
          cout << "Result is from Profile mutation" << endl;
        else if (result.id == session_mutator)
          cout << "Result is from Session mutation" << endl;
      }

      cout << "result count = " << result_count << endl;

      client->async_mutator_close(profile_mutator);
      client->async_mutator_close(session_mutator);
      client->future_close(ff);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile mutation
    Result is from Session mutation
    result count = 2

####  Async scanner (Result)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [Result](../reference_manual/thrift_api.md#result) object. The APIs introduced include the [async_scanner_open](../reference_manual/thrift_api.md#asyncscanneropen) and [async_scanner_close](../reference_manual/thrift_api.md#asyncscannerclose) functions.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");
      ScannerAsync profile_scanner;
      ScannerAsync session_scanner;

      ThriftGen::Future ff = client->future_open(0);

      {
        ThriftGen::ScanSpec ss;
        vector row_intervals;
        ThriftGen::RowInterval ri;
        ri.__set_start_row("1");
        ri.__set_start_inclusive(true);
        ri.__set_end_row("1");
        ri.__set_end_inclusive(true);
        row_intervals.push_back(ri);
        ss.__set_row_intervals(row_intervals);
        profile_scanner = client->async_scanner_open(ns, "Profile", ff, ss);
      }

      {
        ThriftGen::ScanSpec ss;
        vector row_intervals;
        ThriftGen::RowInterval ri;
        ri.__set_start_row("0001-200238");
        ri.__set_start_inclusive(true);
        ri.__set_end_row("0001-200238");
        ri.__set_end_inclusive(true);
        row_intervals.push_back(ri);
        ss.__set_row_intervals(row_intervals);
        session_scanner = client->async_scanner_open(ns, "Session", ff, ss);
      }

      ThriftGen::Result result;

      while (true) {

        client->future_get_result(result, ff, 0);

        if (result.is_empty)
          break;

        if (result.is_error) {
          cout << "Async scanner error:  " << result.error_msg << endl;
          _exit(1);
        }

        assert(result.is_scan);
        assert(result.id == profile_scanner || result.id == session_scanner);

        if (result.id == profile_scanner)
          cout << "Result is from Profile scan" << endl;
        else if (result.id == session_scanner)
          cout << "Result is from Session scan" << endl;

        for (auto & cell : result.cells)
          cout << cell << endl;

      }

      client->async_scanner_close(profile_scanner);
      client->async_scanner_close(session_scanner);
      client->future_close(ff);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile scan
    Cell(key=Key(row=1, column_family=info, column_qualifier=name, timestamp=1424041593378619001, revision=1424041593378619001, flag=255), value=Joe)
    Cell(key=Key(row=1, column_family=last_access, column_qualifier=, timestamp=1424041593423600001, revision=1424041593423600001, flag=255), value=2014-06-13 16
    :06:09)
    Result is from Session scan
    Cell(key=Key(row=0001-200238, column_family=user_id, column_qualifier=1, timestamp=1424041593423711001, revision=1424041593423711001, flag=255), value=<null>
    )
    Cell(key=Key(row=0001-200238, column_family=page_hit, column_qualifier=, timestamp=1424041593423711002, revision=1424041593423711002, flag=255), value=/index
    .html)

####  Async scanner (ResultSerialized)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultSerialized](../reference_manual/thrift_api.md#resultserialized) object. This example introduces the [future_get_result_serialized](../reference_manual/thrift_api.md#futuregetresultserialized) API.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");
      ScannerAsync profile_scanner;
      ScannerAsync session_scanner;

      ThriftGen::Future ff = client->future_open(0);

      {
        ThriftGen::ScanSpec ss;
        vector row_intervals;
        ThriftGen::RowInterval ri;
        ri.__set_start_row("1");
        ri.__set_start_inclusive(true);
        ri.__set_end_row("1");
        ri.__set_end_inclusive(true);
        row_intervals.push_back(ri);
        ss.__set_row_intervals(row_intervals);
        profile_scanner = client->async_scanner_open(ns, "Profile", ff, ss);
      }

      {
        ThriftGen::ScanSpec ss;
        vector row_intervals;
        ThriftGen::RowInterval ri;
        ri.__set_start_row("0001-200238");
        ri.__set_start_inclusive(true);
        ri.__set_end_row("0001-200238");
        ri.__set_end_inclusive(true);
        row_intervals.push_back(ri);
        ss.__set_row_intervals(row_intervals);
        session_scanner = client->async_scanner_open(ns, "Session", ff, ss);
      }

      ThriftGen::ResultSerialized result_serialized;

      while (true) {

        client->future_get_result_serialized(result_serialized, ff, 0);

        if (result_serialized.is_empty)
          break;

        if (result_serialized.is_error) {
          cout << "Async scanner error:  " << result_serialized.error_msg << endl;
          _exit(1);
        }

        assert(result_serialized.is_scan);
        assert(result_serialized.id == profile_scanner || result_serialized.id == session_scanner);

        if (result_serialized.id == profile_scanner)
          cout << "Result is from Profile scan" << endl;
        else if (result_serialized.id == session_scanner)
          cout << "Result is from Session scan" << endl;

        SerializedCellsReader reader(result_serialized.cells.data(),
                                     result_serialized.cells.size());

        Hypertable::Cell hcell;
        while (reader.next()) {
          reader.get(hcell);
          cout << convert_cell(hcell) << endl;
        }

      }

      client->async_scanner_close(profile_scanner);
      client->async_scanner_close(session_scanner);
      client->future_close(ff);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile scan
    Cell(key=Key(row=1, column_family=info, column_qualifier=name, timestamp=1424041593378619001, revision=-9223372036854775806, flag=255), value=Joe)
    Cell(key=Key(row=1, column_family=last_access, column_qualifier=, timestamp=1424041593423600001, revision=-9223372036854775806, flag=255), value=2014-06-13 1
    6:06:09)
    Result is from Session scan
    Cell(key=Key(row=0001-200238, column_family=user_id, column_qualifier=1, timestamp=1424041593423711001, revision=-9223372036854775806, flag=255), value=)
    Cell(key=Key(row=0001-200238, column_family=page_hit, column_qualifier=, timestamp=1424041593423711002, revision=-9223372036854775806, flag=255), value=/inde
    x.html)

####  Async scanner (ResultAsArrays)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultAsArrays](../reference_manual/thrift_api.md#resultasarrays) object. This example introduces the [future_get_result_as_arrays](../reference_manual/thrift_api.md#futuregetresultasarrays) API.

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");
      ScannerAsync profile_scanner;
      ScannerAsync session_scanner;

      ThriftGen::Future ff = client->future_open(0);

      {
        ThriftGen::ScanSpec ss;
        vector row_intervals;
        ThriftGen::RowInterval ri;
        ri.__set_start_row("1");
        ri.__set_start_inclusive(true);
        ri.__set_end_row("1");
        ri.__set_end_inclusive(true);
        row_intervals.push_back(ri);
        ss.__set_row_intervals(row_intervals);
        profile_scanner = client->async_scanner_open(ns, "Profile", ff, ss);
      }

      {
        ThriftGen::ScanSpec ss;
        vector row_intervals;
        ThriftGen::RowInterval ri;
        ri.__set_start_row("0001-200238");
        ri.__set_start_inclusive(true);
        ri.__set_end_row("0001-200238");
        ri.__set_end_inclusive(true);
        row_intervals.push_back(ri);
        ss.__set_row_intervals(row_intervals);
        session_scanner = client->async_scanner_open(ns, "Session", ff, ss);
      }

      ThriftGen::ResultAsArrays result_as_arrays;

      while (true) {

        client->future_get_result_as_arrays(result_as_arrays, ff, 0);

        if (result_as_arrays.is_empty)
          break;

        if (result_as_arrays.is_error) {
          cout << "Async scanner error:  " << result_as_arrays.error_msg << endl;
          _exit(1);
        }

        assert(result_as_arrays.is_scan);
        assert(result_as_arrays.id == profile_scanner || result_as_arrays.id == session_scanner);

        if (result_as_arrays.id == profile_scanner)
          cout << "Result is from Profile scan" << endl;
        else if (result_as_arrays.id == session_scanner)
          cout << "Result is from Session scan" << endl;

        for (auto & cell_as_array : result_as_arrays.cells)
          cout << cell_as_array << endl;

      }

      client->async_scanner_close(profile_scanner);
      client->async_scanner_close(session_scanner);
      client->future_close(ff);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile scan
    CellAsArray( row='1' cf='info' cq='name' value='Joe' timestamp=1424041593378619001)
    CellAsArray( row='1' cf='last_access' cq='' value='2014-06-13 16:06:09' timestamp=1424041593423600001)
    Result is from Session scan
    CellAsArray( row='0001-200238' cf='user_id' cq='1' value='' timestamp=1424041593423711001)
    CellAsArray( row='0001-200238' cf='page_hit' cq='' value='/index.html' timestamp=1424041593423711002)

### Atomic counters

This section describes how to use atomic counters. The examples assume that a  _Hits_ table has been created with the following HQL command.

    CREATE TABLE Hits (count COUNTER);

####  Increment

The code snippet below illustrates how to increment per-second hit counts for pages of a website.

    try {
      vector cells;
      ThriftGen::Namespace ns = client->namespace_open("test");
      ThriftGen::Mutator mutator = client->mutator_open(ns, "Hits", 0, 0);

      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:18", "1"));
      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:18", "1"));
      cells.push_back(make_cell("/foo/bar.html", "count", "2014-06-14 07:31:18", "1"));
      cells.push_back(make_cell("/foo/bar.html", "count", "2014-06-14 07:31:18", "1"));
      cells.push_back(make_cell("/foo/bar.html", "count", "2014-06-14 07:31:18", "1"));
      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:19", "1"));
      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:19", "1"));
      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:19", "1"));
      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:19", "1"));
      cells.push_back(make_cell("/foo/bar.html", "count", "2014-06-14 07:31:19", "1"));
      client->mutator_set_cells(mutator, cells);
      client->mutator_flush(mutator);

      {
        ThriftGen::ScanSpec ss;
        ThriftGen::Scanner scanner = client->scanner_open(ns, "Hits", ss);
        do {
          client->scanner_get_cells(cells, scanner);
          for (auto & cell : cells)
            cout << cell << endl;
        } while (!cells.empty());
        client->scanner_close(scanner);
      }

      client->mutator_close(mutator);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=/foo/bar.html, column_family=count, column_qualifier=2014-06-14 07:31:18, timestamp=1424041594216718003, revision=1424041594216718003, flag=
    255), value=3)
    Cell(key=Key(row=/foo/bar.html, column_family=count, column_qualifier=2014-06-14 07:31:19, timestamp=1424041594216718004, revision=1424041594216718004, flag=
    255), value=1)
    Cell(key=Key(row=/index.html, column_family=count, column_qualifier=2014-06-14 07:31:18, timestamp=1424041594216718006, revision=1424041594216718006, flag=25
    5), value=2)
    Cell(key=Key(row=/index.html, column_family=count, column_qualifier=2014-06-14 07:31:19, timestamp=1424041594216718010, revision=1424041594216718010, flag=25
    5), value=4)

####  Reset and subtraction

The code snippet below illustrates how to reset and subtract from counters.

    try {
      vector cells;
      ThriftGen::Namespace ns = client->namespace_open("test");
      ThriftGen::Mutator mutator = client->mutator_open(ns, "Hits", 0, 0);

      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:18", "=0"));
      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:18", "7"));
      cells.push_back(make_cell("/foo/bar.html", "count", "2014-06-14 07:31:18", "-1"));
      cells.push_back(make_cell("/index.html", "count", "2014-06-14 07:31:19", "-2"));
      cells.push_back(make_cell("/foo/bar.html", "count", "2014-06-14 07:31:19", "=19"));
      client->mutator_set_cells(mutator, cells);
      client->mutator_flush(mutator);

      {
        ThriftGen::ScanSpec ss;
        ThriftGen::Scanner scanner = client->scanner_open(ns, "Hits", ss);
        do {
          client->scanner_get_cells(cells, scanner);
          for (auto & cell : cells)
            cout << cell << endl;
        } while (!cells.empty());
        client->scanner_close(scanner);
      }

      client->mutator_close(mutator);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    Cell(key=Key(row=/foo/bar.html, column_family=count, column_qualifier=2014-06-14 07:31:18, timestamp=1424041594278805001, revision=1424041594278805001, flag=
    255), value=2)
    Cell(key=Key(row=/foo/bar.html, column_family=count, column_qualifier=2014-06-14 07:31:19, timestamp=1424041594278805002, revision=1424041594278805002, flag=
    255), value=19)
    Cell(key=Key(row=/index.html, column_family=count, column_qualifier=2014-06-14 07:31:18, timestamp=1424041594278805004, revision=1424041594278805004, flag=25
    5), value=7)
    Cell(key=Key(row=/index.html, column_family=count, column_qualifier=2014-06-14 07:31:19, timestamp=1424041594278805005, revision=1424041594278805005, flag=25
    5), value=2)

### Creating unique keys

This section illustrates how to create unique keys using the [create_cell_unique](../reference_manual/thrift_api.md#createcellunique) API. The example show how you can create unique user IDs for an application. The code assumes that a _User_ table has been created with the following HQL command.

    CREATE TABLE User (info, id TIME_ORDER desc MAX_VERSIONS 1);

The example code snippet is as follows.

    ThriftGen::Key key;
    key.column_family="id";
    String ret;

    try {
      ThriftGen::Namespace ns = client->namespace_open("test");
      key.row="joe1987";
      client->create_cell_unique(ret, ns, "User", key, "");
      key.row="mary.bellweather";
      client->create_cell_unique(ret, ns, "User", key, "");
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

    {
      ThriftGen::Namespace ns = client->namespace_open("test");
      try {
        key.row="joe1987";
        client->create_cell_unique(ret, ns, "User", key, "");
      }
      catch (ClientException &e) {
        if (e.code == Error::ALREADY_EXISTS)
          cout << "User name '" << key.row << "' is already taken" << endl;
        else
          cout << e.message << endl;
      }
      client->namespace_close(ns);
    }

    try {
      vector cells;
      ThriftGen::Namespace ns = client->namespace_open("test");
      ThriftGen::Scanner scanner = client->scanner_open(ns, "User", ThriftGen::ScanSpec());
      do {
        client->scanner_get_cells(cells, scanner);
        for (auto & cell : cells)
          cout << cell << endl;
      } while (!cells.empty());
      client->scanner_close(scanner);
      client->namespace_close(ns);
    }
    catch (ClientException &e) {
      cout << e.message << endl;
      exit(1);
    }

The following is example output produced by the above code snippet.

    User name 'joe1987' is already taken
    Cell(key=Key(row=joe1987, column_family=id, column_qualifier=, timestamp=1424041594928989001, revision=1424041594928989001, flag=255), value=97f611ce-d7d9-4d
    d5-b3cb-5054822cec57)
    Cell(key=Key(row=mary.bellweather, column_family=id, column_qualifier=, timestamp=1424041594968289001, revision=1424041594968289001, flag=255), value=caedc7c
    3-4b91-4bc4-b90d-d3142d8a31e4)

### Appendix - helper functions

The following helper functions are used in the examples in this document.

    const ThriftGen::Cell convert_cell_as_array(ThriftGen::CellAsArray &cell_as_array) {
      char *end;
      ThriftGen::Key key;
      ThriftGen::Cell cell;
      int len = cell_as_array.size();
      switch (len) {
      case 7: key.__set_flag((ThriftGen::KeyFlag::type)atoi(cell_as_array[6].c_str()));
      case 6: key.__set_revision((Lld)strtoll(cell_as_array[5].c_str(), &end, 0));
      case 5: key.__set_timestamp((Lld)strtoll(cell_as_array[4].c_str(), &end, 0));
      case 4: cell.__set_value(cell_as_array[3]);
      case 3: key.__set_column_qualifier(cell_as_array[2]);
      case 2: key.__set_column_family(cell_as_array[1]);
      case 1: key.__set_row(cell_as_array[0]);
        cell.__set_key(key);
        break;
      default:
        HT_THROWF(Error::BAD_KEY, "CellAsArray: bad size: %d", len);
      }
      return cell;
    }

    const ThriftGen::Cell convert_cell(Hypertable::Cell &hcell) {
      ThriftGen::Cell cell;
      ThriftGen::Key key;
      ThriftGen::Value value;

      key.__set_row(hcell.row_key);
      key.__set_column_family(hcell.column_family);
      if (hcell.column_qualifier && *hcell.column_qualifier)
        key.__set_column_qualifier(hcell.column_qualifier);
      key.__set_flag((ThriftGen::KeyFlag::type)hcell.flag);
      key.__set_revision(hcell.revision);
      key.__set_timestamp(hcell.timestamp);

      value.append((const char *)hcell.value, hcell.value_len);

      cell.__set_key(key);
      cell.__set_value(value);
      return cell;
    }
