use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";

use URT;
use Test::More tests => 49;

use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle();
$dbh->do('create table thing (thing_id integer PRIMARY KEY, value varchar, other varchar)');
my $sth = $dbh->prepare('insert into thing values (?,?,?)');
foreach my $id ( 2..10 ) {
    $sth->execute($id,chr($id+64), chr($id+64));  # id 2 has balue B, id 3 has value C, etc
}
$sth->finish;

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => 'thing_id',
    has => ['value','other'],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'thing',
);


# A thing we've defined but does not exist in the DB
my $defined_thing = URT::Thing->__define__(thing_id => '12345', value => 'CC', other => 'CC');
ok($defined_thing, 'Instantiate a URT::Thing with __define__');

# At the start, there are 9 items in the DB, plus the __define__d one

my @things = URT::Thing->get();
is(scalar(@things), 10, 'Got all 10 things');

ok($dbh->do('delete from thing where thing_id = 4'),
   'Delete thing_id 4 from the database');

# Deleted one, now there are 9
@things = UR::Context->reload('URT::Thing');
is(scalar(@things), 9, 'reload() returned 9 things');



ok($dbh->do('delete from thing where thing_id = 6'),
   'Delete thing_id 6 from the database');
@things = UR::Context->reload('URT::Thing');
is(scalar(@things), 8, 'get() returned 8 things');


# Change object 2's value from 'B' to ZZZ.  Now there are 8 things in memory and the DB.
# In the DB, object 2's value sorts first, but in memory it sorts last
# Remaing object IDs should be 2,3,5,7,8,9,10,12345
my $trans = UR::Context::Transaction->begin;
    ok(URT::Thing->get(2)->value('ZZZ'), "Change thing 2's value to ZZZ");
    my @expected_ids = (3,12345,5,7,8,9,10,2);
    @things = UR::Context->reload('URT::Thing', -order => ['value']);
    is(scalar(@things), 8, 'Got 8 things ordered by value');

    is_deeply([ map { $_->id } @things],
              \@expected_ids,
              'Objects came back in the expected order');

    # Now delete object 2 from the DB.  Reloading will throw an exception
    # because it's modified in memory, and modified in a conflicting manner in the
    # database (it's deleted)
    ok($dbh->do('delete from thing where thing_id = 2'),
       'Delete thing_id 2 from database');
    @things = eval { UR::Context->reload('URT::Thing', -order => ['value']) };
    is(scalar(@things),0, 'Got no things back from reload()');
    like($@,
         qr(URT::Thing ID '2' previously existed in an underlying),
         'reload thew an exception about the deleted object');

    # Undo the previous change so we won't get an exception again
$trans->rollback;

# After rolling back the transaction, Object ID 2 is still deleted from the database,
# but exists in memory as an unchanged object.  There are now 6 objects in the DB
# and 8 in memory (don't forget the 1 that was __define_d
#
# Now, change object 10's value from J to A in memory.  In the DB, object 10 sorts last,
# but in memory it sorts first.

$trans = UR::Context::Transaction->begin;
    ok(URT::Thing->get(10)->value('A'), 'Change thing id 10 value to A');
    @expected_ids = (10,3,12345,5,7,8,9);
    @things = UR::Context->reload('URT::Thing', -order => ['value']);
    is(scalar(@things), 7, 'Got 7 things ordered by value');
    is_deeply([ map { $_->id } @things],
              \@expected_ids,
              'Objects came back in the expected order');

    # Now delete it from the DB and make sure it throws an exception
    ok($dbh->do('delete from thing where thing_id = 10'),
       'Delete thing_id 10 from database');
    @things = eval { UR::Context->reload('URT::Thing', -order => ['value']) };
    is(scalar(@things),0, 'Got no things back from reload()');
    like($@,
         qr(URT::Thing ID '10' previously existed in an underlying),
         'reload thew an exception about the deleted object');
$trans->rollback;


# After the transaction, object ID 10 is still deleted from the database
# but exists in memory as an unchanged object.  There are now 5 objects in
# the DB and 7 in memory (6 that came from the DB, plus the __define__d one)

# Change object 3's value from C to ZZZ in the DB.  In memory it will sort first,
# but in the database it will sort last.

