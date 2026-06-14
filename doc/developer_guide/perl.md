# Perl

## Table of Contents

### Introduction

This document presents example Perl code that excercises the Thrift API. To quickly get Hypertable up and running on a single machine so that you can try out these examples, see [Hypertable Standalone Installation](../installation/quick_start_standalone.md). The source code for all of the examples in this document, along with the build and run scripts, can be found in [hypertable_api_example.tgz](http://hypertable.com/pub/hypertable_api_example.tgz).

### Environment setup and running

The following bash script illustrates how to setup an enviroment and run a Hypertable perl thrift client program.

    HYPERTABLE_HOME=/opt/hypertable/current

    perl -I . -I $HYPERTABLE_HOME/lib/perl/gen-perl -I $HYPERTABLE_HOME/lib/perl hypertable_api_test.pl

### Program boilerplate

The following use statements are required for the code examples in this document.

    use Hypertable::ThriftClient;
    use Error qw(:try);
    use Time::Local;
    use strict;
    use warnings;

### Creating a thrift client

All of the examples in this document reference a pointer to a Thrift client object. The following code snippet illustrates how to create a Thrift client object connected to a ThriftBroker listening on the default port (15867) on localhost. To change the ThriftBroker location, just change "localhost" to the domain name of the machine on which the ThriftBroker is running.

    my $client = new Hypertable::ThriftClient("localhost", 15867);

### Basics

The following code snippet illustrates the basics of working with namespaces and tables. The APIs introduced include [namespace_exists](../reference_manual/thrift_api.md#namespaceexists), [namespace_create](../reference_manual/thrift_api.md#namespacecreate), [namespace_open](../reference_manual/thrift_api.md#namespaceopen), [namespace_get_listing](../reference_manual/thrift_api.md#namespacegetlisting), [namespace_close](../reference_manual/thrift_api.md#namespaceclose), [table_drop](../reference_manual/thrift_api.md#tabledrop), and [table_create](../reference_manual/thrift_api.md#tablecreate).

    try {

        if (!$client->namespace_exists("test")) {
            $client->namespace_create("test");
        }

        my $ns = $client->namespace_open("test");

        my $if_exists = 1;

        $client->table_drop($ns, "Fruits", $if_exists);

        my %cf_specs;
        my $cf_spec;
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "genus"});
        $cf_specs{'genus'} = $cf_spec;
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "description"});
        $cf_specs{'description'} = $cf_spec;
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "tag"});
        $cf_specs{'tag'} = $cf_spec;

        my $schema = new Hypertable::ThriftGen::Schema({column_families => \%cf_specs});

        $client->table_create($ns, "Fruits", $schema);

        $client->namespace_create("/test/sub");

        my $result = $client->namespace_get_listing($ns);

        for my $entry (@{$result}) {
            print $entry->name;
            if ($entry->is_namespace) {
                print "\t(dir)";
            }
            print "\n";
        }

        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    Fruits
    sub	(dir)

### Convenience APIs

####  set_cells

The following code snippet illustrates how to create [Cell](../reference_manual/thrift_api.md#cell) objects and insert them with the [set_cells](../reference_manual/thrift_api.md#setcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](perl.md#basics) example.

    try {
        my $ns = $client->namespace_open("test");

        my @cells;
        my ($value, $key, $cell);

        $key = new Hypertable::ThriftGen::Key({row => 'apple',
                                               column_family => 'genus'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => 'Malus'});
        push(@cells, $cell);

        $key = new Hypertable::ThriftGen::Key({row => 'apple',
                                               column_family => 'description'});

        $value = 'The apple is the pomaceous fruit of the apple tree.';
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => $value});
        push(@cells, $cell);

        $key = new Hypertable::ThriftGen::Key({row => 'apple',
                                               column_family => 'tag',
                                               column_qualifier => 'cruncy'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key});
        push(@cells, $cell);

        $client->set_cells($ns, "Fruits", \@cells);

        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

####  get_cells

The following code snippet illustrates how to fetch cells with the [get_cells](../reference_manual/thrift_api.md#getcells) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](perl.md#basics) example and makes use of the _print_cell_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions).

    try {
        my $ns = $client->namespace_open("test");

        my @columns;
        push(@columns, "description");
        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns});

        my $result = $client->get_cells($ns, "Fruits", $ss);

        for my $cell (@{$result}) {
            print_cell($cell);
        }

        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=apple column_family=description column_qualifier=} value=The apple is the pomaceous fruit of the apple tree.

####  set_cells_as_arrays

