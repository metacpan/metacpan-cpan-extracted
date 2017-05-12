#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 22;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

# Turn this on for debugging
#$ENV{UR_DBI_MONITOR_SQL}=1;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, "got a db handle");
ok($dbh->do('create table thing
            ( thing_id int NOT NULL PRIMARY KEY, name varchar, is_cool integer, color varchar)'),
   'created parent table');

ok(UR::Object::Type->define( 
        class_name => 'URT::Thing',
        table_name => 'thing',
        id_by => [
            'thing_id' =>     { is => 'NUMBER' },
        ],
        has => [
            'name' =>          { is => 'STRING' },
            is_cool =>         { is => 'NUMBER' },
            color =>           { is => 'STRING' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for Thing");

my $sth = $dbh->prepare('insert into thing (thing_id, name, is_cool, color) values (?,?,?,?)');
ok($sth,'insert statement prepared');
foreach my $n ( 1 .. 10 ) {
    ok($sth->execute($n,$n,1,'green'), "inserted thing ID $n");
}

$sth->execute(99,99,0,'white');   # item 99 is not cool

my $load_count = 0;
ok(URT::Thing->create_subscription(
                    method => 'load',
                    callback => sub {$load_count++}),
     'Created a subscription for load');

my $query_count = 0;
my $query_text = '';
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_text = $_[0]; $query_count++}),
    'Created a subscription for query');

$load_count = 0;
$query_count = 0;
my @o = URT::Thing->get(name => [5,7,2,99,102], is_cool => 1);
is(scalar(@o), 3, 'get() returned the correct number of items with in clause containing some non-matching values');
is($load_count, 3, 'loaded 0 new objects');
is($query_count, 1, 'made 1 query');


$load_count = 0;
$query_count = 0;
@o = URT::Thing->get(name => 5, is_cool => 1, color => 'green');
is(scalar(@o), 1, 'get() correctly returns object matching name that was in the previous in-clause');
is($load_count, 0, 'loaded 0 new objects');
is($query_count, 0, 'no query was generated');

