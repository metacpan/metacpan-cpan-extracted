#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use URT;

use Test::More tests => 10;

# This tests a get() by subclass specific parameters on a subclass with no table of its own.
# The property is only defined on the subclass, but the data lives in the table referred to
# in the parent class

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, 'Got DB handle');

ok($dbh->do(q{
            create table animal (
                animal_id   integer NOT NULL,
                name        varchar NOT NULL,
                num_legs    integer,
                subclass    varchar NOT NULL)}),
        'Created animal table');

ok($dbh->do("insert into animal (animal_id, name, subclass, num_legs) values (1,'fido','URT::Dog', 4)"),
    'Inserted fido');
ok($dbh->do("insert into animal (animal_id, name, subclass, num_legs) values (2,'woody','URT::Bird', 2)"),
    'Inserted woody');
ok($dbh->do("insert into animal (animal_id, name, subclass) values (3,'jaws','URT::Shark')"),
    'Inserted jaws');

ok($dbh->commit(), 'DB commit');
       
# Dogs and birds have legs, sharks don't
UR::Object::Type->define(
    class_name => 'URT::Animal',
    id_by => [
        animal_id => { is => 'NUMBER', len => 10 },
    ],
    has => [
        name => { is => 'Text' },
        subclass => { is => 'Text' },
    ],
    subclassify_by => 'subclass',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'animal',
); 

UR::Object::Type->define(
    class_name => 'URT::Dog',
    is => 'URT::Animal',
    has_optional => [
        num_legs => { is => 'Integer' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::Bird',
    is => 'URT::Animal',
    has_optional => [
        num_legs => { is => 'Integer', column_name => 'num_legs' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::Shark',
    is => 'URT::Animal',
);


my @animals = URT::Dog->get(num_legs => 3);
is(scalar(@animals), 0, 'No dogs with 3 legs');

@animals = URT::Bird->get(num_legs => 2);
is(scalar(@animals), 1, 'Got 1 bird with 2 legs');
is($animals[0]->name, 'woody', ' It was the right animal');

@animals = eval { URT::Animal->get(num_legs => 0) };
like($@, 
     qr/Unknown parameters to URT::Animal get()/,
     'Correctly got an exception trying to query URT::Animal by num_legs');