The following code snippet illustrates how to create [CellAsArray](../reference_manual/thrift_api.md#cellasarray) objects and insert them with the [set_cells_as_arrays](../reference_manual/thrift_api.md#setcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](perl.md#basics) example.

    try {
        my $ns = $client->namespace_open("test");

        my @cells_as_arrays;
        my $cell_as_array;
        my $value;

        $cell_as_array = ["orange", "genus", "", "Citrus"];
        push(@cells_as_arrays, $cell_as_array);

        $value = "The orange (specifically, the sweet orange) is the fruit of " .
            "the citrus species Citrus × sinensis in the family Rutaceae.";
        $cell_as_array = ["orange", "description", "", $value];
        push(@cells_as_arrays, $cell_as_array);

        $cell_as_array = ["orange", "tag", "juicy", ""];
        push(@cells_as_arrays, $cell_as_array);

        $client->set_cells_as_arrays($ns, "Fruits", \@cells_as_arrays);

        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

####  get_cells_as_arrays

The following code snippet illustrates how to fetch cells with the [get_cells_as_arrays](../reference_manual/thrift_api.md#getcellsasarrays) API. It assumes that the _Fruits_ table in the _test_ namespace has been created as illustrated in the [Basics](perl.md#basics) example and makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions).

    try {
        my $ns = $client->namespace_open("test");

        my @columns;
        push(@columns, "description");
        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns});

        my $result = $client->get_cells_as_arrays($ns, "Fruits", $ss);

        for my $cell_as_array (@{$result}) {
            print_cell_as_array(@{$cell_as_array});
        }

        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {CellAsArray key={Key row=apple column_family=description column_qualifier=} value=The apple is the pomaceous fruit of the apple tree.
    {CellAsArray key={Key row=orange column_family=description column_qualifier=} value=The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus × sinensis in the family Rutaceae.

### Creating a table

The following code snippet illustrates how to create a table with the [table_create](../reference_manual/thrift_api.md#tablecreate) API. It introduces the API classes [Schema](../reference_manual/thrift_api.md#schema), [AccessGroupSpec](../reference_manual/thrift_api.md#accessgroupspec), [AccessGroupOptions](../reference_manual/thrift_api.md#accessgroupoptions), [ColumnFamilySpec](../reference_manual/thrift_api.md#columnfamilyspec), and [ColumnFamilyOptions](../reference_manual/thrift_api.md#columnfamilyoptions).

    try {
        my $ns = $client->namespace_open("test");

        my (%ag_specs, %cf_specs);
        my ($ag_spec, $ag_options, $cf_spec, $cf_options);

        # table defaults
        my $table_ag_defaults = new Hypertable::ThriftGen::AccessGroupOptions({blocksize => 65536});
        my $table_cf_defaults = new Hypertable::ThriftGen::ColumnFamilyOptions({max_versions => 1});

        # Access group "ag_normal"
        $cf_options = new Hypertable::ThriftGen::ColumnFamilyOptions({max_versions => 2});
        $ag_spec = new Hypertable::ThriftGen::AccessGroupSpec({name => 'ag_normal',
                                                               defaults => $cf_options});
        $ag_specs{'ag_normal'} = $ag_spec;

        # Column "a"
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "a",
                                                                access_group => "ag_normal",
                                                                value_index => 1,
                                                                qualifier_index => 1});
        $cf_specs{'a'} = $cf_spec;

        # Column "b"
        $cf_options = new Hypertable::ThriftGen::ColumnFamilyOptions({max_versions => 3});
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "b",
                                                                access_group => "ag_normal",
                                                                options => $cf_options});
        $cf_specs{'b'} = $cf_spec;

        # Access group "ag_fast"
        $ag_options = new Hypertable::ThriftGen::AccessGroupOptions({in_memory => 1,
                                                                     blocksize => 131072});
        $ag_spec = new Hypertable::ThriftGen::AccessGroupSpec({name => 'ag_fast',
                                                               options => $ag_options});
        $ag_specs{'ag_fast'} = $ag_spec;

        # Column "c"
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "c",
                                                                access_group => "ag_fast"});
        $cf_specs{'c'} = $cf_spec;

        # Access group "ag_secure"
        $ag_options = new Hypertable::ThriftGen::AccessGroupOptions({replication => 5});
        $ag_spec = new Hypertable::ThriftGen::AccessGroupSpec({name => 'ag_secure',
                                                               options => $ag_options});
        $ag_specs{'ag_secure'} = $ag_spec;

        # Column "d"
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "d",
                                                                access_group => "ag_secure"});
        $cf_specs{'d'} = $cf_spec;

        # Access group "ag_counter"
        $cf_options = new Hypertable::ThriftGen::ColumnFamilyOptions({max_versions => 0,
                                                                      counter => 1});
        $ag_spec = new Hypertable::ThriftGen::AccessGroupSpec({name => 'ag_counter',
                                                               defaults => $cf_options});
        $ag_specs{'ag_counter'} = $ag_spec;

        # Column "e"
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "e",
                                                                access_group => "ag_counter"});
        $cf_specs{'e'} = $cf_spec;

        # Column "f"
        $cf_options = new Hypertable::ThriftGen::ColumnFamilyOptions({counter => 0});
        $cf_spec = new Hypertable::ThriftGen::ColumnFamilySpec({name => "f",
                                                                access_group => "ag_counter",
                                                                options => $cf_options});
        $cf_specs{'f'} = $cf_spec;

        my $schema = new Hypertable::ThriftGen::Schema({access_group_defaults => $table_ag_defaults,
                                                        column_family_defaults => $table_cf_defaults,
                                                        access_groups => \%ag_specs,
                                                        column_families => \%cf_specs});

        $client->table_create($ns, "TestTable", $schema);

        my $result = $client->hql_query($ns, "SHOW CREATE TABLE TestTable");

        for my $line (@{$result->results}) {
            print $line;
        }

        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

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

