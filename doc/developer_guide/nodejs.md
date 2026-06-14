# Node.js

## Table of Contents

### Introduction

This document presents example Node.js code that excercises the Thrift API. To quickly get Hypertable up and running on a single machine so that you can try out these examples, see [Hypertable Standalone Installation](../installation/quick_start_standalone.md). The source code for all of the examples in this document, along with the build and run scripts, can be found in the following archive:

[hypertable_api_example.tgz](http://hypertable.com/pub/hypertable_api_example.tgz)

### Environment setup and running

The following bash script illustrates how to setup an enviroment and run a Hypertable Node.js thrift client program.

    HYPERTABLE_HOME=/opt/hypertable/current

    env NODE_PATH=$HYPERTABLE_HOME/lib/js/node/node_modules \
      $HYPERTABLE_HOME/sbin/node ./hypertable_api_test.js

### Program Boilerplate

The following require statements are assumed in the code examples in this document.

    'use strict';
    var assert = require('assert');
    var async = require('async');
    var util = require('util');
    var hypertable = require('hypertable');
    var Timestamp = require('hypertable/timestamp');

### Creating a Thrift Client

All of the examples in this document reference a pointer to a Thrift client object. The following code snippet illustrates how to create a Thrift client object connected to a ThriftBroker listening on the default port (15867) on localhost. To change the ThriftBroker location, just change "localhost" to the domain name of the machine on which the ThriftBroker is running.

    var client = new hypertable.ThriftClient("localhost", 15867);

### Basics

The following code snippet illustrates the basics of working with namespaces and tables. The APIs introduced include [namespace_exists](../reference_manual/thrift_api.md#namespaceexists), [namespace_create](../reference_manual/thrift_api.md#namespacecreate), [namespace_open](../reference_manual/thrift_api.md#namespaceopen), [namespace_get_listing](../reference_manual/thrift_api.md#namespacegetlisting), [namespace_close](../reference_manual/thrift_api.md#namespaceclose), [table_drop](../reference_manual/thrift_api.md#tabledrop), and [table_create](../reference_manual/thrift_api.md#tablecreate).

    var ns;
    async.series([
      function createTestNamespace (callback) {
        client.namespace_exists('test', function (error, exists) {
            if (!exists)
              client.namespace_create('test', callback);
            else
              callback(error);
          });
      },
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function dropFruitsTable (callback) {
        var ifExists = true;
        client.table_drop(ns, 'Fruits', ifExists, callback);
      },
      function createFruitsTable (callback) {
        var columnFamilies = {};
        columnFamilies.genus = new hypertable.ColumnFamilySpec({name: 'genus'});
        columnFamilies.description = new hypertable.ColumnFamilySpec({name: 'description'});
        columnFamilies.tag = new hypertable.ColumnFamilySpec({name: 'tag'});
        var schema = new hypertable.Schema({column_families: columnFamilies});
        client.table_create(ns, 'Fruits', schema, callback);
      },
      function createTestSubNamespace (callback) {
        client.namespace_create('/test/sub', callback);
      },
      function displayTestListing (callback) {
        client.namespace_get_listing(ns, function (error, listing) {
            for (var j = 0; j < listing.length; j++) {
              if (listing[j].is_namespace)
                console.log(util.format('%s\t(dir)', listing[j].name));
              else
                console.log(util.format('%s', listing[j].name));
            }
            callback(error);
          });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Fruits
    sub	(dir)

### Convenience APIs

####  set_cells

The following code snippet illustrates how to create [Cell](../reference_manual/thrift_api.md#cell) objects and insert them with the [set_cells](../reference_manual/thrift_api.md#setcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](nodejs.md#basics) example.

    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function setCells (callback) {
        var key, cell;
        var cells = [];

        key = new hypertable.Key({row: 'apple', column_family: 'genus'});
        cell = new hypertable.Cell({key: key, value: 'Malus'});
        cells.push(cell);

        key = new hypertable.Key({row: 'apple', column_family: 'description'});
        cell = new hypertable.Cell({key: key,
                                    value: 'The apple is the pomaceous fruit of the apple tree.'});
        cells.push(cell);

        key = new hypertable.Key({row: 'apple', column_family: 'tag', column_qualifier: 'crunchy'});
        cell = new hypertable.Cell({key: key});
        cells.push(cell);

        client.set_cells(ns, 'Fruits', cells,
                         function (error) { callback(error); });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

####  get_cells

The following code snippet illustrates how to fetch cells with the [get_cells](../reference_manual/thrift_api.md#getcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](nodejs.md#basics) example.

    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function getCells (callback) {
        client.get_cells(ns, 'Fruits', new ScanSpec({columns: ['description']}),
                         function (error, cells) {
            if (!error) {
              for (var j = 0; j < cells.length; j++)
                console.log(cells[j].toString());
            }
            callback(error);
          });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='apple', column_family='description', column_qualifier='', timestamp=1427995329442597002, revision=1427995329442597002, flag=255), value='The apple is the pomaceous fruit of the apple tree.')

####  set_cells_as_arrays

The following code snippet illustrates how to create [CellAsArray](../reference_manual/thrift_api.md#cellasarray) objects and insert them with the [set_cells_as_arrays](../reference_manual/thrift_api.md#setcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](nodejs.md#basics) example.

    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function setCellsAsArrays (callback) {
        var cell_as_array;
        var cells_as_arrays = [];

        cell_as_array = ['orange', 'genus', '', 'Citrus'];
        cells_as_arrays.push(cell_as_array);

        cell_as_array = ['orange', 'description', '',
                         'The orange (specifically, the sweet orange) is ' +
                         'the fruit of the citrus species Citrus x ' +
                         'sinensis in the family Rutaceae.'];
        cells_as_arrays.push(cell_as_array);

        cell_as_array = ['orange', 'tag', 'juicy', ''];
        cells_as_arrays.push(cell_as_array);

        client.set_cells_as_arrays(ns, 'Fruits', cells_as_arrays, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

####  get_cells_as_arrays

The following code snippet illustrates how to fetch cells with the [get_cells_as_arrays](../reference_manual/thrift_api.md#getcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](nodejs.md#basics) example.

    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function getCellsAsArrays (callback) {
        client.get_cells_as_arrays(ns, 'Fruits', new ScanSpec({columns: ['description']}),
                         function (error, cells_as_arrays) {
            if (!error) {
              for (var j = 0; j < cells_as_arrays.length; j++)
                console.log(cells_as_arrays[j].slice(0 ,4));
            }
            callback(error);
          });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    [ 'apple',
      'description',
      '',
      'The apple is the pomaceous fruit of the apple tree.' ]
    [ 'orange',
      'description',
      '',
      'The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus x sinensis in the family Rutaceae.' ]

####  set_cells_serialized

The following code snippet illustrates how to insert cells with the [set_cells_serialized](../reference_manual/thrift_api.md#setcellsserialized) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](nodejs.md#basics) example. It makes use of the [SerializedCellsWriter](http://www.hypertable.com/doc/node-js-api/hypertable/current/module-hypertable.SerializedCellsWriter.html) class.

    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function setCellsSerialized (callback) {

        var writer = new hypertable.SerializedCellsWriter(1024);

        writer.add('canteloupe', 'genus', null, null, 'Cucumis');

        writer.add('canteloupe', 'description', null, null,
                   'Canteloupe refers to a variety of Cucumis melo, a ' +
                   'species in the family Cucurbitaceae.');

        writer.add('canteloupe', 'tag', 'juicy');

        client.set_cells_serialized(ns, 'Fruits', writer.getBuffer(), callback);

      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

####  get_cells_serialized

The following code snippet illustrates how to fetch cells with the [get_cells_serialized](../reference_manual/thrift_api.md#getcellsserialized) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](nodejs.md#basics) example. It makes use of the [SerializedCellsReader](http://www.hypertable.com/doc/node-js-api/hypertable/current/module-hypertable.SerializedCellsReader.html) class.

    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function getCellsSerialized (callback) {
        client.get_cells_serialized(ns, 'Fruits',
                                    new ScanSpec({columns: ['description']}),
                                    function (error, result) {
                                      if (!error) {
                                        var reader = new hypertable.SerializedCellsReader(result);
                                        while (reader.next())
                                          console.log(reader.getCell().toString());
                                      }
                                      callback(error);
                                    });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='apple', column_family='description', column_qualifier='', timestamp=1427995329442597002, flag=255), value='The apple is the pomaceous fruit of the apple tree.')
    Cell(key=Key(row='canteloupe', column_family='description', column_qualifier='', timestamp=1427995329529040002, flag=255), value='Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.')
    Cell(key=Key(row='orange', column_family='description', column_qualifier='', timestamp=1427995329487326002, flag=255), value='The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus x sinensis in the family Rutaceae.')

### Creating a table

The following code snippet illustrates how to create a table with the [table_create](../reference_manual/thrift_api.md#tablecreate) API. It introduces the API classes [Schema](../reference_manual/thrift_api.md#schema), [AccessGroupSpec](../reference_manual/thrift_api.md#accessgroupspec), [AccessGroupOptions](../reference_manual/thrift_api.md#accessgroupoptions), [ColumnFamilySpec](../reference_manual/thrift_api.md#columnfamilyspec), and [ColumnFamilyOptions](../reference_manual/thrift_api.md#columnfamilyoptions).

    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function createTable (callback) {

        var defaultAgOptions = new hypertable.AccessGroupOptions({blocksize: 65536});
        var defaultCfOptions = new hypertable.ColumnFamilyOptions({max_versions: 1});

        var cfOptions = new hypertable.ColumnFamilyOptions({max_versions: 2});
        var agSpec = new hypertable.AccessGroupSpec({name: 'ag_normal', defaults: cfOptions});

        var agSpecs = {};
        agSpecs['ag_normal'] = agSpec;

        var cfSpec = new hypertable.ColumnFamilySpec({name: 'a', access_group: 'ag_normal',
                                                      value_index: true, qualifier_index: true});
        var cfSpecs = {};
        cfSpecs['a'] = cfSpec;

        cfOptions = new hypertable.ColumnFamilyOptions({max_versions: 3});
        cfSpec = new hypertable.ColumnFamilySpec({name: 'b', access_group: 'ag_normal',
                                                  options: cfOptions});
        cfSpecs['b'] = cfSpec;

        var agOptions = new hypertable.AccessGroupOptions({in_memory: true, blocksize: 131072});
        agSpec = new hypertable.AccessGroupSpec({name: 'ag_fast', options: agOptions});
        agSpecs['ag_fast'] = agSpec;

        cfSpec = new hypertable.ColumnFamilySpec({name: 'c', access_group: 'ag_fast'});
        cfSpecs['c'] = cfSpec;

        agOptions = new hypertable.AccessGroupOptions({replication: 5});
        agSpec = new hypertable.AccessGroupSpec({name: 'ag_secure', options: agOptions});
        agSpecs['ag_secure'] = agSpec;

        cfSpec = new hypertable.ColumnFamilySpec({name: 'd', access_group: 'ag_secure'});
        cfSpecs['d'] = cfSpec;

        cfOptions = new hypertable.ColumnFamilyOptions({counter: true, max_versions: 0});
        agSpec = new hypertable.AccessGroupSpec({name: 'ag_counter', defaults: cfOptions});
        agSpecs['ag_counter'] = agSpec;

        cfSpec = new hypertable.ColumnFamilySpec({name: 'e', access_group: 'ag_counter'});
        cfSpecs['e'] = cfSpec;

        cfOptions = new hypertable.ColumnFamilyOptions({counter: false});
        cfSpec = new hypertable.ColumnFamilySpec({name: 'f', access_group: 'ag_counter',
                                                  options: cfOptions});
        cfSpecs['f'] = cfSpec;

        var schema = new hypertable.Schema({access_groups: agSpecs, column_families: cfSpecs,
                                            access_group_defaults: defaultAgOptions,
                                            column_family_defaults: defaultCfOptions});

        client.table_create(ns, 'TestTable', schema, callback);
      },
      function showCreateTable (callback) {
        client.hql_query(ns, "SHOW CREATE TABLE TestTable", function (error, result) {
            if (result)
              console.log(util.format('%s', result.results[0]));
            callback(error);
          });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

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

The following code snippet illustrates how to alter a table with the [table_alter](../reference_manual/thrift_api.md#tablealter) API. It assumes that the table _TestTable_ has been created as in the [Creating a table](nodejs.md#creating-a-table) example.

    var ns;
    var schema;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function getSchema (callback) {
        client.get_schema(ns, 'TestTable', function (error, result) {
            if (!error)
              schema = result;
            callback(error);
          });
      },
      function alterTable (callback) {

        // Rename column 'b' to 'z'
        var cfSpec = schema.column_families['b'];
        delete schema.column_families['b'];
        cfSpec.name = 'z';
        schema.column_families['z'] = cfSpec;

        // Add column "g"
        cfSpec = new hypertable.ColumnFamilySpec({name: 'g', access_group: 'ag_counter'});
        schema.column_families['g'] = cfSpec;

        client.table_alter(ns, 'TestTable', schema, callback);
      },
      function showCreateTable (callback) {
        client.hql_query(ns, "SHOW CREATE TABLE TestTable", function (error, result) {
            if (result)
              console.log(util.format('%s', result.results[0]));
            callback(error);
          });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

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

The code snippet below illustrates how to insert cells into a table using a mutator. The APIs introduced include [mutator_open](../reference_manual/thrift_api.md#mutatoropen), [mutator_set_cells](../reference_manual/thrift_api.md#mutatorsetcells), [mutator_flush](../reference_manual/thrift_api.md#mutatorflush), and [mutator_close](../reference_manual/thrift_api.md#mutatorclose). The example is shown below.

    var mutator;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openMutator (callback) {
        client.mutator_open(ns, "Fruits", 0, 0, function (error, result) {
            if (!error)
              mutator = result;
            callback(error);
          });
      },
      function setCellsAutoTimestamp (callback) {
        var cells = [];
        var cell;
        var key;

        key = new hypertable.Key({row: 'lemon', column_family: 'genus'});
        cell = new hypertable.Cell({key: key, value: 'Citrus'});
        cells.push(cell);

        key = new hypertable.Key({row: 'lemon', column_family: 'description'});
        cell = new hypertable.Cell({key: key, value: 'The lemon (Citrus x limon)' +
                                    'is a small evergreen tree native to Asia.'});
        cells.push(cell);

        key = new hypertable.Key({row: 'lemon', column_family: 'tag',
                                  column_qualifier: 'bitter'});
        cell = new hypertable.Cell({key: key});
        cells.push(cell);

        client.mutator_set_cells(mutator, cells, callback);

      },
      function flushMutator (callback) {
        client.mutator_flush(mutator, callback);
      },
      function setCellsWithTimestamp (callback) {
        var cells = [];
        var cell;
        var key;
        var ts;

        // 2014-06-06 16:27:15
        ts = new Timestamp( new Date(2014, 6, 6, 16, 27, 15) );

        key = new hypertable.Key({row: 'mango', column_family: 'genus',
                                  timestamp: ts});
        cell = new hypertable.Cell({key: key, value: 'Mangifera'});
        cells.push(cell);

        key = new hypertable.Key({row: 'mango', column_family: 'tag',
                                  column_qualifier: 'sweet',
                                  timestamp: ts});
        cell = new hypertable.Cell({key: key});
        cells.push(cell);

        key = new hypertable.Key({row: 'mango', column_family: 'description',
                                  timestamp: ts});
        cell = new hypertable.Cell({key: key, value: 'Mango is one of the ' +
                                    'delicious seasonal fruits grown in the ' +
                                    'tropics.'});
        cells.push(cell);

        // 2014-06-06 16:27:16
        ts = new Timestamp( new Date(2014, 6, 6, 16, 27, 16) );

        key = new hypertable.Key({row: 'mango', column_family: 'description',
                                  timestamp: ts});
        cell = new hypertable.Cell({key: key, value: 'The mango is a juicy stone' +
                                    ' fruit belonging to the genus Mangifera, ' +
                                    'consisting of numerous tropical fruiting ' +
                                    'trees, that are cultivated mostly for ' +
                                    'edible fruits.'});
        cells.push(cell);

        client.mutator_set_cells(mutator, cells, callback);
      },
      function flushMutator (callback) {
        client.mutator_flush(mutator, callback);
      },
      function setCellsDelete (callback) {
        var cells = [];
        var cell;
        var key;
        var ts;

        // 2014-06-06 16:27:15
        ts = new Timestamp( new Date(2014, 6, 6, 16, 27, 15) );

        key = new hypertable.Key({row: 'apple', flag: hypertable.KeyFlag.DELETE_ROW});
        cell = new hypertable.Cell({key: key});
        cells.push(cell);

        key = new hypertable.Key({row: 'mango', column_family: 'description',
                                  flag: hypertable.KeyFlag.DELETE_CELL});
        cell = new hypertable.Cell({key: key});
        cells.push(cell);

        client.mutator_set_cells(mutator, cells, callback);

      },
      function flushMutator (callback) {
        client.mutator_flush(mutator, callback);
      },
      function closeMutator (callback) {
        client.mutator_close(mutator, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

### Scanner

The following examples illustrate how to query a table using a scanner. The APIs introduced include the [scanner_open](../reference_manual/thrift_api.md#scanneropen), [scanner_get_cells](../reference_manual/thrift_api.md#scannergetcells), and [scanner_close](../reference_manual/thrift_api.md#scannerclose) functions, and the [ScanSpec](../reference_manual/thrift_api.md#scanspec) and [RowInterval](../reference_manual/thrift_api.md#rowinterval) classes.

####  Full table scan

The following code illustrates how to do a full table scan using the scanner APIs.

    var ns;
    var scanSpec;
    var scanner;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {
        scanSpec = new hypertable.ScanSpec();
        client.scanner_open(ns, "Fruits", scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function doScan (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='canteloupe', column_family='description', column_qualifier='', timestamp=1427995329529040002, revision=1427995329529040002, flag=255), value='Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.')
    Cell(key=Key(row='canteloupe', column_family='genus', column_qualifier='', timestamp=1427995329529040001, revision=1427995329529040001, flag=255), value='Cucumis')
    Cell(key=Key(row='canteloupe', column_family='tag', column_qualifier='juicy', timestamp=1427995329529040003, revision=1427995329529040003, flag=255), value='null')
    Cell(key=Key(row='lemon', column_family='description', column_qualifier='', timestamp=1427995332129842002, revision=1427995332129842002, flag=255), value='The lemon (Citrus x limon)is a small evergreen tree native to Asia.')
    Cell(key=Key(row='lemon', column_family='genus', column_qualifier='', timestamp=1427995332129842001, revision=1427995332129842001, flag=255), value='Citrus')
    Cell(key=Key(row='lemon', column_family='tag', column_qualifier='bitter', timestamp=1427995332129842003, revision=1427995332129842003, flag=255), value='null')
    Cell(key=Key(row='mango', column_family='genus', column_qualifier='', timestamp=1404689235000000000, revision=1427995332194142001, flag=255), value='Mangifera')
    Cell(key=Key(row='mango', column_family='tag', column_qualifier='sweet', timestamp=1404689235000000000, revision=1427995332194142002, flag=255), value='null')
    Cell(key=Key(row='orange', column_family='description', column_qualifier='', timestamp=1427995329487326002, revision=1427995329487326002, flag=255), value='The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus x sinensis in the family Rutaceae.')
    Cell(key=Key(row='orange', column_family='genus', column_qualifier='', timestamp=1427995329487326001, revision=1427995329487326001, flag=255), value='Citrus')
    Cell(key=Key(row='orange', column_family='tag', column_qualifier='juicy', timestamp=1427995329487326003, revision=1427995329487326003, flag=255), value='null')

####  Restricted scan with ScanSpec

The following code illustrates how to do a table scan using a ScanSpec.

    var ns;
    var scanSpec;
    var scanner;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {
        var rowInterval = new hypertable.RowInterval({start_row: 'cherry',
                                                      start_inclusive: true,
                                                      end_row: 'orange',
                                                      end_inclusive: false});
        var rowIntervals = [ rowInterval ];
        var columns = ['genus', 'tag:fleshy', 'tag:bitter', 'tag:sweet'];
        scanSpec = new hypertable.ScanSpec({row_intervals: rowIntervals,
                                            versions: 1, columns: columns});
        client.scanner_open(ns, "Fruits", scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function doScan (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='lemon', column_family='genus', column_qualifier='', timestamp=1427995332129842001, revision=1427995332129842001, flag=255), value='Citrus')
    Cell(key=Key(row='lemon', column_family='tag', column_qualifier='bitter', timestamp=1427995332129842003, revision=1427995332129842003, flag=255), value='null')
    Cell(key=Key(row='mango', column_family='genus', column_qualifier='', timestamp=1404689235000000000, revision=1427995332194142001, flag=255), value='Mangifera')
    Cell(key=Key(row='mango', column_family='tag', column_qualifier='sweet', timestamp=1404689235000000000, revision=1427995332194142002, flag=255), value='null')

### HQL

####  hql_query

The following code illustrates how to issue HQL commands with the [hql_query](../reference_manual/thrift_api.md#hqlquery) API. It also introduces the [HqlResult](../reference_manual/thrift_api.md#hqlresult) class.

    var ns = 0;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function getListing (callback) {
        client.hql_query(ns, 'GET LISTING', function (error, response) {
            if (!error) {
              for (var j = 0; j < response.results.length; j++)
                console.log(util.format('%s', response.results[j]));
            }
            callback(error);
          });
      },
      function select (callback) {
        client.hql_query(ns, "SELECT * from Fruits WHERE ROW = 'mango'", function (error, response) {
            if (!error) {
              for (var j = 0; j < response.cells.length; j++)
                console.log(response.cells[j].toString());
            }
            callback(error);
          });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Fruits
    TestTable
    ^TestTable
    ^^TestTable
    sub	(namespace)
    Cell(key=Key(row='mango', column_family='genus', column_qualifier='', timestamp=1404689235000000000, revision=1427995332194142001, flag=255), value='Mangifera')
    Cell(key=Key(row='mango', column_family='tag', column_qualifier='sweet', timestamp=1404689235000000000, revision=1427995332194142002, flag=255), value='null')

####  hql_query_as_arrays

The following code illustrates how to issue an HQL query with the [hql_query_as_arrays](../reference_manual/thrift_api.md#hqlqueryasarrays) API. It also introduces the [HqlResultAsArrays](../reference_manual/thrift_api.md#hqlresultasarrays) class.

    var ns = 0;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function hqlQueryAsArrays (callback) {
        client.hql_query_as_arrays(ns, "SELECT * from Fruits WHERE ROW = 'lemon'", function (error, result) {
            if (!error) {
              for (var j = 0; j < result.cells.length; j++)
                console.log(result.cells[j].slice(0 ,4));
            }
            callback(error);
          });
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    [ 'lemon',
      'description',
      '',
      'The lemon (Citrus x limon)is a small evergreen tree native to Asia.' ]
    [ 'lemon', 'genus', '', 'Citrus' ]
    [ 'lemon', 'tag', 'bitter', '' ]

####  hql_exec (mutator)

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a mutator.

    var mutator;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function hqlExecMutator (callback) {
        client.hql_exec(ns, "INSERT INTO Fruits VALUES ('strawberry', 'genus'," +
                        "'Fragaria'), ('strawberry', 'tag:fibrous', ''), " +
                        "('strawberry', 'description', 'The garden strawberry " +
                        "is a widely grown hybrid species of the genus " +
                        "Fragaria')", true, false, function (error, result) {
            if (!error)
              mutator = result.mutator;
            callback(error);
          });
      },
      function mutatorSetCells (callback) {
        var cells = [];
        var cell;
        var key;

        key = new hypertable.Key({row: 'pineapple', column_family: 'genus'});
        cell = new hypertable.Cell({key: key, value: 'Anans'});
        cells.push(cell);

        key = new hypertable.Key({row: 'pineapple', column_family: 'tag',
                                  column_qualifier: 'acidic'});
        cell = new hypertable.Cell({key: key});
        cells.push(cell);

        key = new hypertable.Key({row: 'pineapple', column_family: 'description'});
        cell = new hypertable.Cell({key: key, value:
                                    'The pineapple (Ananas comosus) is a ' +
                                    'tropical plant with edible multiple fruit ' +
                                    'consisting of coalesced berries.'});
        cells.push(cell);

        client.mutator_set_cells(mutator, cells, callback);
      },
      function flushMutator (callback) {
        client.mutator_flush(mutator, callback);
      },
      function closeMutator (callback) {
        client.mutator_close(mutator, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

####  hql_exec (scanner}

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a scanner.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function hqlExecScanner (callback) {
        client.hql_exec(ns, 'SELECT * from Fruits', false, true, function (error, result) {
            if (!error)
              scanner = result.scanner;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='canteloupe', column_family='description', column_qualifier='', timestamp=1427995329529040002, revision=1427995329529040002, flag=255), value='Canteloupe refers to a variety of Cucumis melo, a species in the family Cucurbitaceae.')
    Cell(key=Key(row='canteloupe', column_family='genus', column_qualifier='', timestamp=1427995329529040001, revision=1427995329529040001, flag=255), value='Cucumis')
    Cell(key=Key(row='canteloupe', column_family='tag', column_qualifier='juicy', timestamp=1427995329529040003, revision=1427995329529040003, flag=255), value='null')
    Cell(key=Key(row='lemon', column_family='description', column_qualifier='', timestamp=1427995332129842002, revision=1427995332129842002, flag=255), value='The lemon (Citrus x limon)is a small evergreen tree native to Asia.')
    Cell(key=Key(row='lemon', column_family='genus', column_qualifier='', timestamp=1427995332129842001, revision=1427995332129842001, flag=255), value='Citrus')
    Cell(key=Key(row='lemon', column_family='tag', column_qualifier='bitter', timestamp=1427995332129842003, revision=1427995332129842003, flag=255), value='null')
    Cell(key=Key(row='mango', column_family='genus', column_qualifier='', timestamp=1404689235000000000, revision=1427995332194142001, flag=255), value='Mangifera')
    Cell(key=Key(row='mango', column_family='tag', column_qualifier='sweet', timestamp=1404689235000000000, revision=1427995332194142002, flag=255), value='null')
    Cell(key=Key(row='orange', column_family='description', column_qualifier='', timestamp=1427995329487326002, revision=1427995329487326002, flag=255), value='The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus x sinensis in the family Rutaceae.')
    Cell(key=Key(row='orange', column_family='genus', column_qualifier='', timestamp=1427995329487326001, revision=1427995329487326001, flag=255), value='Citrus')
    Cell(key=Key(row='orange', column_family='tag', column_qualifier='juicy', timestamp=1427995329487326003, revision=1427995329487326003, flag=255), value='null')
    Cell(key=Key(row='pineapple', column_family='description', column_qualifier='', timestamp=1427995332478214003, revision=1427995332478214003, flag=255), value='The pineapple (Ananas comosus) is a tropical plant with edible multiple fruit consisting of coalesced berries.')
    Cell(key=Key(row='pineapple', column_family='genus', column_qualifier='', timestamp=1427995332478214001, revision=1427995332478214001, flag=255), value='Anans')
    Cell(key=Key(row='pineapple', column_family='tag', column_qualifier='acidic', timestamp=1427995332478214002, revision=1427995332478214002, flag=255), value='null')
    Cell(key=Key(row='strawberry', column_family='description', column_qualifier='', timestamp=1427995332478214006, revision=1427995332478214006, flag=255), value='The garden strawberry is a widely grown hybrid species of the genus Fragaria')
    Cell(key=Key(row='strawberry', column_family='genus', column_qualifier='', timestamp=1427995332478214004, revision=1427995332478214004, flag=255), value='Fragaria')
    Cell(key=Key(row='strawberry', column_family='tag', column_qualifier='fibrous', timestamp=1427995332478214005, revision=1427995332478214005, flag=255), value='null')

### Secondary Indexes

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

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var args = {column_family: 'section',
                    operation: hypertable.ColumnPredicateOperation.EXACT_MATCH,
                    value: 'books'};
        var columnPredicate = new hypertable.ColumnPredicate(args);
        var columns = [ 'title' ];
        var scanSpec = new hypertable.ScanSpec({column_predicates: [columnPredicate], columns: columns});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='0307743659', column_family='title', column_qualifier='', timestamp=1427995335873512001, revision=1427995335873512001, flag=255), value='The Shining Mass Market Paperback')
    Cell(key=Key(row='0321321928', column_family='title', column_qualifier='', timestamp=1427995335873512008, revision=1427995335873512008, flag=255), value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]')
    Cell(key=Key(row='0321776402', column_family='title', column_qualifier='', timestamp=1427995335873512019, revision=1427995335873512019, flag=255), value='C++ Primer Plus (6th Edition) (Developer's Library)')

####  Value index (exact match with qualifier)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title FROM products WHERE info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var operation = hypertable.ColumnPredicateOperation.EXACT_MATCH |
                        hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        var args = {column_family: 'info', column_qualifier: 'actor',
                    operation: operation, value: 'Jack Nicholson'};
        var columnPredicate = new hypertable.ColumnPredicate(args);
        var columns = [ 'title' ];
        var scanSpec = new hypertable.ScanSpec({column_predicates: [columnPredicate], columns: columns});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='B00002VWE0', column_family='title', column_qualifier='', timestamp=1427995335873512030, revision=1427995335873512030, flag=255), value='Five Easy Pieces (1970)')
    Cell(key=Key(row='B002VWNIDG', column_family='title', column_qualifier='', timestamp=1427995335873512049, revision=1427995335873512049, flag=255), value='The Shining (1980)')

####  Value index (prefix match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =^ 'Addison-Wesley';

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var operation = hypertable.ColumnPredicateOperation.PREFIX_MATCH |
                        hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        var args = {column_family: 'info', column_qualifier: 'publisher',
                    operation: operation, value: 'Addison-Wesley'};
        var columnPredicate = new hypertable.ColumnPredicate(args);
        var columns = [ 'title', 'info:publisher' ];
        var scanSpec = new hypertable.ScanSpec({column_predicates: [columnPredicate], columns: columns});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='0321321928', column_family='title', column_qualifier='', timestamp=1427995335873512008, revision=1427995335873512008, flag=255), value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]')
    Cell(key=Key(row='0321321928', column_family='info', column_qualifier='publisher', timestamp=1427995335614819000, revision=1427995335873512013, flag=255), value='Addison-Wesley Professional; 1 edition (March 10, 2005)')
    Cell(key=Key(row='0321776402', column_family='title', column_qualifier='', timestamp=1427995335873512019, revision=1427995335873512019, flag=255), value='C++ Primer Plus (6th Edition) (Developer's Library)')
    Cell(key=Key(row='0321776402', column_family='info', column_qualifier='publisher', timestamp=1427995335614670000, revision=1427995335873512024, flag=255), value='Addison-Wesley Professional; 6 edition (October 28, 2011)')

####  Value index (regex match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =~ /^Addison-Wesley/;

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var operation = hypertable.ColumnPredicateOperation.REGEX_MATCH |
                        hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        var args = {column_family: 'info', column_qualifier: 'publisher',
                    operation: operation, value: '^Addison-Wesley'};
        var columnPredicate = new hypertable.ColumnPredicate(args);
        var columns = [ 'title', 'info:publisher' ];
        var scanSpec = new hypertable.ScanSpec({column_predicates: [columnPredicate], columns: columns});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='0321321928', column_family='title', column_qualifier='', timestamp=1427995335873512008, revision=1427995335873512008, flag=255), value='C++ Common Knowledge: Essential Intermediate Programming [Paperback]')
    Cell(key=Key(row='0321321928', column_family='info', column_qualifier='publisher', timestamp=1427995335614819000, revision=1427995335873512013, flag=255), value='Addison-Wesley Professional; 1 edition (March 10, 2005)')
    Cell(key=Key(row='0321776402', column_family='title', column_qualifier='', timestamp=1427995335873512019, revision=1427995335873512019, flag=255), value='C++ Primer Plus (6th Edition) (Developer's Library)')
    Cell(key=Key(row='0321776402', column_family='info', column_qualifier='publisher', timestamp=1427995335614670000, revision=1427995335873512024, flag=255), value='Addison-Wesley Professional; 6 edition (October 28, 2011)')

####  Qualifier index (exists)

The following HQL query which leverages the qualifier index of the _info_ column:

    SELECT title FROM products WHERE Exists(info:studio);

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var operation = hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        var args = {column_family: 'info', column_qualifier: 'studio',
                    operation: operation};
        var columnPredicate = new hypertable.ColumnPredicate(args);
        var columns = [ 'title' ];
        var scanSpec = new hypertable.ScanSpec({column_predicates: [columnPredicate], columns: columns});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='B00002VWE0', column_family='title', column_qualifier='', timestamp=1427995335873512030, revision=1427995335873512030, flag=255), value='Five Easy Pieces (1970)')
    Cell(key=Key(row='B000Q66J1M', column_family='title', column_qualifier='', timestamp=1427995335873512039, revision=1427995335873512039, flag=255), value='2001: A Space Odyssey [Blu-ray]')
    Cell(key=Key(row='B002VWNIDG', column_family='title', column_qualifier='', timestamp=1427995335873512049, revision=1427995335873512049, flag=255), value='The Shining (1980)')

####  Qualifier index (exists regex prefix match)

The following HQL query which leverages the qualifier index of the _category_ column:

    SELECT title FROM products WHERE Exists(category:/^\/Movies/);

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var operation = hypertable.ColumnPredicateOperation.QUALIFIER_REGEX_MATCH;
        var args = {column_family: 'category', column_qualifier: '^/Movies',
                    operation: operation};
        var columnPredicate = new hypertable.ColumnPredicate(args);
        var columns = [ 'title' ];
        var scanSpec = new hypertable.ScanSpec({column_predicates: [columnPredicate], columns: columns});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='B00002VWE0', column_family='title', column_qualifier='', timestamp=1427995335873512030, revision=1427995335873512030, flag=255), value='Five Easy Pieces (1970)')
    Cell(key=Key(row='B000Q66J1M', column_family='title', column_qualifier='', timestamp=1427995335873512039, revision=1427995335873512039, flag=255), value='2001: A Space Odyssey [Blu-ray]')
    Cell(key=Key(row='B002VWNIDG', column_family='title', column_qualifier='', timestamp=1427995335873512049, revision=1427995335873512049, flag=255), value='The Shining (1980)')

####  Value index (OR query)

The following HQL query performs a boolean _OR_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen P/ OR info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var predicates = [];
        var operation = hypertable.ColumnPredicateOperation.REGEX_MATCH |
          hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        var args = {column_family: 'info', column_qualifier: 'author',
                    operation: operation, value: '^Stephen P'};
        var columnPredicate = new hypertable.ColumnPredicate(args);
        predicates.push(columnPredicate);

        operation = hypertable.ColumnPredicateOperation.PREFIX_MATCH |
          hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        args = {column_family: 'info', column_qualifier: 'publisher',
                    operation: operation, value: 'Anchor'};
        columnPredicate = new hypertable.ColumnPredicate(args);
        predicates.push(columnPredicate);

        var scanSpec = new hypertable.ScanSpec({column_predicates: predicates,
                                                columns: [ 'title' ]});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='0307743659', column_family='title', column_qualifier='', timestamp=1427995335873512001, revision=1427995335873512001, flag=255), value='The Shining Mass Market Paperback')
    Cell(key=Key(row='0321776402', column_family='title', column_qualifier='', timestamp=1427995335873512019, revision=1427995335873512019, flag=255), value='C++ Primer Plus (6th Edition) (Developer's Library)')

####  Value index (AND query)

The following HQL query performs a boolean _AND_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var predicates = [];
        var operation = hypertable.ColumnPredicateOperation.REGEX_MATCH |
          hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        var args = {column_family: 'info', column_qualifier: 'author',
                    operation: operation, value: '^Stephen [PK]'};
        var columnPredicate = new hypertable.ColumnPredicate(args);
        predicates.push(columnPredicate);

        operation = hypertable.ColumnPredicateOperation.PREFIX_MATCH |
          hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        args = {column_family: 'info', column_qualifier: 'publisher',
                    operation: operation, value: 'Anchor'};
        columnPredicate = new hypertable.ColumnPredicate(args);
        predicates.push(columnPredicate);

        var scanSpec = new hypertable.ScanSpec({column_predicates: predicates,
                                                columns: [ 'title' ],
                                                and_column_predicates: true});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='0307743659', column_family='title', column_qualifier='', timestamp=1427995335873512001, revision=1427995335873512001, flag=255), value='The Shining Mass Market Paperback')

####  Value index (AND row interval)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW interval:

    SELECT title
      FROM products
      WHERE ROW > 'B00002VWE0' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var rowInterval = new hypertable.RowInterval({start_row: 'B00002VWE0',
                                                      start_inclusive: false,
                                                      end_inclusive: true});
        var operation = hypertable.ColumnPredicateOperation.EXACT_MATCH |
          hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        var args = {column_family: 'info', column_qualifier: 'actor',
                    operation: operation, value: 'Jack Nicholson'};
        var columnPredicate = new hypertable.ColumnPredicate(args);

        var scanSpec = new hypertable.ScanSpec({row_intervals: [rowInterval],
                                                column_predicates: [columnPredicate],
                                                columns: [ 'title' ],
                                                and_column_predicates: true});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='B002VWNIDG', column_family='title', column_qualifier='', timestamp=1427995335873512049, revision=1427995335873512049, flag=255), value='The Shining (1980)')

####  Value index (AND row prefix)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW prefix interval:

    SELECT title
      FROM products
      WHERE ROW =^ 'B' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    var scanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openScanner (callback) {

        var rowInterval = new hypertable.RowInterval({start_row: 'B',
                                                      start_inclusive: true,
                                                      end_row: 'C',
                                                      end_inclusive: false});
        var operation = hypertable.ColumnPredicateOperation.EXACT_MATCH |
          hypertable.ColumnPredicateOperation.QUALIFIER_EXACT_MATCH;
        var args = {column_family: 'info', column_qualifier: 'actor',
                    operation: operation, value: 'Jack Nicholson'};
        var columnPredicate = new hypertable.ColumnPredicate(args);

        var scanSpec = new hypertable.ScanSpec({row_intervals: [rowInterval],
                                                column_predicates: [columnPredicate],
                                                columns: [ 'title' ],
                                                and_column_predicates: true});

        client.scanner_open(ns, 'products', scanSpec, function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='B00002VWE0', column_family='title', column_qualifier='', timestamp=1427995335873512030, revision=1427995335873512030, flag=255), value='Five Easy Pieces (1970)')
    Cell(key=Key(row='B002VWNIDG', column_family='title', column_qualifier='', timestamp=1427995335873512049, revision=1427995335873512049, flag=255), value='The Shining (1980)')

### Asynchronous APIs

This section describes how to use the asynchronous APIs. The examples assume that tables _Profile_ and _Session_ are created and loaded with the following HQL commands.

    CREATE TABLE Profile (info, last_access MAX_VERSIONS 1);

    CREATE TABLE Session (user_id, page_hit);

    INSERT INTO Profile
      VALUES ('1', 'info:name', 'Joe'), ('2', 'info:name', 'Sue');

####  Async mutator

The code snippet below illustrates how to insert cells into multiple tables simultaneously using an asynchronous mutator. The APIs introduced include the [future_open](../reference_manual/thrift_api.md#futureopen), [future_get_result](../reference_manual/thrift_api.md#futuregetresult), [future_close](../reference_manual/thrift_api.md#futureclose), [async_mutator_open](../reference_manual/thrift_api.md#asyncmutatoropen), [async_mutator_set_cells](../reference_manual/thrift_api.md#asyncmutatorsetcells), [async_mutator_flush](../reference_manual/thrift_api.md#asyncmutatorflush), and [async_mutator_close](../reference_manual/thrift_api.md#asyncmutatorclose) functions and the [Result](../reference_manual/thrift_api.md#result) class.

    var future;
    var asyncMutator = [];
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openFuture (callback) {
        client.future_open(0, function (error, result) {
            if (!error)
              future = result;
            callback(error);
          });
      },
      function openMutators (callback) {
        async.parallel([
          function openProfileMutator (callback) {
            client.async_mutator_open(ns, 'Profile', future, 0, callback);
          },
          function openSessionMutator (callback) {
            client.async_mutator_open(ns, 'Session', future, 0, callback);
          }
        ],
        function(error, results) {
          asyncMutator = results;
          callback(error);
        });
      },
      function asyncMutatorSetCells (callback) {
        async.parallel([
          function asyncMutatorProfileSetCells (callback) {
            var cells = [];
            var key = new hypertable.Key({row: '1', column_family: 'last_access'});
            var cell = new hypertable.Cell({key: key, value: '2014-06-13 16:06:09'});
            cells.push(cell);
            key = new hypertable.Key({row: '2', column_family: 'last_access'});
            cell = new hypertable.Cell({key: key, value: '2014-06-13 16:06:10'});
            cells.push(cell);
            client.async_mutator_set_cells(asyncMutator[0], cells, function (error) {
                if (!error)
                  client.async_mutator_flush(asyncMutator[0], callback);
                else
                  callback(error);
              });
          },
          function asyncMutatorSessionSetCells (callback) {
            var cells = [];
            var key = new hypertable.Key({row: '0001-200238',
                                          column_family: 'user_id',
                                          column_qualifier: '1'});
            var cell = new hypertable.Cell({key: key});
            cells.push(cell);
            key = new hypertable.Key({row: '0001-200238',
                                      column_family: 'page_hit'});
            cell = new hypertable.Cell({key: key, value: '/index.html'});
            cells.push(cell);
            key = new hypertable.Key({row: '0002-383049',
                                      column_family: 'user_id',
                                      column_qualifier: '2'});
            cell = new hypertable.Cell({key: key});
            cells.push(cell);
            key = new hypertable.Key({row: '0002-383049',
                                      column_family: 'page_hit'});
            cell = new hypertable.Cell({key: key, value: '/foo/bar.html'});
            cells.push(cell);
            client.async_mutator_set_cells(asyncMutator[1], cells, function (error) {
                if (!error)
                  client.async_mutator_flush(asyncMutator[1], callback);
                else
                  callback(error);
              });
          }
        ],
        function(error) { callback(error); });
      },
      function fetchResults (callback) {
        var resultCount = 0;
        var futureResult;
        async.doWhilst(
          function (callback) {
            client.future_get_result(future, 10000, function (error, result) {
                futureResult = result;
                if (!error && !futureResult.is_empty) {
                  resultCount += 1;
                  if (result.is_error)
                    error = new Error(result.error_msg);
                  else if (result.id.toBuffer().compare(asyncMutator[0].toBuffer()))
                    console.log('Result is from Profile mutation');
                  else if (result.id.toBuffer().compare(asyncMutator[1].toBuffer()))
                    console.log('Result is from Session mutation');
                }
                callback(error);
              });
          },
          function () { return !futureResult.is_empty; },
          function (error) {
            if (!error)
              console.log('result count = ' + resultCount);
            callback(error);
          }
        );
      },
      function closeMutators (callback) {
        async.parallel([
          function closeProfileMutator (callback) {
            client.async_mutator_close(asyncMutator[0], callback);
          },
          function closeSessionMutator (callback) {
            client.async_mutator_close(asyncMutator[1], callback);
          }
        ],
        function(error) { callback(error); });
      },
      function closeFuture (callback) {
        client.future_close(future, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Result is from Session mutation
    Result is from Profile mutation
    result count = 2

####  Async scanner (Result)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [Result](../reference_manual/thrift_api.md#result) object. The APIs introduced include the [async_scanner_open](../reference_manual/thrift_api.md#asyncscanneropen) and [async_scanner_close](../reference_manual/thrift_api.md#asyncscannerclose) functions.

    var future;
    var asyncScanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openFuture (callback) {
        client.future_open(0, function (error, result) {
            if (!error)
              future = result;
            callback(error);
          });
      },
      function openScanners (callback) {
        async.parallel([
          function openProfileScanner (callback) {
            var rowInterval = new hypertable.RowInterval({start_row: '1',
                                                          start_inclusive: true,
                                                          end_row: '1',
                                                          end_inclusive: true});
            var scanSpec = new hypertable.ScanSpec({row_intervals: [rowInterval]});
            client.async_scanner_open(ns, 'Profile', future, scanSpec, callback);
          },
          function openSessionScanner (callback) {
            var rowInterval = new hypertable.RowInterval({start_row: '0001-200238',
                                                          start_inclusive: true,
                                                          end_row: '0001-200238',
                                                          end_inclusive: true});
            var scanSpec = new hypertable.ScanSpec({row_intervals: [rowInterval]});
            client.async_scanner_open(ns, 'Session', future, scanSpec, callback);
          }
        ],
        function(error, results) {
          asyncScanner = results;
          callback(error);
        });
      },
      function fetchResults (callback) {
        var futureResult;
        async.doWhilst(
          function (callback) {
            client.future_get_result(future, 10000, function (error, result) {
                futureResult = result;
                if (!error && !futureResult.is_empty) {
                  if (result.is_error) {
                    callback(new Error(result.error_msg));
                    return;
                  }
                  assert(futureResult.is_scan, 'Unexpected non-scanner result encountered');
                  if (result.id.toBuffer().compare(asyncScanner[0].toBuffer()))
                    console.log('Result is from Profile scan');
                  else if (result.id.toBuffer().compare(asyncScanner[1].toBuffer()))
                    console.log('Result is from Session scan');
                  else {
                    callback(new Error('Invalid scanner ID encountered'));
                    return;
                  }
                  for (var j = 0; j < result.cells.length; j++)
                    console.log(result.cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return !futureResult.is_empty; },
          function (error) { callback(error); }
        );
      },
      function closeScanners (callback) {
        async.parallel([
          function closeProfileScanner (callback) {
            client.async_scanner_close(asyncScanner[0], callback);
          },
          function closeSessionScanner (callback) {
            client.async_scanner_close(asyncScanner[1], callback);
          }
        ],
        function(error) { callback(error); });
      },
      function closeFuture (callback) {
        client.future_close(future, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Result is from Session scan
    Cell(key=Key(row='1', column_family='info', column_qualifier='name', timestamp=1427995336626193001, revision=1427995336626193001, flag=255), value='Joe')
    Cell(key=Key(row='1', column_family='last_access', column_qualifier='', timestamp=1427995337435070001, revision=1427995337435070001, flag=255), value='2014-06-13 16:06:09')
    Result is from Profile scan
    Cell(key=Key(row='0001-200238', column_family='user_id', column_qualifier='1', timestamp=1427995337435721001, revision=1427995337435721001, flag=255), value='null')
    Cell(key=Key(row='0001-200238', column_family='page_hit', column_qualifier='', timestamp=1427995337435721002, revision=1427995337435721002, flag=255), value='/index.html')

####  Async scanner (ResultSerialized)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultSerialized](../reference_manual/thrift_api.md#resultserialized) object. This example introduces the [future_get_result_serialized](../reference_manual/thrift_api.md#futuregetresultserialized) API and makes use of the [SerializedCellsReader](http://www.hypertable.com/doc/node-js-api/hypertable/current/module-hypertable.SerializedCellsReader.html) class.

    var future;
    var asyncScanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openFuture (callback) {
        client.future_open(0, function (error, result) {
            if (!error)
              future = result;
            callback(error);
          });
      },
      function openScanners (callback) {
        async.parallel([
          function openProfileScanner (callback) {
            var rowInterval = new hypertable.RowInterval({start_row: '1',
                                                          start_inclusive: true,
                                                          end_row: '1',
                                                          end_inclusive: true});
            var scanSpec = new hypertable.ScanSpec({row_intervals: [rowInterval]});
            client.async_scanner_open(ns, 'Profile', future, scanSpec, callback);
          },
          function openSessionScanner (callback) {
            var rowInterval = new hypertable.RowInterval({start_row: '0001-200238',
                                                          start_inclusive: true,
                                                          end_row: '0001-200238',
                                                          end_inclusive: true});
            var scanSpec = new hypertable.ScanSpec({row_intervals: [rowInterval]});
            client.async_scanner_open(ns, 'Session', future, scanSpec, callback);
          }
        ],
        function(error, results) {
          asyncScanner = results;
          callback(error);
        });
      },
      function fetchResults (callback) {
        var futureResult;
        async.doWhilst(
          function (callback) {
            client.future_get_result_serialized(future, 10000, function (error, result_serialized) {
                futureResult = result_serialized;
                if (!error && !futureResult.is_empty) {
                  if (result_serialized.is_error) {
                    callback(new Error(result_serialized.error_msg));
                    return;
                  }
                  assert(futureResult.is_scan, 'Unexpected non-scanner result encountered');
                  if (result_serialized.id.toBuffer().compare(asyncScanner[0].toBuffer()))
                    console.log('Result is from Profile scan');
                  else if (result_serialized.id.toBuffer().compare(asyncScanner[1].toBuffer()))
                    console.log('Result is from Session scan');
                  else {
                    callback(new Error('Invalid scanner ID encountered'));
                    return;
                  }
                  var reader = new hypertable.SerializedCellsReader(result_serialized.cells);
                  while (reader.next())
                    console.log(reader.getCell().toString());
                }
                callback(error);
              });
          },
          function () { return !futureResult.is_empty; },
          function (error) { callback(error); }
        );
      },
      function closeScanners (callback) {
        async.parallel([
          function closeProfileScanner (callback) {
            client.async_scanner_close(asyncScanner[0], callback);
          },
          function closeSessionScanner (callback) {
            client.async_scanner_close(asyncScanner[1], callback);
          }
        ],
        function(error) { callback(error); });
      },
      function closeFuture (callback) {
        client.future_close(future, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Result is from Session scan
    Cell(key=Key(row='1', column_family='info', column_qualifier='name', timestamp=1427995336626193001, flag=255), value='Joe')
    Cell(key=Key(row='1', column_family='last_access', column_qualifier='', timestamp=1427995337435070001, flag=255), value='2014-06-13 16:06:09')
    Result is from Profile scan
    Cell(key=Key(row='0001-200238', column_family='user_id', column_qualifier='1', timestamp=1427995337435721001, flag=255), value='null')
    Cell(key=Key(row='0001-200238', column_family='page_hit', column_qualifier='', timestamp=1427995337435721002, flag=255), value='/index.html')

####  Async scanner (ResultAsArrays)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultAsArrays](../reference_manual/thrift_api.md#resultasarrays) object. This example introduces the [future_get_result_as_arrays](../reference_manual/thrift_api.md#futuregetresultasarrays) API.

    var future;
    var asyncScanner;
    var ns;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openFuture (callback) {
        client.future_open(0, function (error, result) {
            if (!error)
              future = result;
            callback(error);
          });
      },
      function openScanners (callback) {
        async.parallel([
          function openProfileScanner (callback) {
            var rowInterval = new hypertable.RowInterval({start_row: '1',
                                                          start_inclusive: true,
                                                          end_row: '1',
                                                          end_inclusive: true});
            var scanSpec = new hypertable.ScanSpec({row_intervals: [rowInterval]});
            client.async_scanner_open(ns, 'Profile', future, scanSpec, callback);
          },
          function openSessionScanner (callback) {
            var rowInterval = new hypertable.RowInterval({start_row: '0001-200238',
                                                          start_inclusive: true,
                                                          end_row: '0001-200238',
                                                          end_inclusive: true});
            var scanSpec = new hypertable.ScanSpec({row_intervals: [rowInterval]});
            client.async_scanner_open(ns, 'Session', future, scanSpec, callback);
          }
        ],
        function(error, results) {
          asyncScanner = results;
          callback(error);
        });
      },
      function fetchResults (callback) {
        var futureResult;
        async.doWhilst(
          function (callback) {
            client.future_get_result_as_arrays(future, 10000, function (error, result_as_arrays) {
                futureResult = result_as_arrays;
                if (!error && !futureResult.is_empty) {
                  if (result_as_arrays.is_error) {
                    callback(new Error(result_as_arrays.error_msg));
                    return;
                  }
                  assert(futureResult.is_scan, 'Unexpected non-scanner result encountered');
                  if (result_as_arrays.id.toBuffer().compare(asyncScanner[0].toBuffer()))
                    console.log('Result is from Profile scan');
                  else if (result_as_arrays.id.toBuffer().compare(asyncScanner[1].toBuffer()))
                    console.log('Result is from Session scan');
                  else {
                    callback(new Error('Invalid scanner ID encountered'));
                    return;
                  }
                  for (var j = 0; j < result_as_arrays.cells.length; j++)
                    console.log(result_as_arrays.cells[j].slice(0 ,4));
                }
                callback(error);
              });
          },
          function () { return !futureResult.is_empty; },
          function (error) { callback(error); }
        );
      },
      function closeScanners (callback) {
        async.parallel([
          function closeProfileScanner (callback) {
            client.async_scanner_close(asyncScanner[0], callback);
          },
          function closeSessionScanner (callback) {
            client.async_scanner_close(asyncScanner[1], callback);
          }
        ],
        function(error) { callback(error); });
      },
      function closeFuture (callback) {
        client.future_close(future, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Result is from Session scan
    [ '1', 'info', 'name', 'Joe' ]
    [ '1', 'last_access', '', '2014-06-13 16:06:09' ]
    Result is from Profile scan
    [ '0001-200238', 'user_id', '1', '' ]
    [ '0001-200238', 'page_hit', '', '/index.html' ]

### Atomic counters

This section describes how to use atomic counters. The examples assume that a  _Hits_ table has been created with the following HQL command.

    CREATE TABLE Hits (count COUNTER);

####  Increment

The code snippet below illustrates how to increment per-second hit counts for pages of a website.

    var mutator;
    var ns;
    var scanner;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openMutator (callback) {
        client.mutator_open(ns, "Hits", 0, 0, function (error, result) {
            if (!error)
              mutator = result;
            callback(error);
          });
      },
      function setCells (callback) {

        var cells = [];
        var key = new hypertable.Key({row: '/index.html',
                                      column_family: 'count',
                                      column_qualifier: '2014-06-14 07:31:18'});
        var cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/index.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:18'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/foo/bar.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:18'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/foo/bar.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:18'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/foo/bar.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:18'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/index.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:19'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/index.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:19'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/index.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:19'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/index.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:19'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/foo/bar.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:19'});
        cell = new hypertable.Cell({key: key, value: '1'});
        cells.push(cell);

        client.mutator_set_cells(mutator, cells, function (error, result) {
            if (error)
              callback(error);
            else
              client.mutator_flush(mutator, callback);
          });
      },
      function openScanner (callback) {
        client.scanner_open(ns, 'Hits', new hypertable.ScanSpec(), function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeMutator (callback) {
        client.mutator_close(mutator, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='/foo/bar.html', column_family='count', column_qualifier='2014-06-14 07:31:18', timestamp=1427995338241796003, revision=1427995338241796003, flag=255), value='3')
    Cell(key=Key(row='/foo/bar.html', column_family='count', column_qualifier='2014-06-14 07:31:19', timestamp=1427995338241796004, revision=1427995338241796004, flag=255), value='1')
    Cell(key=Key(row='/index.html', column_family='count', column_qualifier='2014-06-14 07:31:18', timestamp=1427995338241796006, revision=1427995338241796006, flag=255), value='2')
    Cell(key=Key(row='/index.html', column_family='count', column_qualifier='2014-06-14 07:31:19', timestamp=1427995338241796010, revision=1427995338241796010, flag=255), value='4')

####  Reset and subtraction

The code snippet below illustrates how to reset and subtract from counters.

    var mutator;
    var ns;
    var scanner;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function openMutator (callback) {
        client.mutator_open(ns, "Hits", 0, 0, function (error, result) {
            if (!error)
              mutator = result;
            callback(error);
          });
      },
      function setCells (callback) {

        var cells = [];
        var key = new hypertable.Key({row: '/index.html',
                                      column_family: 'count',
                                      column_qualifier: '2014-06-14 07:31:18'});
        var cell = new hypertable.Cell({key: key, value: '=0'});
        cells.push(cell);

        key = new hypertable.Key({row: '/index.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:18'});
        cell = new hypertable.Cell({key: key, value: '7'});
        cells.push(cell);

        key = new hypertable.Key({row: '/foo/bar.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:18'});
        cell = new hypertable.Cell({key: key, value: '-1'});
        cells.push(cell);

        key = new hypertable.Key({row: '/index.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:19'});
        cell = new hypertable.Cell({key: key, value: '-2'});
        cells.push(cell);

        key = new hypertable.Key({row: '/foo/bar.html',
                                  column_family: 'count',
                                  column_qualifier: '2014-06-14 07:31:19'});
        cell = new hypertable.Cell({key: key, value: '=19'});
        cells.push(cell);

        client.mutator_set_cells(mutator, cells, function (error, result) {
            if (error)
              callback(error);
            else
              client.mutator_flush(mutator, callback);
          });
      },
      function openScanner (callback) {
        client.scanner_open(ns, 'Hits', new hypertable.ScanSpec(), function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeMutator (callback) {
        client.mutator_close(mutator, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    Cell(key=Key(row='/foo/bar.html', column_family='count', column_qualifier='2014-06-14 07:31:18', timestamp=1427995338321821001, revision=1427995338321821001, flag=255), value='2')
    Cell(key=Key(row='/foo/bar.html', column_family='count', column_qualifier='2014-06-14 07:31:19', timestamp=1427995338321821002, revision=1427995338321821002, flag=255), value='19')
    Cell(key=Key(row='/index.html', column_family='count', column_qualifier='2014-06-14 07:31:18', timestamp=1427995338321821004, revision=1427995338321821004, flag=255), value='7')
    Cell(key=Key(row='/index.html', column_family='count', column_qualifier='2014-06-14 07:31:19', timestamp=1427995338321821005, revision=1427995338321821005, flag=255), value='2')

### Creating unique keys

This section illustrates how to create unique keys using the [create_cell_unique](../reference_manual/thrift_api.md#createcellunique) API. The example show how you can create unique user IDs for an application. The code assumes that a _User_ table has been created with the following HQL command.

    CREATE TABLE User (info, id TIME_ORDER desc MAX_VERSIONS 1);

The example code snippet is as follows.

    var ns;
    var scanner;
    async.series([
      function openTestNamespace (callback) {
        client.namespace_open('test', function (error, result) {
            if (!error)
              ns = result;
            callback(error);
          });
      },
      function hqlCreateTable (callback) {
        client.hql_query(ns, 'CREATE TABLE User (info, id TIME_ORDER desc MAX_VERSIONS 1)', callback);
      },
      function createCellsUnique (callback) {
        async.parallel([
          function (callback) {
            var key = new hypertable.Key({row: 'joe1987', column_family: 'id'});
            client.create_cell_unique(ns, 'User', key, '', callback);
          },
          function (callback) {
            var key = new hypertable.Key({row: 'mary.bellweather', column_family: 'id'});
            client.create_cell_unique(ns, 'User', key, '', callback);
          }
        ],
        function(error) { callback(error); });
      },
      function createConflictingCell (callback) {
        var key = new hypertable.Key({row: 'joe1987', column_family: 'id'});
        client.create_cell_unique(ns, 'User', key, '', function (error, result) {
            if (error && error.code == 48) {
              console.log('User name "' + key.row + '" is already taken');
              callback();
            }
            else
              callback(error);
          });
      },
      function openScanner (callback) {
        client.scanner_open(ns, 'User', new hypertable.ScanSpec(), function (error, result) {
            if (!error)
              scanner = result;
            callback(error);
          });
      },
      function scannerGetCells (callback) {
        var cells;
        async.doWhilst(
          function (callback) {
            client.scanner_get_cells(scanner, function (error, result) {
                if (!error) {
                  cells = result;
                  for (var j=0; j < cells.length; j++)
                    console.log(cells[j].toString());
                }
                callback(error);
              });
          },
          function () { return Boolean(cells.length); },
          function (error) {
            callback(error);
          }
        );
      },
      function closeScanner (callback) {
        client.scanner_close(scanner, callback);
      },
      function closeTestNamespace (callback) {
        client.namespace_close(ns, callback);
      }
    ],
    function(error) {
      if (error)
        console.log(util.format('%s: %s', error.name, error.message));
    });

The following is example output produced by the above code snippet.

    User name "joe1987" is already taken
    Cell(key=Key(row='joe1987', column_family='id', column_qualifier='', timestamp=1427995339050992001, revision=1427995339050992001, flag=255), value='330e201a-c757-4415-af84-c1d4c446b771')
    Cell(key=Key(row='mary.bellweather', column_family='id', column_qualifier='', timestamp=1427995339089921001, revision=1427995339089921001, flag=255), value='1df7c13e-f85d-4f0f-9692-01f9f7ff216c')

### Appendix - Javascript API class documentation

API documentation, generated from the source code using the [JSDoc](http://usejsdoc.org/) tool, can be found at [Hypertable Javascript Class API](http://www.hypertable.com/doc/node-js-api/hypertable/current/index.html). The following highlights some of the important classes.

[Int64](http://www.hypertable.com/doc/node-js-api/hypertable/current/Int64.html) \- Holds a 64-bit integer. Since the Javascript Number type can only accurately represent integers to 53 bits, this class is used to pass 64-bit integers through the Thrift API. It is used for a number of things, including namespace IDs, scanner IDs, mutator IDs, timestamps, generation numbers, and revision numbers.

[SerializedCellsReader](http://www.hypertable.com/doc/node-js-api/hypertable/current/module-hypertable.SerializedCellsReader.html) \- There are a number of scanner APIs that return a serialized cells buffer, which is a compact serial representation of a list of cells, that is sent through the thrift API as a single BLOB. The serialized cells buffer can be more efficient that other APIs that transfer each cell as a separate Thrift object. This class is used to read cells from a serialized cells buffer.

[SerializedCellsWriter](http://www.hypertable.com/doc/node-js-api/hypertable/current/module-hypertable.SerializedCellsWriter.html) \- Like it's SeralizedCellsReader counterpart, there are a number of mutator APIs that accept data in the form of a serialized cells buffer (see above). This class is used to encode a list of cells into a serialized cells buffer.

[ThriftClient](http://www.hypertable.com/doc/node-js-api/hypertable/current/module-hypertable.ThriftClient.html) \- This is the primary Hypertable Thrift interface class which exposes all of the methods defined in the Hypertable Thrift API.

[Timestamp](http://www.hypertable.com/doc/node-js-api/hypertable/current/Timestamp.html) \- This class is derived from the [Int64](http://www.hypertable.com/doc/node-js-api/hypertable/current/Int64.html) class and contains constructors and methods designed to handle 64-bit timestamps.
