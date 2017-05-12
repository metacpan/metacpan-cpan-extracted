#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT::DataSource::SomeSQLite;
use Test::More tests => 6;

# This test does a query that joins two different tables twice each into a single query
# (for a total of 4 tables joined) for a different "reason" each time.
#
# Loading a row shouldn't cause any additional queries

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

$dbh->do('create table person (person_id integer not null primary key, name varchar not null)');
$dbh->do('create table attribute (attr_id integer not null primary key, person_id integer not null, key varchar, value varchar)');

# Bob and Fred are people
$dbh->do("insert into person values (1,'Bob')");
$dbh->do("insert into person values (2,'Fred')");

# Bob lives at 123 main st and has a green car
$dbh->do("insert into attribute values (11,1,'address','123 main st')");
$dbh->do("insert into attribute values (12,1,'car_color','green')");

# Fred lives at 456 elm st and has a red car
$dbh->do("insert into attribute values (21,2,'address','456 elm st')");
$dbh->do("insert into attribute values (22,2,'car_color','red')");

# Bob's father is Fred
$dbh->do("insert into attribute values (13,1,'father_id', 2)");

UR::Object::Type->define(
    class_name => 'Person',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'person',
    id_by => [
        person_id => { is => 'Integer' },
    ],
    has => [
       name => { is => 'String', },
       attributes => { is => 'Attribute', reverse_as => 'person', is_many => 1 },
       address => { is => 'String', via => 'attributes', to => 'value', where => [key => 'address'] },

       father_id => { is => 'Integer', via => 'attributes', to => 'value', where => [key => 'father_id'], is_optional => 1 },
       father => { is => 'Person', id_by => 'father_id', is_optional => 1 },
       father_address => { via => 'father', to => 'address', is_optional => 1 },

       car_color => { is => 'String', via => 'attributes', to => 'value', where => [ key => 'car_color' ] },
    ],
);

UR::Object::Type->define(
    class_name => 'Attribute',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'attribute',
    id_by => [
        attr_id => { is => 'Integer' },
    ],
    has => [
        person => { is => 'Person', id_by => 'person_id' },
        key => { is => 'String', },
        value => { is => 'String', },
    ],
);


my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub { $query_count++ }),
   'Created a subscription for query');
my $iter = Person->create_iterator(father_address => '456 elm st');
ok($iter, 'Created iterator for people filter by father_address');
is($query_count, 1, 'Made one query');

$query_count = 0;
my $p = $iter->next();
ok($p, 'Got a person');
is($p->name, 'Bob', 'It was the right person');
is($query_count, 0, 'Made no queries');


