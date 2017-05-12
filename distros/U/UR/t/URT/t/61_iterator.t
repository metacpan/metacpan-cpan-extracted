#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 12;

my $dbh = &setup_classes_and_db();

# This tests creating an iterator and doing a regular get() 
# for the same stuff, and make sure they return the same things

subtest 'Basic' => sub {
    plan tests => 5;

    # create the iterator but don't read anything from it yet
    my $iter = URT::Thing->create_iterator(name => 'Bob');
    ok($iter, 'Created iterator for Things named Bob');

    my @objs;
    while (my $o = $iter->next()) {
        is($o->name, 'Bob', 'Got an object with name Bob');
        push @objs, $o;
    }
    is(scalar(@objs), 2, '2 Things returned by the iterator');
    is_deeply( [ map { $_->id } @objs], [2,4], 'Got the right object IDs from the iterator');
};

subtest 'or-rule' => sub {
    plan tests => 3;

    my $iter = URT::Thing->create_iterator(-or => [[name => 'Bob'], [name => 'Joe']]);
    ok($iter, 'Created an iterator for things named Bob or Joe');

    my @objs;
    while(my $o = $iter->next()) {
        push @objs, $o;
    }
    is(scalar(@objs), 5, '5 things returned by the iterator');
    is_deeply( [ map { $_->id } @objs], [2,4,6,8,10], 'Got the right object IDs from the iterator');
};

subtest 'complicated or rule' => sub {
    plan tests => 3;

    my $iter = URT::Thing->create_iterator(-or => [[name => 'Joe', 'id <' => 8], [name => 'Bob', 'id >' => 3]]);
    ok($iter, 'create iterator');
    my @objs;
    while(my $o = $iter->next()) {
        push @objs, $o;
    }
    is(scalar(@objs), 2, '2 things returned by the iterator');
    is_deeply( [ map { $_->id } @objs], [4,6], 'Got the right object IDs from the iterator');
};


subtest 'with order-by' => sub {
    plan tests => 3;

    my $iter = URT::Thing->create_iterator(-or => [[name => 'Joe', data => 'foo'],[name => 'Bob']], -order => ['-data']);
    ok($iter, 'Created an iterator for an OR rule with with descending order by');
    my @objs;
    while(my $o = $iter->next()) {
        push @objs, $o;
    }
    is(scalar(@objs), 3, '3 things returned by the iterator');
    is_deeply( [ map { $_->id } @objs], [2,6,4], 'Got the right object IDs from the iterator');
};

subtest 'or-rule, 2 ways to match the same object' => sub {
    plan tests => 3;

    my $iter = URT::Thing->create_iterator(-or => [[ id => 2 ], [name => 'Bob', data => 'foo']]);
    ok($iter, 'Created an iterator for an OR rule with two ways to match the same single object');
    my @objs;
    while(my $o = $iter->next()) {
        push @objs, $o;
    }
    is(scalar(@objs), 1, 'Got one object back from the iterstor');
    is_deeply( [ map { $_->id } @objs], [2], 'Gor the right object ID from the iterator');
};

subtest peek => sub {
    plan tests => 8;

    # there are 3 Joes
    my $iter = URT::Thing->create_iterator(name => 'Joe');
    my $o1 = $iter->peek;
    ok($o1, 'peek');

    my $o2 = $iter->peek;
    is($o1, $o2, 'peek again returns the same obj');

    $o2 = $iter->next();
    is($o1, $o2, 'next() returns the same obj, again');

    $o2 = $iter->peek();
    isnt($o1, $o2, 'peek after next() returns a different object');

    my $o3 = $iter->next();
    is($o2, $o3, 'next() after peek returns the same object');

    $o3 = $iter->next();
    ok($o3, 'next() returns 3rd object');

    ok(! $iter->peek(), 'peek returns nothing after iter is exhausted');
    ok(! $iter->next(), 'next returns nothing after iter is exhausted');
};

subtest remaining => sub {
    plan tests => 5;

    my $iter = URT::Thing->create_iterator();
    ok($iter, 'create iterator matching all objects');

    ok($iter->next, 'Get first object');
    my @remaining = $iter->remaining;
    is(scalar(@remaining), 4, 'got all 4 remaining objects');

    is($iter->next, undef, 'calling next() now returns undef');
    @remaining = $iter->remaining;
    is(scalar(@remaining), 0, 'remaining() returns 0 objects');
};

subtest create_for_list => sub {
    plan tests => 2;

    my @expected = (
            URT::Thing->get(2),
            0,
            1,
            URT::Thing->get(6),
        );
    my $iter = UR::Object::Iterator->create_for_list(@expected);
    ok($iter, 'created iterator');

    my @objs = $iter->remaining;
    is_deeply(\@objs, \@expected, 'got back all the objects');
};

subtest map => sub {
    plan tests => 3;

    my $original_iter = URT::Thing->create_iterator(name => 'Bob');
    ok($original_iter, 'Create iterator for all Bob');

    my $names_iter = $original_iter->map(sub { $_->name });
    ok($names_iter, 'Create mapping iterator returning names');

    is_deeply([qw( Bob Bob )],
              [ $names_iter->remaining ],
              'all values from mapping iterator');
};

sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle();

    ok($dbh, 'got DB handle');

    ok($dbh->do('create table things (thing_id integer, name varchar, data varchar)'),
       'Created things table');

    my $insert = $dbh->prepare('insert into things (thing_id, name, data) values (?,?,?)');
    foreach my $row ( ( [2, 'Bob', 'foo'],
                        [4, 'Bob', 'baz'],
                        [6, 'Joe', 'foo'], 
                        [8, 'Joe', 'bar'],
                        [10, 'Joe','baz'],
                      )) {
        unless ($insert->execute(@$row)) {
            die "Couldn't insert a row into 'things': $DBI::errstr";
        }
    }

    $dbh->commit();

    # Now we need to fast-forward the sequence past 4, since that's the highest ID we inserted manually
    my $sequence = URT::DataSource::SomeSQLite->_get_sequence_name_for_table_and_column('things', 'thing_id');
    die "Couldn't determine sequence for table 'things' column 'thing_id'" unless ($sequence);

    my $id = -1;
    while($id <= 4) {
        $id = URT::DataSource::SomeSQLite->_get_next_value_from_sequence($sequence);
    }

    ok(UR::Object::Type->define(
           class_name => 'URT::Thing',
           id_by => [
                'thing_id' => { is => 'Integer' },
           ],
           has => ['name', 'data'],
           data_source => 'URT::DataSource::SomeSQLite',
           table_name => 'things'),
       'Created class URT::Thing');

    return $dbh;
}
               