The following code snippet illustrates how to alter a table with the [table_alter](../reference_manual/thrift_api.md#tablealter) API. It assumes that the table _TestTable_ has been created as in the [Creating a table](perl.md#creating-a-table) example.

    try {
        my $ns = $client->namespace_open("test");

        my $schema = $client->get_schema($ns, "TestTable");

        my $cf_spec;

        # Rename column "b" to "z"
        my $column_families = $schema->column_families;
        $cf_spec = $column_families->{'b'};
        delete $column_families->{'b'};
        $cf_spec->{name} = 'z';
        $column_families->{'z'} = $cf_spec;

        # Add column "g"
        $cf_spec =
            new Hypertable::ThriftGen::ColumnFamilySpec({name => "g",
                                                         access_group => "ag_counter"});
        $schema->column_families->{'g'} = $cf_spec;

        $client->table_alter($ns, "TestTable", $schema);

        my $result = $client->hql_query($ns, "SHOW CREATE TABLE TestTable");

        for my $line (@{$result->results}) {
            print $line;
        }

        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

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
        my $ns = $client->namespace_open("test");

        my $mutator = $client->mutator_open($ns, "Fruits", 0, 0);
        my ($timestamp, $description, $key, $cell);
        my @cells;

        # Auto-assigned timestamps
        $key = new Hypertable::ThriftGen::Key({row => 'lemon',
                                               column_family => 'genus'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => 'Citrus'});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => 'lemon',
                                               column_family => 'tag',
                                               column_qualifier => 'bitter'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => 'lemon',
                                               column_family => 'description'});
        $description = "The lemon (Citrus × limon) is a small evergreen " .
            "tree native to Asia.";
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => $description});
        push(@cells, $cell);

        $client->mutator_set_cells($mutator, \@cells);
        $client->mutator_flush($mutator);

        # Explicitly-supplied timestamps
        @cells = ();
        $timestamp = timelocal(15,27,16,6,5,2014) * 1000000000;
        $key = new Hypertable::ThriftGen::Key({row => 'mango',
                                               column_family => 'genus',
                                               timestamp => $timestamp});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => 'Mangifera'});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => 'mango',
                                               column_family => 'tag',
                                               column_qualifier => 'sweet',
                                               timestamp => $timestamp});
        $cell = new Hypertable::ThriftGen::Cell({key => $key});
        push(@cells, $cell);
        $description = "Mango is one of the delicious seasonal fruits grown " .
            "in the tropics.";
        $key = new Hypertable::ThriftGen::Key({row => 'mango',
                                               column_family => 'description',
                                               timestamp => $timestamp});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => $description});
        push(@cells, $cell);
        $timestamp = timelocal(16,27,16,6,5,2014) * 1000000000;
        $description = "The mango is a juicy stone fruit belonging to the " .
            "genus Mangifera, consisting of numerous tropical fruiting trees," .
            "that are cultivated mostly for edible fruits.";
        $key = new Hypertable::ThriftGen::Key({row => 'mango',
                                               column_family => 'description',
                                               timestamp => $timestamp});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => $description});
        push(@cells, $cell);
        $client->mutator_set_cells($mutator, \@cells);
        $client->mutator_flush($mutator);

        # Delete cells
        @cells = ();
        my $flag = Hypertable::ThriftGen::KeyFlag::DELETE_ROW;
        $key = new Hypertable::ThriftGen::Key({row => 'apple',
                                               flag => $flag});
        $cell = new Hypertable::ThriftGen::Cell({key => $key});
        push(@cells, $cell);
        $flag = Hypertable::ThriftGen::KeyFlag::DELETE_CELL;
        $timestamp = timelocal(15,27,16,6,5,2014) * 1000000000;
        $key = new Hypertable::ThriftGen::Key({row => 'mango',
                                               column_family => 'description',
                                               timestamp => $timestamp,
                                               flag => $flag});
        $cell = new Hypertable::ThriftGen::Cell({key => $key});
        push(@cells, $cell);
        $client->mutator_set_cells($mutator, \@cells);
        $client->mutator_flush($mutator);
        $client->mutator_close($mutator);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

### Scanner

