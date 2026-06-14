# PHP

## Table of Contents

### Introduction

This document presents example PHP code that excercises the Thrift API. To quickly get Hypertable up and running on a single machine so that you can try out these examples, see [Hypertable Standalone Installation](../installation/quick_start_standalone.md). The source code for all of the examples in this document, along with the build and run scripts, can be found in [hypertable_api_example.tgz](http://hypertable.com/pub/hypertable_api_example.tgz).

### Environment setup and running

The following bash script illustrates how to setup an enviroment and run a Hypertable PHP thrift client program.

    HYPERTABLE_HOME=/opt/hypertable/current

    export PHPTHRIFT_ROOT=$HYPERTABLE_HOME/lib/php

    php ./hypertable_api_test.php

### Program boilerplate

To include the thrift cient code into your program, a global variable _THRIFT_ROOT_ must be set to the lib/php directory in the Hypertable installation. Once that is set, the ThriftClient.php must then be included in your program. For the datetime conversions used throughout the examples, the timezone must be set with a call to the _date_default_timezone_set_ function. The following code snippet illustrates how to do this. It assumes that an environment variable _PHPTHRIFT_ROOT_ has been set to the lib/php direcotry of the Hypertable installation.

    if (!isset($GLOBALS['THRIFT_ROOT']))
        $GLOBALS['THRIFT_ROOT'] = getenv('PHPTHRIFT_ROOT');

    require_once $GLOBALS['THRIFT_ROOT'].'/ThriftClient.php';

    date_default_timezone_set("America/Los_Angeles");

### Creating a thrift client

All of the examples in this document reference a pointer to a Thrift client object. The following code snippet illustrates how to create a Thrift client object connected to a ThriftBroker listening on the default port (15867) on localhost. To change the ThriftBroker location, just change "localhost" to the domain name of the machine on which the ThriftBroker is running.

    try {
      $client = new Hypertable_ThriftClient("localhost", 15867);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

### Basics

The following code snippet illustrates the basics of working with namespaces and tables. The APIs introduced include [namespace_exists](../reference_manual/thrift_api.md#namespaceexists), [namespace_create](../reference_manual/thrift_api.md#namespacecreate), [namespace_open](../reference_manual/thrift_api.md#namespaceopen), [namespace_get_listing](../reference_manual/thrift_api.md#namespacegetlisting), [namespace_close](../reference_manual/thrift_api.md#namespaceclose), [table_drop](../reference_manual/thrift_api.md#tabledrop), and [table_create](../reference_manual/thrift_api.md#tablecreate).

    try {

      if (!$client->namespace_exists("test"))
        $client->namespace_create("test");

      $ns = $client->namespace_open("test");

      $if_exists = True;
      $client->table_drop($ns, "Fruits", $if_exists);

      $cf = new \Hypertable_ThriftGen\ColumnFamilySpec(array('name'=> 'genus'));
      $cf_specs["genus"] = $cf;
      $cf = new \Hypertable_ThriftGen\ColumnFamilySpec(array('name'=> 'description'));
      $cf_specs["description"] = $cf;
      $cf = new \Hypertable_ThriftGen\ColumnFamilySpec(array('name'=> 'tag'));
      $cf_specs["tag"] = $cf;

      $schema = new \Hypertable_ThriftGen\Schema(array('column_families'=> $cf_specs));

      $client->table_create($ns, "Fruits", $schema);

      $client->namespace_create("/test/sub");

      $listing = $client->namespace_get_listing($ns);

      foreach ($listing as &$entry) {
        echo "$entry->name";
        if ($entry->is_namespace)
          echo "\t(dir)";
        echo "\n";
      }

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    Fruits
    sub	(dir)

### Convenience APIs

####  set_cells

The following code snippet illustrates how to create [Cell](../reference_manual/thrift_api.md#cell) objects and insert them with the [set_cells](../reference_manual/thrift_api.md#setcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    try {
      $ns = $client->namespace_open("test");

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'apple', 'column_family'=> 'genus'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> 'Malus'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'apple', 'column_family'=> 'description'));
      $value = "The apple is the pomaceous fruit of the apple tree.";
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> $value));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'apple', 'column_family'=> 'tag',
                                                 'column_qualifier' => 'cruncy'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key));
      $cells[] = $cell;

      $client->set_cells($ns, "Fruits", $cells);

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

####  get_cells

The following code snippet illustrates how to fetch cells with the [get_cells](../reference_manual/thrift_api.md#getcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example. It also makes use of the _print_cell_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      $columns = array("description");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('columns'=> $columns));

      $cells = $client->get_cells($ns, "Fruits", $ss);

      foreach ($cells as &$cell) {
        print_cell($cell);
      }

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=apple' column_family='description' column_qualifier=null ' flag=255} value='The apple is the pomaceous fruit of the apple tree.'

####  set_cells_as_arrays

