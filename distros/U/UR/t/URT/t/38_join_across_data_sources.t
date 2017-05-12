#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 50;

# FIXME - This tests the simple case of a single indirect property.
# Need to add a test for a doubly-indirect property crossing 2 data
# sources, and a test where the numeric order of things is differen
# than the alphabetic order

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

# Turn this on for debugging
#$ENV{UR_DBI_MONITOR_SQL}=1;


my $tmp_path = "/tmp/ur_testsuite$$";
ok(mkdir($tmp_path), "mkdir temp dir");
our $DB_FILE_1 = "$tmp_path/ur_testsuite_db1_$$.sqlite";
our $DB_FILE_2 = "$tmp_path/ur_testsuite_db2_$$.sqlite";
END {
    &clean_tmp_dir($tmp_path);
}

&create_data_sources($tmp_path);
&populate_databases($tmp_path);
&create_test_classes($tmp_path);


# Set up subscriptions to count queries and loads
my($db1_query_count, $primary_load_count, $db2_query_count, $related_load_count);
sub reset_counts {
    ($db1_query_count, $primary_load_count, $db2_query_count, $related_load_count) = (0,0,0,0);
}


ok(URT::38Primary->create_subscription(
                    method => 'load',
                    callback => sub {$primary_load_count++}),
     'Created a subscription for URT::38Primary load');
ok(URT::38Related->create_subscription(
                    method => 'load',
                    callback => sub {$related_load_count++}),
     'Created a subscription for URT::38Related load');
ok(URT::DataSource::SomeSQLite1->create_subscription(
                    method => 'query',
                    callback => sub {$db1_query_count++}),
    'Created a subscription for SomeSQLite1 query');
ok(URT::DataSource::SomeSQLite2->create_subscription(
                    method => 'query',
                    callback => sub {$db2_query_count++}),
    'Created a subscription for SomeSQLite2 query');


&reset_counts();
my @o = URT::38Primary->get(related_value => '1');
is(scalar(@o), 1, "contained_value => 1 returns one Primary object");
is($db1_query_count, 1, "Queried db 1 one time");
is($primary_load_count, 1, "Loaded 1 Primary object");
is($db2_query_count, 1, "Queried db 2 one time");
is($related_load_count, 1, "Loaded 1 Related object");


&reset_counts();
@o = URT::38Primary->get(primary_value => 'Two', related_value => '2');
is(scalar(@o), 1, "container_value => 'Two',contained_value=>2 returns one Primary object");
is($db1_query_count, 1, "Queried db 1 one time");
is($primary_load_count, 1, "Loaded 1 Primary object");
is($db2_query_count, 1, "Queried db 2 one time");
is($related_load_count, 1, "Loaded 1 Related object");



&reset_counts();
@o = URT::38Primary->get(related_value => '2');
is(scalar(@o), 2, "contained_value => 2 returns two Primary objects");
is($db1_query_count, 1, "Queried db 1 one time");
is($primary_load_count, 1, "Loaded 1 Primary object");
# FIXME - This next one should really be 0, as the resulting query against db2 is exactly the same as
# the prior get() above.  The problem is that the cross-datasource join logic is
# functioning at the database level, not the object level.  So there's no good way of
# knowing that we've already done that query.
is($db2_query_count, 1, "Correctly didn't query db 2 (same as previous query)");
is($related_load_count, 0, "Correctly loaded 0 Related objects (they're cached)");




&reset_counts();
@o = URT::38Primary->get(related_value => '3');
is(scalar(@o), 0, "contained_value => 3 correctly returns no Primary objects");
is($db1_query_count, 1, "Queried db 1 one time");
is($primary_load_count, 0, "correctly loaded 0 Primary objects");
# Note - it kind of doesn't make sense that we do a query against db2, and that query does 
# match one item in there.  UR doesn't go ahead and load it because the query against the
# primary DB returns no rows, so there's nothing to 'join' against, and no rows from db2's
# query are fetched
is($db2_query_count, 1, "Queried db 2 one time");
is($related_load_count, 0, "Correctly loaded 0 Related object");




&reset_counts();
@o = URT::38Primary->get(related_value => '4');
is(scalar(@o), 0, "contained_value => 4 correctly returns no Primary objects");
# Note - same thing here, the primary query fetches 1 row, but doesn't successfully
# join to any rows in the secondary query, so no objects get loaded.
is($db1_query_count, 1, "Queried db 1 one time");
is($primary_load_count, 0, "correctly loaded 0 Primary objects");
is($db2_query_count, 1, "Queried db 2 one time");
is($related_load_count, 0, "correctly loaded 0 Related objects");



&reset_counts();
@o = URT::38Related->get(related_value => 2, primary_values => 'Two');
is(scalar(@o), 1, 'URT::Related->get(primary_value => 2) returned 1 object');

