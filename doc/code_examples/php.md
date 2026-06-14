# PHP

### Prerequisites

In order for your PHP program to use the Hypertable Thrift Client interface, you need to tell it where to find it. To do that, set an evirnment variable `PHPTHRIFT_ROOT` to point to the `lib/php` directory in your installation. The following snippet illustrates how to do this in the Bash shell.

    export PHPTHRIFT_ROOT=/opt/hypertable/current/lib/php

Then, inside your PHP program, you need to set `$GLOBALS['THRIFT_ROOT']` to point to this directory and include the `ThriftClient.php` file. For example:

    if (!isset($GLOBALS['THRIFT_ROOT']))
        $GLOBALS['THRIFT_ROOT'] =  getenv('PHPTHRIFT_ROOT');

    require_once $GLOBALS['THRIFT_ROOT'].'/ThriftClient.php';

### Code Example

    <?php
    if (!isset($GLOBALS['THRIFT_ROOT']))
        $GLOBALS['THRIFT_ROOT'] =  getenv('PHPTHRIFT_ROOT');

    require_once $GLOBALS['THRIFT_ROOT'].'/ThriftClient.php';

    $client = new Hypertable_ThriftClient("localhost", 38080);
    $namespace = $client->namespace_open("test");

    echo "HQL examples\n";
    print_r($client->hql_query($namespace, "show tables"));
    print_r($client->hql_query($namespace, "select * from thrift_test revs=1 "));

    echo "mutator examples\n";
    $mutator = $client->mutator_open($namespace, "thrift_test", 0, 0);

    $key = new Hypertable_ThriftGen_Key(array('row'=> 'php-k1', 'column_family'=> 'col'));
    $cell = new Hypertable_ThriftGen_Cell(array('key' => $key, 'value'=> 'php-v1'));
    $client->mutator_set_cell($mutator, $cell);
    $client->mutator_close($mutator);

    echo "shared mutator examples\n";
    $mutate_spec = new Hypertable_ThriftGen_MutateSpec(array('appname'=>"test-php",
                                                             'flush_interval'=>1000,
                                                             'flags'=> 0));

    $key = new Hypertable_ThriftGen_Key(array('row'=> 'php-put-k1', 'column_family'=> 'col'));
    $cell = new Hypertable_ThriftGen_Cell(array('key' => $key, 'value'=> 'php-put-v1'));
    $client->shared_mutator_set_cell($namespace, "thrift_test", $mutate_spec, $cell);

    $key = new Hypertable_ThriftGen_Key(array('row'=> 'php-put-k2', 'column_family'=> 'col'));
    $cell = new Hypertable_ThriftGen_Cell(array('key' => $key, 'value'=> 'php-put-v2'));
    $client->shared_mutator_refresh($namespace, "thrift_test", $mutate_spec);
    $client->shared_mutator_set_cell($namespace, "thrift_test", $mutate_spec, $cell);
    sleep(2);

    echo "scanner examples\n";
    $scanner = $client->scanner_open($namespace, "thrift_test",
        new Hypertable_ThriftGen_ScanSpec(array('revs'=> 1)));

    $cells = $client->scanner_get_cells($scanner);

    while (!empty($cells)) {
      print_r($cells);
      $cells = $client->scanner_get_cells($scanner);
    }
    $client->namespace_close($namespace);