The following code snippet illustrates how to create [CellAsArray](../reference_manual/thrift_api.md#cellasarray) objects and insert them with the [set_cells_as_arrays](../reference_manual/thrift_api.md#setcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example.

    try {
      $ns = $client->namespace_open("test");

      $cell_as_array = array("orange", "genus", "", "Citrus");
      $cells_as_arrays[] = $cell_as_array;

      $value = "The orange (specifically, the sweet orange) is the fruit of the" .
        "citrus species Citrus × sinensis in the family Rutaceae.";
      $cell_as_array = array("orange", "description", "", $value);
      $cells_as_arrays[] = $cell_as_array;

      $cell_as_array = array("orange", "tag", "juicy", "");
      $cells_as_arrays[] = $cell_as_array;

      $client->set_cells_as_arrays($ns, "Fruits", $cells_as_arrays);

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

####  get_cells_as_arrays

The following code snippet illustrates how to fetch cells with the [get_cells_as_arrays](../reference_manual/thrift_api.md#getcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](http://hypertable.com/documentation/developer_guide/c4343/#basics) example and makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      $columns = array("description");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('columns'=> $columns));

      $cells_as_arrays = $client->get_cells_as_arrays($ns, "Fruits", $ss);

      foreach ($cells_as_arrays as &$cell_as_array) {
        print_cell_as_array($cell_as_array);
      }

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {CellAsArray: {Key: row=apple' column_family='description' column_qualifier=null } value='The apple is the pomaceous fruit of the apple tree.'
    {CellAsArray: {Key: row=orange' column_family='description' column_qualifier=null } value='The orange (specifically, the sweet orange) is the fruit of thecitrus species Citrus × sinensis in the family Rutaceae.'

### Creating a table

The following code snippet illustrates how to create a table with the [table_create](../reference_manual/thrift_api.md#tablecreate) API. It introduces the API classes [Schema](../reference_manual/thrift_api.md#schema), [AccessGroupSpec](../reference_manual/thrift_api.md#accessgroupspec), [AccessGroupOptions](../reference_manual/thrift_api.md#accessgroupoptions), [ColumnFamilySpec](../reference_manual/thrift_api.md#columnfamilyspec), and [ColumnFamilyOptions](../reference_manual/thrift_api.md#columnfamilyoptions).

    try {
      $ns = $client->namespace_open("test");

      $ag_specs = array();
      $cf_specs = array();

      // Table defaults
      $ag_defaults = new \Hypertable_ThriftGen\AccessGroupOptions(array('blocksize'=> 65536));
      $cf_defaults = new \Hypertable_ThriftGen\ColumnFamilyOptions(array('max_versions'=> 1));

      // Access group "ag_normal"
      {
        $ag_spec = new \Hypertable_ThriftGen\AccessGroupSpec(array('name'=> 'ag_normal'));
        $cf_options = new \Hypertable_ThriftGen\ColumnFamilyOptions(array('max_versions'=> 2));
        $ag_spec->defaults = $cf_options;
        $ag_specs['ag_normal'] = $ag_spec;
      }

      // Column "a"
      {
        $args = array('name'=> 'a', 'access_group'=> 'ag_normal',
                      'value_index'=> True, 'qualifier_index'=> True);
        $cf_spec = new \Hypertable_ThriftGen\ColumnFamilySpec($args);
        $cf_specs['a'] = $cf_spec;
      }

      // Column "b"
      {
        $cf_options = new \Hypertable_ThriftGen\ColumnFamilyOptions(array('max_versions'=> 3));
        $args = array('name'=> 'b', 'access_group'=> 'ag_normal',
                      'options'=> $cf_options);
        $cf_spec = new \Hypertable_ThriftGen\ColumnFamilySpec($args);
        $cf_specs['b'] = $cf_spec;
      }

      // Access group "ag_fast"
      {
        $args = array('in_memory'=> True, 'blocksize'=> 131072);
        $ag_options = new \Hypertable_ThriftGen\AccessGroupOptions($args);
        $args = array('name'=> 'ag_fast', 'options'=> $ag_options);
        $ag_spec = new \Hypertable_ThriftGen\AccessGroupSpec($args);
        $ag_specs['ag_fast'] = $ag_spec;
      }

      // Column "c"
      {
        $args = array('name'=> 'c', 'access_group'=> 'ag_fast');
        $cf_spec = new \Hypertable_ThriftGen\ColumnFamilySpec($args);
        $cf_specs['c'] = $cf_spec;
      }

      // Access group "ag_secure"
      {
        $args = array('replication'=> 5);
        $ag_options = new \Hypertable_ThriftGen\AccessGroupOptions($args);
        $args = array('name'=> 'ag_secure', 'options'=> $ag_options);
        $ag_spec = new \Hypertable_ThriftGen\AccessGroupSpec($args);
        $ag_specs['ag_secure'] = $ag_spec;
      }

      // Column "d"
      {
        $args = array('name'=> 'd', 'access_group'=> 'ag_secure');
        $cf_spec = new \Hypertable_ThriftGen\ColumnFamilySpec($args);
        $cf_specs['d'] = $cf_spec;
      }

      // Access group "ag_counter"
      {
        $args = array('counter'=> True, 'max_versions'=> 0);
        $cf_options = new \Hypertable_ThriftGen\ColumnFamilyOptions($args);
        $args = array('name'=> 'ag_counter', 'defaults'=> $cf_options);
        $ag_spec = new \Hypertable_ThriftGen\AccessGroupSpec($args);
        $ag_specs['ag_counter'] = $ag_spec;
      }

      // Column "e"
      {
        $args = array('name'=> 'e', 'access_group'=> 'ag_counter');
        $cf_spec = new \Hypertable_ThriftGen\ColumnFamilySpec($args);
        $cf_specs['e'] = $cf_spec;
      }

      // Column "f"
      {
        $cf_options = new \Hypertable_ThriftGen\ColumnFamilyOptions(array('counter'=> False));
        $args = array('name'=> 'f', 'access_group'=> 'ag_counter',
                      'options'=> $cf_options);
        $cf_spec = new \Hypertable_ThriftGen\ColumnFamilySpec($args);
        $cf_specs['f'] = $cf_spec;
      }

      $args = array('access_group_defaults'=> $ag_defaults,
                    'column_family_defaults'=> $cf_defaults,
                    'access_groups'=> $ag_specs, 'column_families'=>$cf_specs);
      $schema = new \Hypertable_ThriftGen\Schema($args);

      $client->table_create($ns, "TestTable", $schema);

      $result = $client->hql_query($ns, "show create table TestTable");

      if (!empty($result->results))
        echo $result->results[0];

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
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

The following code snippet illustrates how to alter a table with the [table_alter](../reference_manual/thrift_api.md#tablealter) API. It assumes that the table _TestTable_ has been created as in the [Creating a table](php.md#creating-a-table) example.

    try {
      $ns = $client->namespace_open("test");

      $schema = $client->get_schema($ns, "TestTable");

      // Rename column "b" to "z"
      {
        $cf_spec = $schema->column_families["b"];
        unset($schema->column_families["b"]);
        $cf_spec->name = "z";
        $schema->column_families["z"] = $cf_spec;
      }

      // Add column "g"
      {
        $args = array('name'=> 'g', 'access_group'=> 'ag_counter');
        $cf_spec = new \Hypertable_ThriftGen\ColumnFamilySpec($args);
        $schema->column_families["g"] = $cf_spec;
      }

      $client->table_alter($ns, "TestTable", $schema);

      $result = $client->hql_query($ns, "show create table TestTable");

      if (!empty($result->results))
        echo $result->results[0];

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
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

The code snippet below illustrates how to insert cells into a table using a mutator. The APIs introduced include [mutator_open](../reference_manual/thrift_api.md#mutatoropen), [mutator_set_cells](../reference_manual/thrift_api.md#mutatorsetcells), [mutator_flush](../reference_manual/thrift_api.md#mutatorflush), and [mutator_close](../reference_manual/thrift_api.md#mutatorclose).

    try {
      $ns = $client->namespace_open("test");

      $mutator = $client->mutator_open($ns, "Fruits", 0, 0);

      // Auto-assign timestamps

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'lemon', 'column_family'=> 'genus'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> 'Citrus'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'lemon', 'column_family'=> 'tag',
                                                 'column_qualifier'=> 'bitter'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'lemon', 'column_family'=> 'description'));
      $value = "The lemon (Citrus × limon) is a small evergreen tree native to Asia.";
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> $value));
      $cells[] = $cell;

      $client->mutator_set_cells($mutator, $cells);
      $client->mutator_flush($mutator);

      // Supply timestamps

      $cells = array();

      $ts = strtotime("2014-06-06 16:27:15") * 1000000000;
      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'mango', 'column_family'=> 'genus',
                                                 'timestamp'=> $ts));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> 'Mangifera'));
      $cells[] = $cell;

      $ts = strtotime("2014-06-06 16:27:15") * 1000000000;
      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'mango', 'column_family'=> 'tag',
                                                 'column_qualifier'=> 'sweet',
                                                 'timestamp'=> $ts));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key));
      $cells[] = $cell;

      $ts = strtotime("2014-06-06 16:27:15") * 1000000000;
      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'mango', 'column_family'=> 'description',
                                                 'timestamp'=> $ts));
      $value = "Mango is one of the delicious seasonal fruits grown in the tropics.";
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> $value));
      $cells[] = $cell;

      $ts = strtotime("2014-06-06 16:27:16") * 1000000000;
      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'mango', 'column_family'=> 'description',
                                                 'timestamp'=> $ts));
      $value = "The mango is a juicy stone fruit belonging to the genus " .
        "Mangifera, consisting of numerous tropical fruiting trees, that are " .
        "cultivated mostly for edible fruits.";
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> $value));
      $cells[] = $cell;

      $client->mutator_set_cells($mutator, $cells);
      $client->mutator_flush($mutator);

      // Delete cells

      $cells = array();

      $args = array('row'=> 'apple',
                    'flag'=> \Hypertable_ThriftGen\KeyFlag::DELETE_ROW);
      $key = new \Hypertable_ThriftGen\Key($args);
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key));
      $cells[] = $cell;

      $ts = strtotime("2014-06-06 16:27:15") * 1000000000;
      $args = array('row'=> 'mango', 'column_family'=> 'description',
                    'timestamp'=> $ts,
                    'flag'=> \Hypertable_ThriftGen\KeyFlag::DELETE_CELL);
      $key = new \Hypertable_ThriftGen\Key($args);
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key));
      $cells[] = $cell;

      $client->mutator_set_cells($mutator, $cells);
      $client->mutator_flush($mutator);
      $client->mutator_close($mutator);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

