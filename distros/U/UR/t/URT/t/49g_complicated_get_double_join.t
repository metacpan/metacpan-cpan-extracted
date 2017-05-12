#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT::DataSource::SomeSQLite;
use Test::More tests => 1;

# This tests a get() where the same tabe/column (attribute.value) is getting filtered with
# diggerent values as a result of two different properties (name and sibling_name)
#
# The SQL writer was getting confused by the time it got to the WHERE clause, and 
# applied them both the whatever alias was used for the final join to that table

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
$dbh->do('create table person (person_id integer PRIMARY KEY NOT NULL, sibling_id integer)');
$dbh->do('create table attribute (person_id integer REFERENCES person(person_id), key varchar NOT NULL, value varchar, PRIMARY KEY (person_id, key))');

# Make 2 people named Bob and Fred, they are siblings
$dbh->do("insert into person values (1, 2)");
$dbh->do("insert into attribute values (1,'name','Bob')");

$dbh->do("insert into person values (2, 1)");
$dbh->do("insert into attribute values (2,'name','Fred')");


UR::Object::Type->define(
    class_name => 'Person',
    table_name => 'person',
    id_by => [
        person_id    => { is => 'integer' },
    ],
    has => [
        attributes => { is => 'Attribute', reverse_as => 'person', is_many => 1 },
        name => { is => 'String', via => 'attributes', where => [key => 'name'], to => 'value' },
        sibling => { is => 'Person', id_by => 'sibling_id' },
        sibling_name => { via => 'sibling', to => 'name' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'Attribute',
    table_name => 'attribute',
    data_source => 'URT::DataSource::SomeSQLite',
    id_by => [
        person_id => { is => 'Integer' },
        key => { is => 'String' },
    ],
    has => [
        person => { is => 'Person', id_by => 'person_id'},
        value  => { is => 'String' },
    ],
);

my @p = Person->get(name => 'Bob', sibling_name  => 'Fred' );
is(scalar(@p), 1, 'Got one person');



