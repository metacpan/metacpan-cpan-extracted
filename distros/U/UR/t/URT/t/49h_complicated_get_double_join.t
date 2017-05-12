#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT::DataSource::SomeSQLite;
use Test::More tests => 2;


# Similar to the other double-join test.  The same table gets joined in and needs a different filter
# for each join.
#
# This test is different in that there is an additional join between the two person objects, and
# the property names end up sorting in different orders between test 1 and 2

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
$dbh->do('create table person (person_id integer PRIMARY KEY NOT NULL)');
$dbh->do('create table attribute (attr_id integer PRIMARY KEY NOT NULL, person_id integer NOT NULL REFERENCES person(person_id), name varchar NOT NULL, value varchar)');
$dbh->do('create table relationship (person_id integer REFERENCES person(person_id), related_person_id integer REFERENCES person(person_id), name varchar NOT NULL, PRIMARY KEY (person_id, related_person_id))');

# Make 2 people named Bob and Fred, they are siblings
$dbh->do("insert into person values (1)");
$dbh->do("insert into attribute values (1,1,'name', 'Bob')");

$dbh->do("insert into person values (2)");
$dbh->do("insert into attribute values (3,2,'name', 'Fred')");

$dbh->do("insert into relationship values (1,2,'sibling')");
$dbh->do("insert into relationship values (2,1,'sibling')");

UR::Object::Type->define(
    class_name => 'Person',
    table_name => 'person',
    id_by => [
        person_id    => { is => 'integer' },
    ],
    has_many => [
       attributes => { is => 'Attribute', reverse_as => 'person' },
       relationships => { is => 'Relationship', reverse_as => 'person' },
    ],
    has => [
        name => { via => 'attributes', to => 'value', where => [name => 'name']},
        zname => { via => 'attributes', to => 'value', where => [name => 'name']},
        sibling => { is => 'Person', via => 'relationships', to => 'related_person', where => [name => 'sibling'] },
        sibling_name => { via => 'sibling', to => 'name' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'Attribute',
    table_name => 'attribute',
    data_source => 'URT::DataSource::SomeSQLite',
    id_by => [
        attr_id => { is => 'Integer' },
    ],
    has => [
        person => { is => 'Person', id_by => 'person_id' },
        name => { is => 'String' },
        value => { is => 'String' },
    ],
);

UR::Object::Type->define(
    class_name => 'Relationship',
    table_name => 'relationship',
    data_source => 'URT::DataSource::SomeSQLite',
    id_by => [
        person_id => { is => 'Integer' },
        related_person_id => { is => 'Integer' },
    ],
    has => [
        person => { is => 'Person', id_by => 'person_id'},
        related_person => { is => 'Person', id_by => 'related_person_id' },
        name => { is => 'String' },
    ],
);

my @p = Person->get(name => 'Bob', sibling_name  => 'Fred' );
is(scalar(@p), 1, 'Got one person joining name before sibling');

@p = Person->get(zname => 'Bob', sibling_name  => 'Fred' );
is(scalar(@p), 1, 'Got one person joining name after sibling');