### Scanner

The following examples illustrate how to query a table using a scanner. The APIs introduced include the [scanner_open](../reference_manual/thrift_api.md#scanneropen), [scanner_get_cells](../reference_manual/thrift_api.md#scannergetcells), and [scanner_close](../reference_manual/thrift_api.md#scannerclose) functions, and the [ScanSpec](../reference_manual/thrift_api.md#scanspec) and [RowInterval](../reference_manual/thrift_api.md#rowinterval) classes. It makes use of the _print_cell_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

####  Full table scan

The following code illustrates how to do a full table scan using the scanner APIs.

    try {
      $ns = $client->namespace_open("test");

      $ss = new \Hypertable_ThriftGen\ScanSpec();

      $scanner = $client->scanner_open($ns, "Fruits", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=lemon' column_family='description' column_qualifier=null ' flag=255} value='The lemon (Citrus × limon) is a small evergreen tree native to Asia.'
    {Cell: {Key: row=lemon' column_family='genus' column_qualifier=null ' flag=255} value='Citrus'
    {Cell: {Key: row=lemon' column_family='tag' column_qualifier='bitter' ' flag=255} value=null
    {Cell: {Key: row=mango' column_family='description' column_qualifier=null ' flag=255} value='The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.'
    {Cell: {Key: row=mango' column_family='genus' column_qualifier=null ' flag=255} value='Mangifera'
    {Cell: {Key: row=mango' column_family='tag' column_qualifier='sweet' ' flag=255} value=null
    {Cell: {Key: row=orange' column_family='description' column_qualifier=null ' flag=255} value='The orange (specifically, the sweet orange) is the fruit of thecitrus species Citrus × sinensis in the family Rutaceae.'
    {Cell: {Key: row=orange' column_family='genus' column_qualifier=null ' flag=255} value='Citrus'
    {Cell: {Key: row=orange' column_family='tag' column_qualifier='juicy' ' flag=255} value=null

####  Restricted scan with ScanSpec

The following code illustrates how to do a table scan using a ScanSpec. It makes use of the _print_cell_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      // Row range [cherry..orange)
      $args = array('start_row'=> 'lemon', 'start_inclusive'=> True,
                    'end_row'=> 'orange', 'end_inclusive'=> False);
      $ri = new \Hypertable_ThriftGen\RowInterval($args);
      $row_intervals = array($ri);

      // Columns 'genus', 'tag:bitter', and 'tag:sweet'
      $columns = array('genus', 'tag:bitter', 'tag:sweet');

      $args = array('row_intervals'=> $row_intervals, 'columns'=> $columns,
                    'versions' => 1);
      $ss = new \Hypertable_ThriftGen\ScanSpec($args);

      $scanner = $client->scanner_open($ns, "Fruits", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=lemon' column_family='genus' column_qualifier=null ' flag=255} value='Citrus'
    {Cell: {Key: row=lemon' column_family='tag' column_qualifier='bitter' ' flag=255} value=null
    {Cell: {Key: row=mango' column_family='genus' column_qualifier=null ' flag=255} value='Mangifera'
    {Cell: {Key: row=mango' column_family='tag' column_qualifier='sweet' ' flag=255} value=null

### HQL

####  hql_query

The following code illustrates how to issue HQL commands with the [hql_query](../reference_manual/thrift_api.md#hqlquery) API. It also introduces the [HqlResult](../reference_manual/thrift_api.md#hqlresult) class. It makes use of the _print_cell_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      $result = $client->hql_query($ns, "GET LISTING");

      foreach ($result->results as $line)
        echo "$line\n";

      $result = $client->hql_query($ns, "SELECT * FROM Fruits WHERE ROW = 'lemon'");

      foreach ($result->cells as $cell)
        print_cell($cell);

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    Fruits
    TestTable
    ^TestTable
    ^^TestTable
    sub	(namespace)
    {Cell: {Key: row=lemon' column_family='description' column_qualifier=null ' flag=255} value='The lemon (Citrus × limon) is a small evergreen tree native to Asia.'
    {Cell: {Key: row=lemon' column_family='genus' column_qualifier=null ' flag=255} value='Citrus'
    {Cell: {Key: row=lemon' column_family='tag' column_qualifier='bitter' ' flag=255} value=null

####  hql_query_as_arrays

The following code illustrates how to issue an HQL query with the [hql_query_as_arrays](../reference_manual/thrift_api.md#hqlqueryasarrays) API. It also introduces the [HqlResultAsArrays](../reference_manual/thrift_api.md#hqlresultasarrays) class and makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      $command = "SELECT * FROM Fruits WHERE ROW = 'lemon'";
      $result = $client->hql_query_as_arrays($ns, $command);

      foreach ($result->cells as &$cell_as_array) {
        print_cell_as_array($cell_as_array);
      }

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {CellAsArray: {Key: row=lemon' column_family='description' column_qualifier=null } value='The lemon (Citrus × limon) is a small evergreen tree native to Asia.'
    {CellAsArray: {Key: row=lemon' column_family='genus' column_qualifier=null } value='Citrus'
    {CellAsArray: {Key: row=lemon' column_family='tag' column_qualifier='bitter' } value=null

####  hql_exec (mutator)

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a mutator.

    try {
      $ns = $client->namespace_open("test");

      $command = "INSERT INTO Fruits VALUES ('strawberry', 'genus', 'Fragaria')," .
        " ('strawberry', 'tag:fibrous', ''), ('strawberry', 'description', 'The" .
        " garden strawberry is a widely grown hybrid species of the genus " .
        "Fragaria')";
      $result = $client->hql_exec($ns, $command, True, False);

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'pineapple', 'column_family'=> 'genus'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> 'Ananas'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'pineapple', 'column_family'=> 'tag',
                                                 'column_qualifier'=> 'acidic'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'pineapple', 'column_family'=> 'description'));
      $value = "The pineapple (Ananas comosus) is a tropical plant with edible " .
        "multiple fruit consisting of coalesced berries.";
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> $value));
      $cells[] = $cell;

      $client->mutator_set_cells($result->mutator, $cells);
      $client->mutator_flush($result->mutator);
      $client->mutator_close($result->mutator);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

####  hql_exec (scanner}

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a scanner. It makes use of the _print_cell_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      $result = $client->hql_exec($ns, "SELECT * from Fruits", False, True);

      do {
        $cells = $client->scanner_get_cells($result->scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($result->scanner);

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=lemon' column_family='description' column_qualifier=null ' flag=255} value='The lemon (Citrus × limon) is a small evergreen tree native to Asia.'
    {Cell: {Key: row=lemon' column_family='genus' column_qualifier=null ' flag=255} value='Citrus'
    {Cell: {Key: row=lemon' column_family='tag' column_qualifier='bitter' ' flag=255} value=null
    {Cell: {Key: row=mango' column_family='description' column_qualifier=null ' flag=255} value='The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees, that are cultivated mostly for edible fruits.'
    {Cell: {Key: row=mango' column_family='genus' column_qualifier=null ' flag=255} value='Mangifera'
    {Cell: {Key: row=mango' column_family='tag' column_qualifier='sweet' ' flag=255} value=null
    {Cell: {Key: row=orange' column_family='description' column_qualifier=null ' flag=255} value='The orange (specifically, the sweet orange) is the fruit of thecitrus species Citrus × sinensis in the family Rutaceae.'
    {Cell: {Key: row=orange' column_family='genus' column_qualifier=null ' flag=255} value='Citrus'
    {Cell: {Key: row=orange' column_family='tag' column_qualifier='juicy' ' flag=255} value=null
    {Cell: {Key: row=pineapple' column_family='description' column_qualifier=null ' flag=255} value='The pineapple (Ananas comosus) is a tropical plant with edible multiple fruit consisting of coalesced berries.'
    {Cell: {Key: row=pineapple' column_family='genus' column_qualifier=null ' flag=255} value='Ananas'
    {Cell: {Key: row=pineapple' column_family='tag' column_qualifier='acidic' ' flag=255} value=null
    {Cell: {Key: row=strawberry' column_family='description' column_qualifier=null ' flag=255} value='The garden strawberry is a widely grown hybrid species of the genus Fragaria'
    {Cell: {Key: row=strawberry' column_family='genus' column_qualifier=null ' flag=255} value='Fragaria'
    {Cell: {Key: row=strawberry' column_family='tag' column_qualifier='fibrous' ' flag=255} value=null

### Secondary Indices

This section describes how to query tables using secondary indices. APIs introduced include the [ColumnPredicate](../reference_manual/thrift_api.md#column_predicate) class and the _column_predicates_ and the _and_column_predicates_ members of the [ScanSpec](../reference_manual/thrift_api.md#scanspec) class. The code examples make use of the _print_cell_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions). The examples assume that the table products has been created and loaded with the following HQL commands.

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
      $ns = $client->namespace_open("test");

      $column_predicates = array();
      $args = array('column_family'=> 'section',
                    'operation'=> \Hypertable_ThriftGen\ColumnPredicateOperation::EXACT_MATCH,
                    'value'=> 'books');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('column_predicates'=> $column_predicates,
                                                     'columns'=> $columns));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=0307743659' column_family='title' column_qualifier=null ' flag=255} value='The Shining Mass Market Paperback'
    {Cell: {Key: row=0321321928' column_family='title' column_qualifier=null ' flag=255} value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]'
    {Cell: {Key: row=0321776402' column_family='title' column_qualifier=null ' flag=255} value='C++ Primer Plus (6th Edition) (Developer's Library)'

####  Value index (exact match with qualifier)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title FROM products WHERE info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::EXACT_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'actor',
                    'operation'=> $operation, 'value'=> 'Jack Nicholson');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('column_predicates'=> $column_predicates,
                                                     'columns'=> $columns));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=B00002VWE0' column_family='title' column_qualifier=null ' flag=255} value='Five Easy Pieces (1970)'
    {Cell: {Key: row=B002VWNIDG' column_family='title' column_qualifier=null ' flag=255} value='The Shining (1980)'

####  Value index (prefix match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =^ 'Addison-Wesley';

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::PREFIX_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'publisher',
                    'operation'=> $operation, 'value'=> 'Addison-Wesley');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title", "info:publisher");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('column_predicates'=> $column_predicates,
                                                     'columns'=> $columns));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=0321321928' column_family='title' column_qualifier=null ' flag=255} value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]'
    {Cell: {Key: row=0321321928' column_family='info' column_qualifier='publisher' ' flag=255} value='Addison-Wesley Professional; 1 edition (March 10, 2005)'
    {Cell: {Key: row=0321776402' column_family='title' column_qualifier=null ' flag=255} value='C++ Primer Plus (6th Edition) (Developer's Library)'
    {Cell: {Key: row=0321776402' column_family='info' column_qualifier='publisher' ' flag=255} value='Addison-Wesley Professional; 6 edition (October 28, 2011)'

####  Value index (regex match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =~ /^Addison-Wesley/;

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::REGEX_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'publisher',
                    'operation'=> $operation, 'value'=> '^Addison-Wesley');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title", "info:publisher");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('column_predicates'=> $column_predicates,
                                                     'columns'=> $columns));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=0321321928' column_family='title' column_qualifier=null ' flag=255} value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]'
    {Cell: {Key: row=0321321928' column_family='info' column_qualifier='publisher' ' flag=255} value='Addison-Wesley Professional; 1 edition (March 10, 2005)'
    {Cell: {Key: row=0321776402' column_family='title' column_qualifier=null ' flag=255} value='C++ Primer Plus (6th Edition) (Developer's Library)'
    {Cell: {Key: row=0321776402' column_family='info' column_qualifier='publisher' ' flag=255} value='Addison-Wesley Professional; 6 edition (October 28, 2011)'

####  Qualifier index (exists)

The following HQL query which leverages the qualifier index of the _info_ column:

    SELECT title FROM products WHERE Exists(info:studio);

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'studio',
                    'operation'=> $operation);
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('column_predicates'=> $column_predicates,
                                                     'columns'=> $columns));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=B00002VWE0' column_family='title' column_qualifier=null ' flag=255} value='Five Easy Pieces (1970)'
    {Cell: {Key: row=B000Q66J1M' column_family='title' column_qualifier=null ' flag=255} value='2001: A Space Odyssey [Blu-ray]'
    {Cell: {Key: row=B002VWNIDG' column_family='title' column_qualifier=null ' flag=255} value='The Shining (1980)'

####  Qualifier index (exists regex prefix match)

The following HQL query which leverages the qualifier index of the _category_ column:

    SELECT title FROM products WHERE Exists(category:/^\/Movies/);

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_REGEX_MATCH;
      $args = array('column_family'=> 'category', 'column_qualifier'=> '^/Movies',
                    'operation'=> $operation);
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('column_predicates'=> $column_predicates,
                                                     'columns'=> $columns));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=B00002VWE0' column_family='title' column_qualifier=null ' flag=255} value='Five Easy Pieces (1970)'
    {Cell: {Key: row=B000Q66J1M' column_family='title' column_qualifier=null ' flag=255} value='2001: A Space Odyssey [Blu-ray]'
    {Cell: {Key: row=B002VWNIDG' column_family='title' column_qualifier=null ' flag=255} value='The Shining (1980)'

####  Value index (OR query)

The following HQL query performs a boolean _OR_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen P/ OR info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::REGEX_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'author',
                    'operation'=> $operation, 'value'=> '^Stephen P');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::PREFIX_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'publisher',
                    'operation'=> $operation, 'value'=> 'Anchor');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('column_predicates'=> $column_predicates,
                                                     'columns'=> $columns));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=0307743659' column_family='title' column_qualifier=null ' flag=255} value='The Shining Mass Market Paperback'
    {Cell: {Key: row=0321776402' column_family='title' column_qualifier=null ' flag=255} value='C++ Primer Plus (6th Edition) (Developer's Library)'

####  Value index (AND query)

The following HQL query performs a boolean _AND_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::REGEX_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'author',
                    'operation'=> $operation, 'value'=> '^Stephen [PK]');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::PREFIX_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'publisher',
                    'operation'=> $operation, 'value'=> 'Anchor');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('column_predicates'=> $column_predicates,
                                                     'columns'=> $columns,
                                                     'and_column_predicates'=> True));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=0307743659' column_family='title' column_qualifier=null ' flag=255} value='The Shining Mass Market Paperback'

####  Value index (AND row interval)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW interval:

    SELECT title
      FROM products
      WHERE ROW > 'B00002VWE0' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      // ROW > 'B00002VWE0'
      $args = array('start_row'=> 'B00002VWE0', 'start_inclusive'=> False);
      $ri = new \Hypertable_ThriftGen\RowInterval($args);
      $row_intervals = array($ri);

      // info:actor = 'Jack Nicholson'
      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::EXACT_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'actor',
                    'operation'=> $operation, 'value'=> 'Jack Nicholson');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('row_intervals'=> $row_intervals,
                                                     'column_predicates'=> $column_predicates,
                                                     'columns'=> $columns,
                                                     'and_column_predicates'=> True));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=B002VWNIDG' column_family='title' column_qualifier=null ' flag=255} value='The Shining (1980)'

####  Value index (AND row prefix)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW prefix interval:

    SELECT title
      FROM products
      WHERE ROW =^ 'B' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
      $ns = $client->namespace_open("test");

      // ROW > 'B00002VWE0'
      $args = array('start_row'=> 'B', 'start_inclusive'=> True,
                    'end_row'=> 'C', 'end_inclusive'=> False);
      $ri = new \Hypertable_ThriftGen\RowInterval($args);
      $row_intervals = array($ri);

      // info:actor = 'Jack Nicholson'
      $column_predicates = array();
      $operation = \Hypertable_ThriftGen\ColumnPredicateOperation::EXACT_MATCH |
        \Hypertable_ThriftGen\ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
      $args = array('column_family'=> 'info', 'column_qualifier'=> 'actor',
                    'operation'=> $operation, 'value'=> 'Jack Nicholson');
      $column_predicate = new \Hypertable_ThriftGen\ColumnPredicate($args);
      $column_predicates[] = $column_predicate;

      $columns = array("title");

      $ss = new \Hypertable_ThriftGen\ScanSpec(array('row_intervals'=> $row_intervals,
                                                     'column_predicates'=> $column_predicates,
                                                     'columns'=> $columns,
                                                     'and_column_predicates'=> True));

      $scanner = $client->scanner_open($ns, "products", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=B00002VWE0' column_family='title' column_qualifier=null ' flag=255} value='Five Easy Pieces (1970)'
    {Cell: {Key: row=B002VWNIDG' column_family='title' column_qualifier=null ' flag=255} value='The Shining (1980)'

### Asynchronous APIs

This section describes how to use the asynchronous APIs. The examples assume that tables _Profile_ and _Session_ are created and loaded with the following HQL commands.

    CREATE TABLE Profile (info, last_access MAX_VERSIONS 1);

    CREATE TABLE Session (user_id, page_hit);

    INSERT INTO Profile
      VALUES ('1', 'info:name', 'Joe'), ('2', 'info:name', 'Sue');

####  Async mutator

The code snippet below illustrates how to insert cells into multiple tables simultaneously using an asynchronous mutator. The APIs introduced include the [future_open](../reference_manual/thrift_api.md#futureopen), [future_get_result](../reference_manual/thrift_api.md#futuregetresult), [future_close](../reference_manual/thrift_api.md#futureclose), [async_mutator_open](../reference_manual/thrift_api.md#asyncmutatoropen), [async_mutator_set_cells](../reference_manual/thrift_api.md#asyncmutatorsetcells), [async_mutator_flush](../reference_manual/thrift_api.md#asyncmutatorflush), and [async_mutator_close](../reference_manual/thrift_api.md#asyncmutatorclose) functions and the [Result](../reference_manual/thrift_api.md#result) class.

    try {
      $ns = $client->namespace_open("test");

      $ff = $client->future_open(0);
      $profile_mutator = $client->async_mutator_open($ns, "Profile", $ff, 0);
      $session_mutator = $client->async_mutator_open($ns, "Session", $ff, 0);

      $cells = array();

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '1', 'column_family'=> 'last_access'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '2014-06-13 16:06:09'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '2', 'column_family'=> 'last_access'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '2014-06-13 16:06:10'));
      $cells[] = $cell;

      $client->async_mutator_set_cells($profile_mutator, $cells);

      $cells = array();

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '0001-200238',
                                                 'column_family'=> 'user_id'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '0001-200238',
                                                 'column_family'=> 'page_hit'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '/index.html'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '0002-383049',
                                                 'column_family'=> 'user_id'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '0002-383049',
                                                 'column_family'=> 'page_hit'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '/foo/bar.html'));
      $cells[] = $cell;

      $client->async_mutator_set_cells($session_mutator, $cells);

      $client->async_mutator_flush($profile_mutator);
      $client->async_mutator_flush($session_mutator);

      $result_count = 0;
      while (True) {
        $result = $client->future_get_result($ff, 0);
        if ($result->is_empty)
          break;
        $result_count++;
        if ($result->is_error) {
          echo "Async mutator error:  " . $result->error_msg . "\n";
          exit(1);
        }
        if ($result->id == $profile_mutator)
          echo "Result is from Profile mutation\n";
        else if ($result->id == $session_mutator)
          echo "Result is from Session mutation\n";
      }

      echo "result count = " . $result_count . "\n";

      $client->async_mutator_close($profile_mutator);
      $client->async_mutator_close($session_mutator);
      $client->future_close($ff);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile mutation
    Result is from Session mutation
    result count = 2

####  Async scanner (Result)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [Result](../reference_manual/thrift_api.md#result) object. The APIs introduced include the [async_scanner_open](../reference_manual/thrift_api.md#asyncscanneropen) and [async_scanner_close](../reference_manual/thrift_api.md#asyncscannerclose) functions. It also makes use of the _print_cell_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      $ff = $client->future_open(0);

      // SELECT * from Profile WHERE ROW = "1"
      $args = array('start_row'=> '1', 'start_inclusive'=> True,
                    'end_row'=> '1', 'end_inclusive'=> True);
      $ri = new \Hypertable_ThriftGen\RowInterval($args);
      $row_intervals = array($ri);
      $ss = new \Hypertable_ThriftGen\ScanSpec(array('row_intervals'=> $row_intervals));
      $profile_scanner = $client->async_scanner_open($ns, "Profile", $ff, $ss);

      // SELECT * from Session WHERE ROW = "0001-200238"
      $args = array('start_row'=> '0001-200238', 'start_inclusive'=> True,
                    'end_row'=> '0001-200238', 'end_inclusive'=> True);
      $ri = new \Hypertable_ThriftGen\RowInterval($args);
      $row_intervals = array($ri);
      $ss = new \Hypertable_ThriftGen\ScanSpec(array('row_intervals'=> $row_intervals));
      $session_scanner = $client->async_scanner_open($ns, "Session", $ff, $ss);

      while (True) {

        $result = $client->future_get_result($ff, 0);

        if ($result->is_empty)
          break;

        if ($result->is_error) {
          echo "Async scanner error:  " . $result->error_msg . "\n";
          exit(1);
        }

        assert($result->is_scan);
        assert($result->id == $profile_scanner || $result->id == $session_scanner);

        if ($result->id == $profile_scanner)
          echo "Result is from Profile scan\n";
        else if ($result->id == $session_scanner)
          echo "Result is from Session scan\n";

        foreach ($result->cells as &$cell) {
          print_cell($cell);
        }
      }

      $client->async_scanner_close($profile_scanner);
      $client->async_scanner_close($session_scanner);
      $client->future_close($ff);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile scan
    {Cell: {Key: row=1' column_family='info' column_qualifier='name' ' flag=255} value='Joe'
    {Cell: {Key: row=1' column_family='last_access' column_qualifier=null ' flag=255} value='2014-06-13 16:06:09'
    Result is from Session scan
    {Cell: {Key: row=0001-200238' column_family='user_id' column_qualifier=null ' flag=255} value=null
    {Cell: {Key: row=0001-200238' column_family='page_hit' column_qualifier=null ' flag=255} value='/index.html'

####  Async scanner (ResultAsArrays)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultAsArrays](../reference_manual/thrift_api.md#resultasarrays) object. This example introduces the [future_get_result_as_arrays](../reference_manual/thrift_api.md#futuregetresultasarrays) API and makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      $ff = $client->future_open(0);

      // SELECT * from Profile WHERE ROW = "1"
      $args = array('start_row'=> '1', 'start_inclusive'=> True,
                    'end_row'=> '1', 'end_inclusive'=> True);
      $ri = new \Hypertable_ThriftGen\RowInterval($args);
      $row_intervals = array($ri);
      $ss = new \Hypertable_ThriftGen\ScanSpec(array('row_intervals'=> $row_intervals));
      $profile_scanner = $client->async_scanner_open($ns, "Profile", $ff, $ss);

      // SELECT * from Session WHERE ROW = "0001-200238"
      $args = array('start_row'=> '0001-200238', 'start_inclusive'=> True,
                    'end_row'=> '0001-200238', 'end_inclusive'=> True);
      $ri = new \Hypertable_ThriftGen\RowInterval($args);
      $row_intervals = array($ri);
      $ss = new \Hypertable_ThriftGen\ScanSpec(array('row_intervals'=> $row_intervals));
      $session_scanner = $client->async_scanner_open($ns, "Session", $ff, $ss);

      while (True) {

        $result_as_arrays = $client->future_get_result_as_arrays($ff, 0);

        if ($result_as_arrays->is_empty)
          break;

        if ($result_as_arrays->is_error) {
          echo "Async scanner error:  " . $result_as_arrays->error_msg . "\n";
          exit(1);
        }

        assert($result_as_arrays->is_scan);
        assert($result_as_arrays->id == $profile_scanner ||
               $result_as_arrays->id == $session_scanner);

        if ($result_as_arrays->id == $profile_scanner)
          echo "Result is from Profile scan\n";
        else if ($result_as_arrays->id == $session_scanner)
          echo "Result is from Session scan\n";

        foreach ($result_as_arrays->cells as &$cell_as_array) {
          print_cell_as_array($cell_as_array);
        }
      }

      $client->async_scanner_close($profile_scanner);
      $client->async_scanner_close($session_scanner);
      $client->future_close($ff);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    Result is from Profile scan
    {CellAsArray: {Key: row=1' column_family='info' column_qualifier='name' } value='Joe'
    {CellAsArray: {Key: row=1' column_family='last_access' column_qualifier=null } value='2014-06-13 16:06:09'
    Result is from Session scan
    {CellAsArray: {Key: row=0001-200238' column_family='user_id' column_qualifier=null } value=null
    {CellAsArray: {Key: row=0001-200238' column_family='page_hit' column_qualifier=null } value='/index.html'

### Atomic counters

This section describes how to use atomic counters. The examples assume that a  _Hits_ table has been created with the following HQL command.

    CREATE TABLE Hits (count COUNTER);

####  Increment

The code snippet below illustrates how to increment per-second hit counts for pages of a website. It makes use of the _print_cell_ function defined in [Appendix - helper functions](php.md#appendix---helper-functions).

    try {
      $ns = $client->namespace_open("test");

      $mutator = $client->mutator_open($ns, "Hits", 0, 0);

      $cells = array();

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:18'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:18'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/foo/bar.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:18'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/foo/bar.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:18'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/foo/bar.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:18'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:19'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:19'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:19'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:19'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/foo/bar.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:19'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '1'));
      $cells[] = $cell;

      $client->mutator_set_cells($mutator, $cells);
      $client->mutator_flush($mutator);

      $ss = new \Hypertable_ThriftGen\ScanSpec();

      $scanner = $client->scanner_open($ns, "Hits", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=/foo/bar.html' column_family='count' column_qualifier='2014-06-14 07:31:18' ' flag=255} value='3'
    {Cell: {Key: row=/foo/bar.html' column_family='count' column_qualifier='2014-06-14 07:31:19' ' flag=255} value='1'
    {Cell: {Key: row=/index.html' column_family='count' column_qualifier='2014-06-14 07:31:18' ' flag=255} value='2'
    {Cell: {Key: row=/index.html' column_family='count' column_qualifier='2014-06-14 07:31:19' ' flag=255} value='4'

####  Reset and subtraction

The code snippet below illustrates how to reset and subtract from counters.

    try {
      $ns = $client->namespace_open("test");

      $mutator = $client->mutator_open($ns, "Hits", 0, 0);

      $cells = array();

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:18'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '=0'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:18'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '7'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/foo/bar.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:18'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '-1'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/index.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:19'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '-2'));
      $cells[] = $cell;

      $key = new \Hypertable_ThriftGen\Key(array('row'=> '/foo/bar.html',
                                                 'column_family'=> 'count',
                                                 'column_qualifier'=> '2014-06-14 07:31:19'));
      $cell = new \Hypertable_ThriftGen\Cell(array('key' => $key, 'value'=> '=19'));
      $cells[] = $cell;

      $client->mutator_set_cells($mutator, $cells);
      $client->mutator_flush($mutator);

      $ss = new \Hypertable_ThriftGen\ScanSpec();

      $scanner = $client->scanner_open($ns, "Hits", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);
      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    {Cell: {Key: row=/foo/bar.html' column_family='count' column_qualifier='2014-06-14 07:31:18' ' flag=255} value='2'
    {Cell: {Key: row=/foo/bar.html' column_family='count' column_qualifier='2014-06-14 07:31:19' ' flag=255} value='19'
    {Cell: {Key: row=/index.html' column_family='count' column_qualifier='2014-06-14 07:31:18' ' flag=255} value='7'
    {Cell: {Key: row=/index.html' column_family='count' column_qualifier='2014-06-14 07:31:19' ' flag=255} value='2'

### Creating unique keys

This section illustrates how to create unique keys using the [create_cell_unique](../reference_manual/thrift_api.md#createcellunique) API. The example show how you can create unique user IDs for an application. The code assumes that a _User_ table has been created with the following HQL command.

    CREATE TABLE User (info, id TIME_ORDER desc MAX_VERSIONS 1);

The example code snippet is as follows.

    try {
      $ns = $client->namespace_open("test");

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'joe1987',
                                                 'column_family'=> 'id'));
      $ret = $client->create_cell_unique($ns, "User", $key, "");

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'mary.bellweather',
                                                 'column_family'=> 'id'));
      $ret = $client->create_cell_unique($ns, "User", $key, "");

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

    try {
      $ns = $client->namespace_open("test");

      $key = new \Hypertable_ThriftGen\Key(array('row'=> 'joe1987',
                                                 'column_family'=> 'id'));
      $ret = $client->create_cell_unique($ns, "User", $key, "");

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      if ($e->code == 48) { // ALREADY_EXISTS
        echo "User name '" . $key->row . "' is already taken\n";
        $client->namespace_close($ns);
      }
      else {
        echo "error: $e->message\n";
        exit(1);
      }
    }

    try {

      $ns = $client->namespace_open("test");

      $ss = new \Hypertable_ThriftGen\ScanSpec();

      $scanner = $client->scanner_open($ns, "User", $ss);

      do {
        $cells = $client->scanner_get_cells($scanner);
        foreach ($cells as &$cell) {
          print_cell($cell);
        }
      } while (!empty($cells));

      $client->scanner_close($scanner);

      $client->namespace_close($ns);
    }
    catch (\Hypertable_ThriftGen\ClientException $e) {
      echo "error: $e->message\n";
      exit(1);
    }

The following is example output produced by the above code snippet.

    User name 'joe1987' is already taken
    {Cell: {Key: row=joe1987' column_family='id' column_qualifier=null ' flag=255} value='41cad959-10dc-4f67-98b0-ad6808c2c9c9'
    {Cell: {Key: row=mary.bellweather' column_family='id' column_qualifier=null ' flag=255} value='5027ff9a-3b15-44f5-8302-16367bdb7335'

### Appendix - helper functions

The following helper functions are used in the examples in this document.

    function print_cell( &$cell ) {
      echo "{Cell: {Key: row=" . $cell->key->row . "' column_family='" .
        $cell->key->column_family . "' column_qualifier=";
      if (!empty($cell->key->column_qualifier))
        echo "'" . $cell->key->column_qualifier . "'";
      else
        echo "null";
      echo " ' flag=" . $cell->key->flag . "} value=";
      if (!empty($cell->value))
        echo "'" . $cell->value . "'";
      else
        echo "null";
      echo "\n";
    }

    function print_cell_as_array( &$cell_as_array ) {
      echo "{CellAsArray: {Key: row=" . $cell_as_array[0] . "' column_family='" .
        $cell_as_array[1] . "' column_qualifier=";
      if (!empty($cell_as_array[2]))
        echo "'" . $cell_as_array[2] . "'";
      else
        echo "null";
      echo " } value=";
      if (!empty($cell_as_array[3]))
        echo "'" . $cell_as_array[3] . "'";
      else
        echo "null";
      echo "\n";
    }
