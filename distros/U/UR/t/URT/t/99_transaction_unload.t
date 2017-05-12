#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

use Test::More tests => 3;

subtest 'setup' => sub {
    plan tests => 3;

    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
    ok($dbh->do('CREATE TABLE person (id integer PRIMARY KEY, name text)'),
        'created table (person)');
    ok($dbh->do('INSERT INTO person (id, name) VALUES (1, NULL)'),
        'inserted person 1');

    my $meta = UR::Object::Type->__define__(
        class_name => 'URT::Person',
        id_by => [
            id => { is => 'Integer' },
        ],
        has => {
            name => { is => 'Text' },
        },
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'person',
    );
    ok($meta, 'defined a class');
};


my $person = URT::Person->get(1);
ok(scalar($person->__errors__), 'created a person with errors');
my $tx = UR::Context::Transaction->begin();
URT::Person->unload();
ok($tx->commit, 'committed after unloading erroneous Person');