The following examples illustrate how to query a table using a scanner. The APIs introduced include the [scanner_open](../reference_manual/thrift_api.md#scanneropen), [scanner_get_cells](../reference_manual/thrift_api.md#scannergetcells), and [scanner_close](../reference_manual/thrift_api.md#scannerclose) functions, and the [ScanSpec](../reference_manual/thrift_api.md#scanspec) and [RowInterval](../reference_manual/thrift_api.md#rowinterval) classes. The example makes use of the _print_cell_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions).

####  Full table scan

The following code illustrates how to do a full table scan using the scanner APIs.

    try {
        my $ns = $client->namespace_open("test");
        my $ss = new Hypertable::ThriftGen::ScanSpec();
        my $scanner = $client->scanner_open($ns, "Fruits", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=lemon column_family=description column_qualifier=} value=The lemon (Citrus × limon) is a small evergreen tree native to Asia.
    {Cell key={Key row=lemon column_family=genus column_qualifier=} value=Citrus
    {Cell key={Key row=lemon column_family=tag column_qualifier=bitter} value=[NULL]
    {Cell key={Key row=mango column_family=description column_qualifier=} value=The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees,that are cultivated mostly for edible fruits.
    {Cell key={Key row=mango column_family=genus column_qualifier=} value=Mangifera
    {Cell key={Key row=mango column_family=tag column_qualifier=sweet} value=[NULL]
    {Cell key={Key row=orange column_family=description column_qualifier=} value=The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus × sinensis in the family Rutaceae.
    {Cell key={Key row=orange column_family=genus column_qualifier=} value=Citrus
    {Cell key={Key row=orange column_family=tag column_qualifier=juicy} value=[NULL]

####  Restricted scan with ScanSpec

The following code illustrates how to do a table scan using a ScanSpec. It makes use of the _print_cell_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions).

    try {
        my $ns = $client->namespace_open("test");
        my $ri = new Hypertable::ThriftGen::RowInterval({start_row => 'lemon',
                                                         start_inclusive => 1,
                                                         end_row => 'orange',
                                                         end_inclusive => 0});
        my @row_intervals = ( $ri );
        my @columns = ( "genus", "tag:bitter", "tag:sweet" );
        my $ss = new Hypertable::ThriftGen::ScanSpec({row_intervals => \@row_intervals,
                                                      columns => \@columns,
                                                      versions => 1});
        my $scanner = $client->scanner_open($ns, "Fruits", $ss);

        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=lemon column_family=genus column_qualifier=} value=Citrus
    {Cell key={Key row=lemon column_family=tag column_qualifier=bitter} value=[NULL]
    {Cell key={Key row=mango column_family=genus column_qualifier=} value=Mangifera
    {Cell key={Key row=mango column_family=tag column_qualifier=sweet} value=[NULL]

### HQL

####  hql_query

The following code illustrates how to issue HQL commands with the [hql_query](../reference_manual/thrift_api.md#hqlquery) API. It also introduces the [HqlResult](../reference_manual/thrift_api.md#hqlresult) class.

    try {
        my $ns = $client->namespace_open("test");

        my $result = $client->hql_query($ns, "GET LISTING");

        for my $line (@{$result->results}) {
            print $line . "\n";
        }

        $result = $client->hql_query($ns, "SELECT * from Fruits WHERE ROW = 'mango'");

        for my $cell (@{$result->cells}) {
            print_cell($cell);
        }

        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    Fruits
    TestTable
    ^TestTable
    ^^TestTable
    sub	(namespace)
    {Cell key={Key row=mango column_family=description column_qualifier=} value=The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees,that are cultivated mostly for edible fruits.
    {Cell key={Key row=mango column_family=genus column_qualifier=} value=Mangifera
    {Cell key={Key row=mango column_family=tag column_qualifier=sweet} value=[NULL]

####  hql_query_as_arrays

The following code illustrates how to issue an HQL query with the [hql_query_as_arrays](../reference_manual/thrift_api.md#hqlqueryasarrays) API. It introduces the [HqlResultAsArrays](../reference_manual/thrift_api.md#hqlresultasarrays) class and makes use of the _print_cell_as_array_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions).

    try {
        my $ns = $client->namespace_open("test");
        my $command = "SELECT * from Fruits WHERE ROW = 'lemon'";
        my $result_as_arrays = $client->hql_query_as_arrays($ns, $command);
        for my $cell_as_array (@{$result_as_arrays->cells}) {
            print_cell_as_array(@{$cell_as_array});
        }
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {CellAsArray key={Key row=lemon column_family=description column_qualifier=} value=The lemon (Citrus × limon) is a small evergreen tree native to Asia.
    {CellAsArray key={Key row=lemon column_family=genus column_qualifier=} value=Citrus
    {CellAsArray key={Key row=lemon column_family=tag column_qualifier=bitter} value=

####  hql_exec (mutator)

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a mutator.

    try {
        my $ns = $client->namespace_open("test");
        my $command = "INSERT INTO Fruits VALUES ('strawberry', 'genus', " .
            "'Fragaria'), ('strawberry', 'tag:fibrous', ''), ('strawberry', " .
            "'description', 'The garden strawberry is a widely grown hybrid " .
            "species of the genus Fragaria')";

        my $result = $client->hql_exec($ns, $command, 1, 0);
        my ($description, $key, $cell);
        my @cells;

        $key = new Hypertable::ThriftGen::Key({row => 'pineapple',
                                               column_family => 'genus'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => 'Ananas'});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => 'pineapple',
                                               column_family => 'tag',
                                               column_qualifier => 'acidic'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => 'pineapple',
                                               column_family => 'description'});
        $description = "The pineapple (Ananas comosus) is a tropical plant " .
            "with edible multiple fruit consisting of coalesced berries.";
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => $description});
        push(@cells, $cell);

        $client->mutator_set_cells($result->{mutator}, \@cells);
        $client->mutator_flush($result->{mutator});
        $client->mutator_close($result->{mutator});
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

####  hql_exec (scanner}

The following code illustrates how to issue an HQL command with the [hql_exec](../reference_manual/thrift_api.md#hqlexec) API that returns a scanner. It makes use of the _print_cell_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions).

    try {
        my $ns = $client->namespace_open("test");
        my $result =
            $client->hql_exec($ns, "SELECT * from Fruits", 0, 1);
        while (1) {
            my $cells = $client->scanner_get_cells($result->{scanner});
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($result->{scanner});
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=lemon column_family=description column_qualifier=} value=The lemon (Citrus × limon) is a small evergreen tree native to Asia.
    {Cell key={Key row=lemon column_family=genus column_qualifier=} value=Citrus
    {Cell key={Key row=lemon column_family=tag column_qualifier=bitter} value=[NULL]
    {Cell key={Key row=mango column_family=description column_qualifier=} value=The mango is a juicy stone fruit belonging to the genus Mangifera, consisting of numerous tropical fruiting trees,that are cultivated mostly for edible fruits.
    {Cell key={Key row=mango column_family=genus column_qualifier=} value=Mangifera
    {Cell key={Key row=mango column_family=tag column_qualifier=sweet} value=[NULL]
    {Cell key={Key row=orange column_family=description column_qualifier=} value=The orange (specifically, the sweet orange) is the fruit of the citrus species Citrus × sinensis in the family Rutaceae.
    {Cell key={Key row=orange column_family=genus column_qualifier=} value=Citrus
    {Cell key={Key row=orange column_family=tag column_qualifier=juicy} value=[NULL]
    {Cell key={Key row=pineapple column_family=description column_qualifier=} value=The pineapple (Ananas comosus) is a tropical plant with edible multiple fruit consisting of coalesced berries.
    {Cell key={Key row=pineapple column_family=genus column_qualifier=} value=Ananas
    {Cell key={Key row=pineapple column_family=tag column_qualifier=acidic} value=[NULL]
    {Cell key={Key row=strawberry column_family=description column_qualifier=} value=The garden strawberry is a widely grown hybrid species of the genus Fragaria
    {Cell key={Key row=strawberry column_family=genus column_qualifier=} value=Fragaria
    {Cell key={Key row=strawberry column_family=tag column_qualifier=fibrous} value=[NULL]

### Secondary indices

This section describes how to query tables using secondary indices. APIs introduced include the [ColumnPredicate](../reference_manual/thrift_api.md#column_predicate) class and the _column_predicates_ and the _and_column_predicates_ members of the [ScanSpec](../reference_manual/thrift_api.md#scanspec) class. The examples make use of the _print_cell_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions) and assume that the table _products_ has been created and loaded with the following HQL commands.

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
        my $ns = $client->namespace_open("test");

        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "section",
                                                        operation => $operation,
                                                        value => "books"});
        my @column_predicates = ( $column_predicate );
        my @columns = ( "title" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      column_predicates => \@column_predicates});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=0307743659 column_family=title column_qualifier=} value=The Shining Mass Market Paperback
    {Cell key={Key row=0321321928 column_family=title column_qualifier=} value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    {Cell key={Key row=0321776402 column_family=title column_qualifier=} value=C++ Primer Plus (6th Edition) (Developer's Library)

####  Value index (exact match with qualifier)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title FROM products WHERE info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");

        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::EXACT_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "actor",
                                                        operation => $operation,
                                                        value => "Jack Nicholson"});
        my @column_predicates = ( $column_predicate );
        my @columns = ( "title" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      column_predicates => \@column_predicates});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=B00002VWE0 column_family=title column_qualifier=} value=Five Easy Pieces (1970)
    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier=} value=The Shining (1980)

####  Value index (prefix match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =^ 'Addison-Wesley';

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");
        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::PREFIX_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "publisher",
                                                        operation => $operation,
                                                        value => "Addison-Wesley"});
        my @column_predicates = ( $column_predicate );
        my @columns = ( "title", "info:publisher" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      column_predicates => \@column_predicates});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=0321321928 column_family=title column_qualifier=} value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    {Cell key={Key row=0321321928 column_family=info column_qualifier=publisher} value=Addison-Wesley Professional; 1 edition (March 10, 2005)
    {Cell key={Key row=0321776402 column_family=title column_qualifier=} value=C++ Primer Plus (6th Edition) (Developer's Library)
    {Cell key={Key row=0321776402 column_family=info column_qualifier=publisher} value=Addison-Wesley Professional; 6 edition (October 28, 2011)

####  Value index (regex match)

The following HQL query which leverages the value index of the _info_ column:

    SELECT title, info:publisher
      FROM products
      WHERE info:publisher =~ /^Addison-Wesley/;

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");
        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::REGEX_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "publisher",
                                                        operation => $operation,
                                                        value => "^Addison-Wesley"});
        my @column_predicates = ( $column_predicate );
        my @columns = ( "title", "info:publisher" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      column_predicates => \@column_predicates});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=0321321928 column_family=title column_qualifier=} value=C++ Common Knowledge: Essential Intermediate Programming [Paperback]
    {Cell key={Key row=0321321928 column_family=info column_qualifier=publisher} value=Addison-Wesley Professional; 1 edition (March 10, 2005)
    {Cell key={Key row=0321776402 column_family=title column_qualifier=} value=C++ Primer Plus (6th Edition) (Developer's Library)
    {Cell key={Key row=0321776402 column_family=info column_qualifier=publisher} value=Addison-Wesley Professional; 6 edition (October 28, 2011)

####  Qualifier index (exists)

The following HQL query which leverages the qualifier index of the _info_ column:

    SELECT title FROM products WHERE Exists(info:studio);

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");
        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "studio",
                                                        operation => $operation});
        my @column_predicates = ( $column_predicate );
        my @columns = ( "title" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      column_predicates => \@column_predicates});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=B00002VWE0 column_family=title column_qualifier=} value=Five Easy Pieces (1970)
    {Cell key={Key row=B000Q66J1M column_family=title column_qualifier=} value=2001: A Space Odyssey [Blu-ray]
    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier=} value=The Shining (1980)

####  Qualifier index (exists regex prefix match)

The following HQL query which leverages the qualifier index of the _category_ column:

    SELECT title FROM products WHERE Exists(category:/^\/Movies/);

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");
        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_REGEX_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "category",
                                                        column_qualifier => "^/Movies",
                                                        operation => $operation});
        my @column_predicates = ( $column_predicate );
        my @columns = ( "title" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      column_predicates => \@column_predicates});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=B00002VWE0 column_family=title column_qualifier=} value=Five Easy Pieces (1970)
    {Cell key={Key row=B000Q66J1M column_family=title column_qualifier=} value=2001: A Space Odyssey [Blu-ray]
    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier=} value=The Shining (1980)

####  Value index (OR query)

The following HQL query performs a boolean _OR_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen P/ OR info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");
        my @column_predicates;

        # info:author =~ /^Stephen P/
        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::REGEX_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "author",
                                                        operation => $operation,
                                                        value => "^Stephen P"});
        push (@column_predicates, $column_predicate);

        # info:publisher =^ "Anchor"
        $operation = Hypertable::ThriftGen::ColumnPredicateOperation::PREFIX_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "publisher",
                                                        operation => $operation,
                                                        value => "Anchor"});
        push (@column_predicates, $column_predicate);

        my @columns = ( "title" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      column_predicates => \@column_predicates});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=0307743659 column_family=title column_qualifier=} value=The Shining Mass Market Paperback
    {Cell key={Key row=0321776402 column_family=title column_qualifier=} value=C++ Primer Plus (6th Edition) (Developer's Library)

####  Value index (AND query)

The following HQL query performs a boolean _AND_ combination of two lookups against the value index of the _info_ column:

    SELECT title
      FROM products
      WHERE info:author =~ /^Stephen [PK]/ AND info:publisher =^ 'Anchor';

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");
        my @column_predicates;

        # info:author =~ /^Stephen [PK]/
        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::REGEX_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "author",
                                                        operation => $operation,
                                                        value => "^Stephen [PK]"});
        push (@column_predicates, $column_predicate);

        # info:publisher =^ "Anchor"
        $operation = Hypertable::ThriftGen::ColumnPredicateOperation::PREFIX_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "publisher",
                                                        operation => $operation,
                                                        value => "Anchor"});
        push (@column_predicates, $column_predicate);

        my @columns = ( "title" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      column_predicates => \@column_predicates,
                                                      and_column_predicates => 1});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=0307743659 column_family=title column_qualifier=} value=The Shining Mass Market Paperback

####  Value index (AND row interval)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW interval:

    SELECT title
      FROM products
      WHERE ROW > 'B00002VWE0' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");

        # ROW > 'B00002VWE0'
        my $ri = new Hypertable::ThriftGen::RowInterval({start_row => "B00002VWE0",
                                                         start_inclusive => 0});
        my @row_intervals = ( $ri );

        # info:actor = 'Jack Nicholson'
        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::EXACT_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "actor",
                                                        operation => $operation,
                                                        value => "Jack Nicholson"});
        my @column_predicates = ( $column_predicate );

        my @columns = ( "title" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      row_intervals => \@row_intervals,
                                                      column_predicates => \@column_predicates,
                                                      and_column_predicates => 1});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier=} value=The Shining (1980)

####  Value index (AND row prefix)

The following HQL query performs a boolean _AND_ combination of a lookup against the value index of the _info_ column and a ROW prefix interval:

    SELECT title
      FROM products
      WHERE ROW =^ 'B' AND info:actor = 'Jack Nicholson';

can be issued programmatically with the following code snippet.

    try {
        my $ns = $client->namespace_open("test");

        # ROW =^ 'B'
        my $ri = new Hypertable::ThriftGen::RowInterval({start_row => "B",
                                                         start_inclusive => 1,
                                                         end_row => "C",
                                                         end_inclusive => 0});
        my @row_intervals = ( $ri );

        # info:actor = 'Jack Nicholson'
        my $operation = Hypertable::ThriftGen::ColumnPredicateOperation::EXACT_MATCH |
            Hypertable::ThriftGen::ColumnPredicateOperation::QUALIFIER_EXACT_MATCH;
        my $column_predicate =
            new Hypertable::ThriftGen::ColumnPredicate({column_family => "info",
                                                        column_qualifier => "actor",
                                                        operation => $operation,
                                                        value => "Jack Nicholson"});
        my @column_predicates = ( $column_predicate );

        my @columns = ( "title" );

        my $ss = new Hypertable::ThriftGen::ScanSpec({columns => \@columns,
                                                      row_intervals => \@row_intervals,
                                                      column_predicates => \@column_predicates,
                                                      and_column_predicates => 1});
        my $scanner = $client->scanner_open($ns, "products", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=B00002VWE0 column_family=title column_qualifier=} value=Five Easy Pieces (1970)
    {Cell key={Key row=B002VWNIDG column_family=title column_qualifier=} value=The Shining (1980)

### Asynchronous APIs

This section describes how to use the asynchronous APIs. The examples assume that tables _Profile_ and _Session_ are created and loaded with the following HQL commands.

    CREATE TABLE Profile (info, last_access MAX_VERSIONS 1);

    CREATE TABLE Session (user_id, page_hit);

    INSERT INTO Profile
      VALUES ('1', 'info:name', 'Joe'), ('2', 'info:name', 'Sue');

####  Async mutator

The code snippet below illustrates how to insert cells into multiple tables simultaneously using an asynchronous mutator. The APIs introduced include the [future_open](../reference_manual/thrift_api.md#futureopen), [future_get_result](../reference_manual/thrift_api.md#futuregetresult), [future_close](../reference_manual/thrift_api.md#futureclose), [async_mutator_open](../reference_manual/thrift_api.md#asyncmutatoropen), [async_mutator_set_cells](../reference_manual/thrift_api.md#asyncmutatorsetcells), [async_mutator_flush](../reference_manual/thrift_api.md#asyncmutatorflush), and [async_mutator_close](../reference_manual/thrift_api.md#asyncmutatorclose) functions and the [Result](../reference_manual/thrift_api.md#result) class.

    try {
        my $ns = $client->namespace_open("test");

        my $ff = $client->future_open(0);
        my $profile_mutator = $client->async_mutator_open($ns, "Profile", $ff, 0);
        my $session_mutator = $client->async_mutator_open($ns, "Session", $ff, 0);
        my ($key, $cell);
        my @cells;

        $key = new Hypertable::ThriftGen::Key({row => '1',
                                               column_family => 'last_access'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "2014-06-13 16:06:09"});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => '2',
                                               column_family => 'last_access'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "2014-06-13 16:06:10"});
        push(@cells, $cell);
        $client->async_mutator_set_cells($profile_mutator, \@cells);

        @cells = ();
        $key = new Hypertable::ThriftGen::Key({row => "0001-200238",
                                               column_family => 'user_id',
                                               column_qualifier => "1"});
        $cell = new Hypertable::ThriftGen::Cell({key => $key});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => "0001-200238",
                                               column_family => 'page_hit'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "/index.html"});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => "0002-383049",
                                               column_family => 'user_id',
                                               column_qualifier => "2"});
        $cell = new Hypertable::ThriftGen::Cell({key => $key});
        push(@cells, $cell);
        $key = new Hypertable::ThriftGen::Key({row => "0002-383049",
                                               column_family => 'page_hit'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "/foo/bar.html"});
        push(@cells, $cell);
        $client->async_mutator_set_cells($session_mutator, \@cells);

        $client->async_mutator_flush($profile_mutator);
        $client->async_mutator_flush($session_mutator);

        my $result_count = 0;
        while (1) {
            my $result = $client->future_get_result($ff, 0);
            if ($result->is_empty) {
                last;
            }
            $result_count++;
            if ($result->is_error) {
                print "Async mutator error:  " . $result->error_msg;
                exit 1;
            }
            if ($result->id == $profile_mutator) {
                print "Result is from Profile mutation\n";
            }
            elsif ($result->id == $session_mutator) {
                print "Result is from Session mutation\n";
            }
        }

        print "result count = $result_count\n";
        $client->async_mutator_close($profile_mutator);
        $client->async_mutator_close($session_mutator);
        $client->future_close($ff);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    Result is from Profile mutation
    Result is from Session mutation
    result count = 2

####  Async scanner (Result)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [Result](../reference_manual/thrift_api.md#result) object. The APIs introduced include the [async_scanner_open](../reference_manual/thrift_api.md#asyncscanneropen) and [async_scanner_close](../reference_manual/thrift_api.md#asyncscannerclose) functions. The code makes use of the _print_cell_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions).

    try {
        my $ns = $client->namespace_open("test");
        my $ff = $client->future_open(0);

        my $ri = new Hypertable::ThriftGen::RowInterval({start_row => "1",
                                                         start_inclusive => 1,
                                                         end_row => "1",
                                                         end_inclusive => 1});
        my @row_intervals = ( $ri );
        my $ss = new Hypertable::ThriftGen::ScanSpec({row_intervals => \@row_intervals});
        my $profile_scanner = $client->async_scanner_open($ns, "Profile", $ff, $ss);

        $ri = new Hypertable::ThriftGen::RowInterval({start_row => "0001-200238",
                                                         start_inclusive => 1,
                                                         end_row => "0001-200238",
                                                         end_inclusive => 1});
        @row_intervals = ( $ri );
        $ss = new Hypertable::ThriftGen::ScanSpec({row_intervals => \@row_intervals});
        my $session_scanner = $client->async_scanner_open($ns, "Session", $ff, $ss);

        while (1) {
            my $result = $client->future_get_result($ff, 0);
            if ($result->is_empty) {
                last;
            }
            if ($result->is_error) {
                print "Async scanner error:  " . $result->error_msg;
                exit 1;
            }

            $result->is_scan || die "Result is not from scan";
            $result->id == $profile_scanner || $result->id == $session_scanner ||
                die "ID does not match any of the scanners";

            if ($result->id == $profile_scanner) {
                print "Result is from Profile scan\n";
            }
            elsif ($result->id == $session_scanner) {
                print "Result is from Session scan\n";
            }

            for my $cell (@{$result->cells}) {
                print_cell($cell);
            }
        }

        $client->async_scanner_close($profile_scanner);
        $client->async_scanner_close($session_scanner);
        $client->future_close($ff);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    Result is from Profile scan
    {Cell key={Key row=1 column_family=info column_qualifier=name} value=Joe
    {Cell key={Key row=1 column_family=last_access column_qualifier=} value=2014-06-13 16:06:09
    Result is from Session scan
    {Cell key={Key row=0001-200238 column_family=user_id column_qualifier=1} value=[NULL]
    {Cell key={Key row=0001-200238 column_family=page_hit column_qualifier=} value=/index.html

####  Async scanner (ResultAsArrays)

The code snippet below illustrates how to query two tables simultaneously using asynchronous scanners and a future object that returns a [ResultAsArrays](../reference_manual/thrift_api.md#resultasarrays) object. This example introduces the [future_get_result_as_arrays](../reference_manual/thrift_api.md#futuregetresultasarrays) API. The code makes use of the _print_cell_as_arrays_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions)

    try {
        my $ns = $client->namespace_open("test");
        my $ff = $client->future_open(0);

        my $ri = new Hypertable::ThriftGen::RowInterval({start_row => "1",
                                                         start_inclusive => 1,
                                                         end_row => "1",
                                                         end_inclusive => 1});
        my @row_intervals = ( $ri );
        my $ss = new Hypertable::ThriftGen::ScanSpec({row_intervals => \@row_intervals});
        my $profile_scanner = $client->async_scanner_open($ns, "Profile", $ff, $ss);

        $ri = new Hypertable::ThriftGen::RowInterval({start_row => "0001-200238",
                                                         start_inclusive => 1,
                                                         end_row => "0001-200238",
                                                         end_inclusive => 1});
        @row_intervals = ( $ri );
        $ss = new Hypertable::ThriftGen::ScanSpec({row_intervals => \@row_intervals});
        my $session_scanner = $client->async_scanner_open($ns, "Session", $ff, $ss);

        while (1) {
            my $result_as_arrays = $client->future_get_result_as_arrays($ff, 0);
            if ($result_as_arrays->is_empty) {
                last;
            }
            if ($result_as_arrays->is_error) {
                print "Async scanner error:  " . $result_as_arrays->error_msg;
                exit 1;
            }

            $result_as_arrays->is_scan || die "Result is not from scan";
            $result_as_arrays->id == $profile_scanner ||
                $result_as_arrays->id == $session_scanner ||
                die "ID does not match any of the scanners";

            if ($result_as_arrays->id == $profile_scanner) {
                print "Result is from Profile scan\n";
            }
            elsif ($result_as_arrays->id == $session_scanner) {
                print "Result is from Session scan\n";
            }

            for my $cell_as_array (@{$result_as_arrays->cells}) {
                print_cell_as_array(@{$cell_as_array});
            }
        }

        $client->async_scanner_close($profile_scanner);
        $client->async_scanner_close($session_scanner);
        $client->future_close($ff);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    Result is from Profile scan
    {CellAsArray key={Key row=1 column_family=info column_qualifier=name} value=Joe
    {CellAsArray key={Key row=1 column_family=last_access column_qualifier=} value=2014-06-13 16:06:09
    Result is from Session scan
    {CellAsArray key={Key row=0001-200238 column_family=user_id column_qualifier=1} value=
    {CellAsArray key={Key row=0001-200238 column_family=page_hit column_qualifier=} value=/index.html

### Atomic counters

This section describes how to use atomic counters. The examples make use of the _print_cell_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions) and assume that a  _Hits_ table has been created with the following HQL command.

    CREATE TABLE Hits (count COUNTER);

####  Increment

The code snippet below illustrates how to increment per-second hit counts for pages of a website.

    try {
        my $ns = $client->namespace_open("test");
        my $mutator = $client->mutator_open($ns, "Hits", 0, 0);

        my ($key, $cell);
        my @cells;

        $key = new Hypertable::ThriftGen::Key({row => '/index.html',
                                               column_family => 'count',
                                               column_qualifier => '2014-06-14 07:31:18'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);

        $key = new Hypertable::ThriftGen::Key({row => '/foo/bar.html',
                                               column_family => 'count',
                                               column_qualifier => '2014-06-14 07:31:18'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);

        $key = new Hypertable::ThriftGen::Key({row => '/index.html',
                                               column_family => 'count',
                                               column_qualifier => '2014-06-14 07:31:19'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);

        $key = new Hypertable::ThriftGen::Key({row => '/foo/bar.html',
                                               column_family => 'count',
                                               column_qualifier => '2014-06-14 07:31:19'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "1"});
        push(@cells, $cell);

        $client->mutator_set_cells($mutator, \@cells);
        $client->mutator_flush($mutator);

        my $ss = new Hypertable::ThriftGen::ScanSpec();
        my $scanner = $client->scanner_open($ns, "Hits", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->mutator_close($mutator);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=/foo/bar.html column_family=count column_qualifier=2014-06-14 07:31:18} value=3
    {Cell key={Key row=/foo/bar.html column_family=count column_qualifier=2014-06-14 07:31:19} value=1
    {Cell key={Key row=/index.html column_family=count column_qualifier=2014-06-14 07:31:18} value=2
    {Cell key={Key row=/index.html column_family=count column_qualifier=2014-06-14 07:31:19} value=4

####  Reset and subtraction

The code snippet below illustrates how to reset and subtract from counters.

    try {
        my $ns = $client->namespace_open("test");
        my $mutator = $client->mutator_open($ns, "Hits", 0, 0);

        my ($key, $cell);
        my @cells;

        $key = new Hypertable::ThriftGen::Key({row => '/index.html',
                                               column_family => 'count',
                                               column_qualifier => '2014-06-14 07:31:18'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "=0"});
        push(@cells, $cell);
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "7"});
        push(@cells, $cell);

        $key = new Hypertable::ThriftGen::Key({row => '/foo/bar.html',
                                               column_family => 'count',
                                               column_qualifier => '2014-06-14 07:31:18'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "-1"});
        push(@cells, $cell);

        $key = new Hypertable::ThriftGen::Key({row => '/index.html',
                                               column_family => 'count',
                                               column_qualifier => '2014-06-14 07:31:19'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "-2"});
        push(@cells, $cell);

        $key = new Hypertable::ThriftGen::Key({row => '/foo/bar.html',
                                               column_family => 'count',
                                               column_qualifier => '2014-06-14 07:31:19'});
        $cell = new Hypertable::ThriftGen::Cell({key => $key, value => "=19"});
        push(@cells, $cell);

        $client->mutator_set_cells($mutator, \@cells);
        $client->mutator_flush($mutator);

        my $ss = new Hypertable::ThriftGen::ScanSpec();
        my $scanner = $client->scanner_open($ns, "Hits", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->mutator_close($mutator);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    {Cell key={Key row=/foo/bar.html column_family=count column_qualifier=2014-06-14 07:31:18} value=2
    {Cell key={Key row=/foo/bar.html column_family=count column_qualifier=2014-06-14 07:31:19} value=19
    {Cell key={Key row=/index.html column_family=count column_qualifier=2014-06-14 07:31:18} value=7
    {Cell key={Key row=/index.html column_family=count column_qualifier=2014-06-14 07:31:19} value=2

### Creating unique keys

This section illustrates how to create unique keys using the [create_cell_unique](../reference_manual/thrift_api.md#createcellunique) API. The example show how you can create unique user IDs for an application. The code makes use of the _print_cell_ function defined in [Appendix - helper functions](perl.md#appendix---helper-functions) and assumes that a _User_ table has been created with the following HQL command.

    CREATE TABLE User (info, id TIME_ORDER desc MAX_VERSIONS 1);

The example code snippet is as follows.

    my ($ns, $ret, $key);

    try {
        $ns = $client->namespace_open("test");
        $key = new Hypertable::ThriftGen::Key({row => 'joe1987',
                                               column_family => 'id'});
        $ret = $client->create_cell_unique($ns, "User", $key, "");
        $key = new Hypertable::ThriftGen::Key({row => 'mary.bellweather',
                                               column_family => 'id'});
        $ret = $client->create_cell_unique($ns, "User", $key, "");
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

    try {
        $ns = $client->namespace_open("test");
        $key = new Hypertable::ThriftGen::Key({row => 'joe1987',
                                               column_family => 'id'});
        $ret = $client->create_cell_unique($ns, "User", $key, "");
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        if ($ex->{code} == 48) {
            print "User name '$key->{row}' is already taken\n";
            $client->namespace_close($ns);
        }
        else {
            print "error: $ex->{message}\n";
            exit 1;
        }
    };

    try {
        $ns = $client->namespace_open("test");
        my $ss = new Hypertable::ThriftGen::ScanSpec();
        my $scanner = $client->scanner_open($ns, "User", $ss);
        while (1) {
            my $cells = $client->scanner_get_cells($scanner);
            if (@{$cells}) {
                for my $cell (@{$cells}) {
                    print_cell($cell);
                }
            }
            else {
                last;
            }
        }
        $client->scanner_close($scanner);
        $client->namespace_close($ns);
    }
    catch Hypertable::ThriftGen::ClientException with {
        my $ex = shift;
        print "error: $ex->{message}\n";
        exit 1;
    };

The following is example output produced by the above code snippet.

    User name 'joe1987' is already taken
    {Cell key={Key row=joe1987 column_family=id column_qualifier=} value=ea21e398-eba7-4a8f-85b4-6a125a7282b5
    {Cell key={Key row=mary.bellweather column_family=id column_qualifier=} value=8da8a4a0-0af2-43a6-af26-b9a25ff52d1f

### Appendix - helper functions

The following helper function is used in the examples in this document.

    sub print_cell {
        my($cell) = @_;
        my $key = $cell->key;
        print "{Cell key={Key row=" . $key->row . " column_family=" .
            $key->column_family . " column_qualifier=" . $key->column_qualifier .
            "} value=";
        if (defined $cell->value) {
            print $cell->value . "\n";
        }
        else {
            print "[NULL]\n";
        }
    }

    sub print_cell_as_array {
        my(@cell_as_array) = @_;
        print "{CellAsArray key={Key row=" . $cell_as_array[0] . " column_family=" .
            $cell_as_array[1] . " column_qualifier=" . $cell_as_array[2] .
            "} value=" . $cell_as_array[3] . "\n";
    }