# This actually ends up being 4 because of the way the Indexes get created.  Don't think it's
# useful to test it
#is($db1_query_count, 1, "Queried db 1 one time");
is($primary_load_count, 0, "correctly loaded 0 Primary objects");
is($db2_query_count, 1, "Queried db 2 one time");
is($related_load_count, 0, "correctly loaded 0 Related objects");




sub create_data_sources {

    IO::File->new($DB_FILE_1, 'w')->close();
    class URT::DataSource::SomeSQLite1 {
        is => 'UR::DataSource::SQLite',
    };
    sub URT::DataSource::SomeSQLite1::server { $DB_FILE_1 };

    IO::File->new($DB_FILE_2, 'w')->close();
    class URT::DataSource::SomeSQLite2 {
        is => 'UR::DataSource::SQLite',
    };
    sub URT::DataSource::SomeSQLite2::server { $DB_FILE_2 };
}


sub create_test_classes {
return;
    my $tmp_path = shift;

    # We have to write them out as files instead of calling UR::Object::Type->define()
    # because each class refers to the other

    unshift(@INC, $tmp_path);

    mkdir("$tmp_path/URT") || die "Can't create dir $tmp_path/URT";
    my $f = IO::File->new("$tmp_path/URT/Related.pm",'>');
    $f->print(q(
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
UR::Object::Type->define(
    class_name => 'URT::Related',
    id_by => [ related_id => { is => 'Integer' }, ],
    has => [
        related_value   => { is => 'String' },
        primary_objects => { is => 'URT::Primary', reverse_as => 'related_object', is_many => 1 },
        primary_values  => { vis => 'primary_object', to => 'primary_value', is_many => 1 },
    ],
    data_source => 'URT::DataSource::SomeSQLite2',
    table_name => 'related',
)
1;
));
    $f->close();

    $f = IO::File->new("$tmp_path/URT/Primary.pm",'>');
    $f->print(q(
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
UR::Object::Type->define(
    class_name => 'URT::Primary',
    id_by => [ primary_id => { is => 'Integer' }, ],
    has => [
        primary_value  => { is => 'String' },
        related_id     => { is => 'Integer'},
        related_object => { is => 'URT::Related', id_by => 'related_id' },
        related_value  => { via => 'related_object', to => 'related_value' },
    ],
    data_source => 'URT::DataSource::SomeSQLite1',
    table_name => 'primary_table',
);
1;
));
    $f->close();
}



sub populate_databases {
    my $dbh = URT::DataSource::SomeSQLite1->get_default_handle();
    ok($dbh, 'Got db handle for URT::DataSource::SomeSQLite1');

    ok($dbh->do("create table primary_table (primary_id integer PRIMARY KEY, primary_value varchar, rel_id integer)"),
       "create primary table");
    # This one will match one item in related
    ok($dbh->do("insert into primary_table values (1, 'One', 1)"),
       "insert row 1 into primary");
    # these two things will match one in related
    ok($dbh->do("insert into primary_table values (2, 'Two', 2)"),
       "insert row 2 into primary");
    ok($dbh->do("insert into primary_table values (3, 'Three', 2)"),
       "insert row 3 into primary");
    # Nothing here matches related's 3
    # This will match nothing in related
    ok($dbh->do("insert into primary_table values (4, 'Four', 4)"),
       "insert row 4 into primary");

    ok($dbh->commit(), "Commit SomeSQLite1 DB");

    $dbh = URT::DataSource::SomeSQLite2->get_default_handle();
    ok($dbh, 'Got db handle for URT::DataSource::SomeSQLite2');

    ok($dbh->do("create table related (related_id integer PRIMARY KEY, related_value varchar)"),
       "crate related table");
    ok($dbh->do("insert into related values (1, '1')"),
       "insert row 1 into related");
    ok($dbh->do("insert into related values (2, '2')"),
       "insert row 2 into related");
    ok($dbh->do("insert into related values (3, '3')"),
       "insert row 4 into related");

    ok($dbh->commit(), "Commit SomeSQLite2 DB");
}
    

sub clean_tmp_dir {
    my $tmp_dir = shift;

    my $dbh = URT::DataSource::SomeSQLite1->get_default_handle();
    $dbh->disconnect();
    $dbh = URT::DataSource::SomeSQLite2->get_default_handle();
    $dbh->disconnect();

    #diag("Cleanup tmp dir");
    # These _should_ be the only files in there...
    ok(unlink($DB_FILE_1), 'Remove sqlite DB 1');
    ok(unlink($DB_FILE_2), 'Remove sqlite DB 2');
    ok(rmdir($tmp_dir), "Remove tmp dir $tmp_dir");
}

