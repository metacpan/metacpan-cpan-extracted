use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 44;
use URT::DataSource::SomeSQLite;

&setup_classes_and_db();

my(@things,%things_by_id);

@things = URT::Thing->get(value => [1,2,3]);
is(scalar(@things), 3, 'Got 3 things from the DB with IN');
%things_by_id = map { $_->value => $_ } @things;

is($things_by_id{'1'}->id, 1, 'Got value 1');
is($things_by_id{'2'}->id, 2, 'Got value 2');
is($things_by_id{'3'}->id, 3, 'Got value 3');

@things = URT::Thing->get('value not in' => [1,2,3,4,5]);
is(scalar(@things), 3, 'Got 3 things from the DB with NOT IN');
%things_by_id = map { $_->value => $_ } @things;

is($things_by_id{'6'}->id, 6, 'Got value 6');
is($things_by_id{'7'}->id, 7, 'Got value 7');
is($things_by_id{'8'}->id, 8, 'Got value 8');

@things = URT::Thing->get(value => [1,2,3]);
is(scalar(@things), 3, 'Got 3 things from the cache with IN');
%things_by_id = map { $_->value => $_ } @things;

is($things_by_id{'1'}->id, 1, 'Got value 1');
is($things_by_id{'2'}->id, 2, 'Got value 2');
is($things_by_id{'3'}->id, 3, 'Got value 3');

@things = URT::Thing->get('value not in' => [1,2,3,4,5]);
is(scalar(@things), 3, 'Got 3 things from the cache with NOT IN');
%things_by_id = map { $_->value => $_ } @things;

is($things_by_id{'6'}->id, 6, 'Got value 6');
is($things_by_id{'7'}->id, 7, 'Got value 7');
is($things_by_id{'8'}->id, 8, 'Got value 8');


@things = URT::Thing->get(value => [ 2,3,4 ]);
is(scalar(@things), 3, 'Got 3 things from the DB and cache with IN');
%things_by_id = map { $_->value => $_ } @things;

is($things_by_id{'4'}->id, 4, 'Got value 4');
is($things_by_id{'2'}->id, 2, 'Got value 2');
is($things_by_id{'3'}->id, 3, 'Got value 3');


@things = URT::Thing->get('value not in' => [1,2,3,7,8]);
is(scalar(@things), 3, 'Got 3 things from the DB and cache with NOT IN');
%things_by_id = map { $_->value => $_ } @things;

is($things_by_id{'4'}->id, 4, 'Got value 4');
is($things_by_id{'5'}->id, 5, 'Got value 5');
is($things_by_id{'6'}->id, 6, 'Got value 6');



@things = URT::Thing->get('related_values in' => [1,2,3]);
is(scalar(@things), 8, 'Got 8 things from the DB with related_values IN 1-3');

@things = URT::Thing->get('related_values in' => [-1,-2,9,10]);
is(scalar(@things), 0, 'Got 0 things with related_values in [-1,-2,9,10]');

# All of them will match value 6
@things = URT::Thing->get('related_values in' => [-1, -2, 6]);
is(scalar(@things), 8, 'Got 8 things from the DB with related_values IN [-1, -2, 6]');

@things = URT::Thing->get('related_values not in' => [-10,-9,9,99]);
is(scalar(@things), 8, 'Got 8 things from the DB with related_values not in [-10,-9,9,99]');

@things = URT::Thing->get('related_values not in' => [4,5]);
is(scalar(@things), 8, 'Got 0 things with related_values not in [4,5]');

# all of them have value 7
@things = URT::Thing->get('related_values not in' => [7,100,101]);
is(scalar(@things), 8, 'Got 0 things with related_values not in [7,100,101]');

@things = URT::Thing->get('related_values not in' => [1,2,3,4,5,6,7,8]);
is(scalar(@things), 0, 'Got 0 things with related_values not in [1,2,3,4,5,6,7,8]');


# Only things 1 and 2 have optional values set

@things = URT::Thing->get('related_optional_values in' => [1,2,3]);
is(scalar(@things), 2, 'Got 2 things from DB with related_optional_values in 1-3');

@things = URT::Thing->get('related_optional_values in' => [20,4,16]);
is(scalar(@things), 2, 'Got 2 things with related_optional_values in [4,16,20]');

@things = URT::Thing->get('related_optional_values in' => [25,26,-2]);
is(scalar(@things), 0, 'Got 0 things with related_optional_values in [-2,25,26]');

@things = URT::Thing->get('related_optional_values in' => [19, undef, 5]);
is(scalar(@things), 8, 'All 8 things with related_optional_values in [undef, 5,19]');

# objs 1 and 2 will match the "related values is not null" part
@things = URT::Thing->get('related_optional_values not in' => [undef, 6, 22]);
is(scalar(@things), 2, 'Got 2 things with related_optional_values not in [undef, 6, 22]');

# 1 and 2 have related values not in 7,8 (1-6, for example).  The others (objs 3-8) are NULL and don't match
@things = URT::Thing->get('related_optional_values not in' => [7,8]);
is(scalar(@things), 2, 'Got 2 things with related_optional_values not in [7,8]');

# Same here, 1 and 2 have related values not in the list.  Others are NULL
@things = URT::Thing->get('related_optional_values not in' => [500,501, -22]);
is(scalar(@things), 2, 'Got 2 things with related_optional_values not in [500,501, -22]');


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing (thing_id integer NOT NULL PRIMARY KEY, value integer)"),
        'created thing table');

    my $sth = $dbh->prepare('insert into thing values (?,?)');
    ok($sth, 'Prepared insert statement');
    foreach my $val ( 1,2,3,4,5,6,7,8 ) {
        $sth->execute($val,$val);
    }
    $sth->finish;

    ok( $dbh->do("create table related (related_id integer NOT NULL PRIMARY KEY, thing_id integer references thing(thing_id), value integer)"),
        'created related table');
    $sth = $dbh->prepare('insert into related values (?,?,?)');
    my $id = 1;
    foreach my $val ( 1,2,3,4,5,6,7,8 ) {
        foreach my $thing_id ( 1..8 ) {
            $sth->execute($id++,$thing_id,$val);
        }
    }
    $sth->finish;

    ok( $dbh->do("create table related_optional (related_id integer NOT NULL PRIMARY KEY, thing_id integer references thing(thing_id), value integer)"),
        'created related_optional table');
    $sth = $dbh->prepare('insert into related_optional values (?,?,?)');
    $id = 1;
    foreach my $val ( 1,2,3,4,5,6,7,8 ) {
        $sth->execute($id++,1,$val);
        $sth->execute($id++,2,$val);
    }
    $sth->finish;

    ok($dbh->commit(), 'DB commit');

    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => [
            value => { is => 'Integer' },
        ],
        has_many => [
            relateds => { is => 'URT::Related', reverse_as => 'thing' },
            related_values => { via => 'relateds', to => 'value' },
        ],
        has_many_optional => [
            related_optionals => { is => 'URT::RelatedOptional', reverse_as => 'thing' },
            related_optional_values => { via => 'related_optionals', to => 'value' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );

    UR::Object::Type->define(
        class_name => 'URT::Related',
        id_by => 'related_id',
        has => [
            thing => { is => 'URT::Thing', id_by => 'thing_id' },
            value => { is => 'Integer' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'related',
    );
    UR::Object::Type->define(
        class_name => 'URT::RelatedOptional',
        id_by => 'related_id',
        has => [
            thing => { is => 'URT::Thing', id_by => 'thing_id' },
            value => { is => 'Integer' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'related_optional',
    );

}