$trans = UR::Context::Transaction->begin;
    ok($dbh->do("update thing set value = 'ZZZ' where thing_id = 3"),
       'Change thing id 3 value to ZZZ in the database');
    @expected_ids = (12345,5,7,8,9,3);
    @things = UR::Context->reload('URT::Thing', -order => ['value']);
    is(scalar(@things), 6, 'Got 6 things ordered by value');
    is_deeply([ map { $_->id } @things],
                  \@expected_ids,
                  'Objects came back in the expected order');

    # Now delete the object
    ok(URT::Thing->get(3)->delete, 'Delete thing id 3 from memory');
    @things = UR::Context->reload('URT::Thing', -order => ['value']);
    is(scalar(@things), 5, 'Got 4 object back from reload');
    @expected_ids = (12345,5,7,8,9);
    is_deeply([ map { $_->id } @things],
                  \@expected_ids,
                  'Objects came back in the expected order');
$trans->rollback;


# Change object 9's value from I to A in the DB.  In memory it will sort
# last, but in the DB it will sort first.  Object 3 still has value 'ZZZ'
$trans = UR::Context::Transaction->begin;
    ok($dbh->do("update thing set value = 'A' where thing_id = 9"),
       'Change thing id 9 value to A in the database');
    @expected_ids = (9,12345,5,7,8,3);
    @things = UR::Context->reload('URT::Thing', -order => ['value']);
    is(scalar(@things), 6, 'Got 6 things ordered by value');
    is_deeply([ map { $_->id } @things],
                  \@expected_ids,
                  'Objects came back in the expected order');

    # now delete object ID 9
    ok(URT::Thing->get(9)->delete, 'Delete thing id 9 from memory');
    @things = UR::Context->reload('URT::Thing', -order => ['value']);
    is(scalar(@things), 5, 'Got 4 object back from reload');
    @expected_ids = (12345,5,7,8,3);
    is_deeply([ map { $_->id } @things],
                  \@expected_ids,
                  'Objects came back in the expected order');
# Hack required in UR::Context::__merge... to get object 9 to correctly have
# value => 'A' instead of 'I'
$trans->rollback;


# Try changing an unrelated property and do a query
#
# Object 9 is back again with value 'A' because of the rollback.
$trans = UR::Context::Transaction->begin;
    ok(URT::Thing->get(7)->other('blahblah'), 'Change thing id 7 "other" property');
    ok($dbh->do("update thing set other = 'foofoo' where thing_id = 8"),
       'Change thing id 8 "other" property in the database');

    @things = UR::Context->reload('URT::Thing', -order => ['value']);
    is(scalar(@things), 6, 'Got 4 objects back from reload');
    @expected_ids = (9,12345,5,7,8,3);
    is_deeply([ map { $_->id } @things],
                  \@expected_ids,
                  'Objects came back in the expected order');
$trans->rollback;


# Make a change to both an order-by and a filtered property in memory
$trans = UR::Context::Transaction->begin;
    my $obj = URT::Thing->get(7);
    ok($obj->other('blahblah'), 'Change object 7s other property to blahblah');
    ok($obj->value('A'), 'Change object 7s value to A');

    @things = UR::Context->reload('URT::Thing', 'other ne' => 'blahblah', -order => ['value']);
    is(scalar(@things), 5, 'Got back 5 things from reload() where other is not blahblah');
    @expected_ids = (9,12345,5,8,3);
    is_deeply([ map { $_->id } @things],
                  \@expected_ids,
                  'Objects came back in the expected order');

    isa_ok($obj, 'URT::Thing',  'Thing id 7 was not deleted');
$trans->rollback;

# Make a change to both an order-by and filtered property in the DB
ok($dbh->do("update thing set other = 'blahblah' where thing_id = 7"),
   'Change thing id 7 "other" property in the database');
ok($dbh->do("update thing set value = 'A' where thing_id = 7"),
   'Change thing id 7 value to "A" in the database');
@things = UR::Context->reload('URT::Thing', 'other ne' => 'blahblah', -order => ['value']);
is(scalar(@things), 5, 'Got back 5 things from reload() where other is not blahblah');
@expected_ids = (9,12345,5,8,3);
is_deeply([ map { $_->id } @things],
              \@expected_ids,
              'Objects came back in the expected order');
ok(URT::Thing->get(7), 'Thing id 7 was not deleted');




ok($dbh->do('delete from thing'),
   'Delete all remaining things from the database');
@things = UR::Context->reload('URT::Thing');
is(scalar(@things), 1, 'reload() returned one thing');
is($things[0]->id, $defined_thing->id, 'It was the thing we defined at the beginning of the test');



ok($defined_thing->delete, "Delete the defined object");
@things = UR::Context->reload('URT::Thing');
is(scalar(@things), 0, 'reload() returned no objects');






