# Perl

### Prerequisites

  * Install `Bit::Vector` and `Class::Accessor` perl modules:

**Debian**

        $ apt-get install libbit-vector-perl libclass-accessor-class-perl

**Redhat**

        $ yum install perl-Bit-Vector perl-Class-Accessor

**Mac**

        $ port install p5-bit-vector p5-class-accessor

If you need to do it the hard(er) way, try:

        $ perl -MCPAN -e 'install Bit::Vector'
        $ perl -MCPAN -e 'install Class::Accessor'

  * In order for your Perl program to use the Hypertable Thrift Client interface, you need to tell it where to find it. To do that, you need to tell the perl interpreter to include the lib/perl and lib/perl/gen-perl directories in your Hypertable installation. For example:

        perl -I /opt/hypertable/current/lib/perl -I /opt/hypertable/current/lib/perl/gen-perl your_program.pl

Then to include the Hypertable Thrift Client interface, add the following line to the top of your Perl program:

        use Hypertable::ThriftClient;

  * To run the example program below, you first need to create the namespace _test_ and some test tables, which can be accomplished with the following shell command:

        echo "USE '/'; create namespace test; use test; \
            drop table if exists FruitColor; \
            drop table if exists FruitLocation; \
            drop table if exists FruitEnergy; \
            create table FruitColor(data); \
            create table FruitLocation(data); \
            create table FruitEnergy(data); \
            create table thrift_test ( col ); \
            insert into thrift_test values \
            ('2008-11-11 11:11:11', 'k1', 'col', 'v1'), \
            ('2008-11-11 11:11:11', 'k2', 'col', 'v2'), \
            ('2008-11-11 11:11:11', 'k3', 'col', 'v3');" \
            | /opt/hypertable/current/bin/ht shell --batch

### Code Example

    #!/usr/bin/env perl
    use Hypertable::ThriftClient;
    use Data::Dumper;

    my $client = new Hypertable::ThriftClient("localhost", 38080);

    print "HQL examples\n";
    my $namespace = $client->namespace_open("test");
    print Dumper($client->hql_exec($namespace,"show tables"));
    print Dumper($client->hql_exec($namespace,"select * from thrift_test max_versions 1"));

    print "mutator examples\n";
    my $mutator = $client->mutator_open($namespace, "thrift_test");
    my $key = new Hypertable::ThriftGen::Key({row => 'perl-k1',
                                              column_family => 'col'});
    my $cell = new Hypertable::ThriftGen::Cell({key => $key,
                                                value => 'perl-v1'});
    $client->mutator_set_cell($mutator, $cell);
    $client->mutator_flush($mutator);
    $client->mutator_close($mutator);

    print "shared mutator examples\n";
    my $mutate_spec = new Hypertable::ThriftGen::MutateSpec({appname => "test-perl",
                                                             flush_interval => 1000,
                                                             flags => 0});
    $key = new Hypertable::ThriftGen::Key({row => 'perl-put-k1',
                                           column_family => 'col'});
    $cell = new Hypertable::ThriftGen::Cell({key => $key,
                                             value => 'perl-put-v1'});
    $client->shared_mutator_set_cell($namespace, "thrift_test", $mutate_spec, $cell);

    $key = new Hypertable::ThriftGen::Key({row => 'perl-put-k2',
                                           column_family => 'col'});
    $cell = new Hypertable::ThriftGen::Cell({key => $key,
                                             column_family => 'col',
                                             value => 'perl-put-v2'});
    $client->shared_mutator_refresh($namespace, "thrift_test", $mutate_spec);
    $client->shared_mutator_set_cell($namespace, "thrift_test", $mutate_spec, $cell);
    sleep(2);

    print "scanner examples\n";
    my $scanner = $client->scanner_open($namespace, "thrift_test",
        new Hypertable::ThriftGen::ScanSpec({versions => 1}));

    my $cells = $client->scanner_get_cells($scanner);

    while (scalar @$cells) {
      print Dumper($cells);
      $cells = $client->scanner_get_cells($scanner);
    }

    print "asynchronous examples\n";
    my $future = $client->future_open();
    my $color_scanner = $client->async_scanner_open($namespace, "FruitColor", $future,
        new Hypertable::ThriftGen::ScanSpec({versions => 1}));
    my $location_scanner = $client->async_scanner_open($namespace, "FruitLocation", $future,
        new Hypertable::ThriftGen::ScanSpec({versions => 1}));
    my $energy_scanner = $client->async_scanner_open($namespace, "FruitEnergy", $future,
        new Hypertable::ThriftGen::ScanSpec({versions => 1}));

    my $expected_cells = 6;
    my $num_cells=0;

    while (1) {
      my $result = $client->future_get_result($future);
      print Dumper($result);
      last if ($result->{is_empty}==1 || $result->{is_error}==1 || $result->{is_scan}!=1);
      my $cells = $result->{cells};
      foreach my $cell (@$cells){
        print Dumper($cell);
        $num_cells++;
      }
      if ($num_cells >= 6) {
        $client->future_cancel($future);
        last;
      }
    }

    $client->async_scanner_close($color_scanner);
    $client->async_scanner_close($location_scanner);
    $client->async_scanner_close($energy_scanner);;
    $client->future_close($future);

    die "Expected $expected_cells cells got $num_cells." if ($num_cells != $expected_cells);

    print "regexp scanner example\n";
    $scanner = $client->scanner_open($namespace, "thrift_test",
        new Hypertable::ThriftGen::ScanSpec({versions => 1, row_regexp=>"k", value_regexp=>"^v[24]",
        columns=>["col"]}));

    my $cells = $client->scanner_get_cells($scanner);

    while (scalar @$cells) {
      print Dumper($cells);
      $cells = $client->scanner_get_cells($scanner);
    }

    $client->namespace_close($namespace);
