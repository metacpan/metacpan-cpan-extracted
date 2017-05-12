#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 18;

my $dbh = &setup_classes_and_db();

# This tests creating an iterator and doing a regular get() 
# for the same stuff, and make sure they return the same things

# create the iterator but don't read anything from it yet
my $iter = URT::Thing->create_iterator(name => 'Bob');
ok($iter, 'Created iterator for Things named Bob');

my $o = URT::Thing->get(thing_id => 2);

my @objs = URT::Thing->get(name => 'Bob');

is(scalar(@objs), 2, 'Get returned 2 objects');

my @objs_iter;
while (my $obj = $iter->next()) {
    push @objs_iter, $obj;
}

is(scalar(@objs_iter), 2, 'The iterator returned 2 objects');

is_deeply(\@objs_iter, \@objs, 'Iterator and get() returned the same things');


# Iterator behavior is undefined when the caller manipulates the objects
# matching the iterator's BoolExpr after the iterator's creation, but before
# they come off of the iterator.
#
# In this case, the iterator will only return the one object still matching
# the bx when it's next() method is called, but not the thing that didn't
# exist when the iterator was created.

# Right now objects 6,8 and 10 are named Joe
$iter = URT::Thing->create_iterator(name => 'Joe');
ok($iter, 'Created iterator for Things named Joe');

$o = URT::Thing->get(thing_id => 6);
$o->name('Fred');  # Change the name so it no longer matches the request

$o = URT::Thing->get(thing_id => 10);
$o->delete();      # Delete this one

@objs = URT::Thing->get(name => 'Joe');
is(scalar(@objs), 1, 'get() returned 1 thing named Joe after changing the other');

ok(URT::Thing->create(thing_id => 99, name => 'JoeJoe', data => 'abc'),
   'Make a new thing that matches the iterator BoolExpr');

$o = $iter->next();
is($o->id, 8, 'Second object from iterator is id 8');
is($o->name, 'Joe', 'Second object name is Joe');

$o = $iter->next();
ok(!$o, 'The iterator is done');  # doesn't return the newly created thing



# Make an iterator ordered by 'data', and change 'data' for some of the objects
# while it's running.
#
# Note for future developers: The behavior here is a policy decision, not really
# a logical or technological one.  If the behavior changes in the future, that
# might be ok, but it would need to be documented

# initially, the order is 99 (abc), 8 (bar), 4 (baz), 2 (foo), 6 (foo)
$iter = URT::Thing->create_iterator('id <' => 100, -order => 'data');
ok($iter, 'Create iterator for all things ordered by data');

# The DB query won't see this because the cursor was opened before the update
ok($dbh->do("update things set data = 'aaa' where thing_id = 2"),
   'Change data to "aaa" for thing 2 in the DB, it now sorts first');

my @objects;
# This should fill in 99 and 8
@objects = ($iter->next(), $iter->next());

ok(URT::Thing->get(4)->delete, 'Delete thing id 4 before the iterator returns it');

$o = eval { $iter->next() };
like($@,
     qr/Attempt to fetch an object which matched.*'thing_id' => ('|)4('|)/s,
     'caught exception about deleted thing id 4');

# completely-consistent iterator behaviour would make this one come next
URT::Thing->get(6)->data('bas');
# And might make this one come again at the end of the list
URT::Thing->get(99)->data('zzz');

push @objects, $o while ($o = $iter->next());

my @expected_ids = (99,8,2,6);
my @got_ids = map { $_->id } @objects;
is_deeply(\@got_ids, \@expected_ids, 'Objects are in the expected order');





# Remove the test DB
unlink(URT::DataSource::SomeSQLite->server);


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
               

