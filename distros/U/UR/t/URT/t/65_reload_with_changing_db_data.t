use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";

use URT;
use Test::More tests => 270;

use URT::DataSource::SomeSQLite;

# This test uses 3 independent groups of classes/tables:
# 1) One class where no subclassing is involved (URT::Thing uses table thing)
# 2) A pair of classes where we need to do a join to get the subclassed data
#    URT::Fruit uses the fruit table.  URT::Apple is its subclass and uses table
#    apple
# 3) A pair of classes where the child class has no table of its own.
#    URT::Vehicle uses table vehicle.  URT::Car is its subclass and has no table

my $dbh = &setup_classes_and_db();


# The test messes with the 'value' property/column.  This hash maps the class name 
# with which table contains the 'value' column
my %table_for_class = ('URT::Thing'   => 'thing',
                       'URT::Fruit'   => 'apple',
                       'URT::Apple'   => 'apple',
                       'URT::Vehicle' => 'vehicle',
                       'URT::Car'     => 'vehicle',
                      );

# Context exception messages complain about the class the data originally comes from
my %complaint_class = ('URT::Thing' => 'URT::Thing',
                       'URT::Fruit' => 'URT::Apple',
                       'URT::Apple' => 'URT::Apple',
                       'URT::Vehicle' => 'URT::Vehicle',
                       'URT::Car' => 'URT::Vehicle',
                     );

my $obj_id = 1; 
foreach my $test_class ( 'URT::Thing', 'URT::Fruit', 'URT::Apple', 'URT::Vehicle', 'URT::Car') {
    #diag("Working on class $test_class");
    UR::DBI->no_commit(0);

    my $test_table = $table_for_class{$test_class};

    my $this_pass_obj_id = $obj_id++;

    my $thing = $test_class->get($this_pass_obj_id);
    ok($thing, "Got a $test_class object");
    is($thing->value, 1, 'its value is 1');

    my $cx = UR::Context->current();
    ok($cx, 'Got the current context');
    
    # First test.  Make no changes and reload the object 
    ok(eval { $cx->reload($thing) }, 'Reloaded object after no changes');
    is($@, '', 'No exceptions during reload');
    ok(!scalar($thing->__changes__), 'No changes, as expected');
    
    
    # Next test, Make a change to the database, no change to the object and reload
    # It should update the object's value to match the newly reloaded DB data
    ok($dbh->do("update $test_table  set value = 2 where thing_id = $this_pass_obj_id"), 'Updated value for thing in the DB to 2');
    ok(eval { $cx->reload($thing) }, 'Reloaded object again');
    is($@, '', 'No exceptions during reload');
    is($thing->value, 2, 'its value is now 2');
    ok(!scalar($thing->__changes__), 'No changes. as expected');

    
    # make a change to the object, no change to the DB
    ok($thing->value(3), 'Changed the object value to 3');
    is(scalar($thing->__changes__), 1, 'One change, as expected');
    ok(eval { $cx->reload($thing) },' Reload object');
    is($@, '', 'No exceptions during reload');
    is($thing->value, 3, 'Value is still 3');
    is(scalar($thing->__changes__), 1, 'Still one change, as expected');
    
    # Make a change to the DB, and the exact same change to the object
    ok($dbh->do("update $test_table set value = 3 where thing_id = $this_pass_obj_id"), 'Updated value for thing in the DB to 3');
    ok($thing->value(3), "Changed the object's value to 3");
    ok($thing->__changes__, 'Before reloading, object says it has changes');
    ok(eval { $cx->reload($thing) },'Reloaded object again');
    is($@, '', 'No exceptions during reload');
    is($thing->value, 3, 'Value is 3');
    ok(! scalar($thing->__changes__), 'After reloading, object says it has no changes');
    
    
    
    # Make a change to the DB data, and a different cahange to the object.  This should fail
    ok($dbh->do("update $test_table set value = 4 where thing_id = $this_pass_obj_id"), 'Updated value for thing in the DB to 4');
    ok($thing->value(5), "Changed the object's value to 5");
    ok(! eval { $cx->reload($thing) },'Reloading fails, as expected');
    my $message = $@;
    $message =~ s/\s+/ /gm;   # collapse whitespace
    my $complaint_class = $complaint_class{$test_class};
    like($message,
         qr/A change has occurred in the database for $complaint_class property 'value' on object ID $this_pass_obj_id from '3' to '4'. At the same time, this application has made a change to that value to '5'./,
         'Exception message looks correct');
    is($thing->value, 5, 'Value is 5');
    
    
    ok(UR::DBI->no_commit(1), 'Turned on no_commit');
    ok($thing->value(6), "Changed the object's value to 6");
    ok(UR::Context->commit(), 'calling commit()');
    ok($dbh->do("update $test_table set value = 6 where thing_id = $this_pass_obj_id"), 'Updated value for thing in the DB to 6');
    ok(eval { $cx->reload($thing) },'Reloading object again');
    is($@, '', 'No exceptions during reload');
    is($thing->value, 6, 'Value is 6');
    
    ok(UR::DBI->no_commit(1), 'Turned on no_commit');
    ok($thing->value(7), "Changed the object's value to 7");
    ok(UR::Context->commit(), 'calling commit()');
    ok($dbh->do("update $test_table set value = 7 where thing_id = $this_pass_obj_id"), 'Updated value for thing in the DB to 7');
    ok($thing->value(8), 'Changed object value to 8');
    ok(eval { $cx->reload($thing) },'Reloading object again');
    is($@, '', 'No exceptions during reload');
    is($thing->value, 8, 'Value is 8');
    
    ok(UR::DBI->no_commit(1), 'Turned on no_commit');
    ok($thing->value(9), "Changed the object's value to 9");
    ok(UR::Context->commit(), 'calling commit()');
    ok($dbh->do("update $test_table set value = 10 where thing_id = $this_pass_obj_id"), 'Updated value for thing in the DB to 10');
    ok($thing->value(11), 'Changed object value to 11');
    ok(! eval { $cx->reload($thing) },'Reloading fails, as expected');
    $message = $@;
    $message =~ s/\s+/ /gm;   # collapse whitespace
    like($message,
         qr/A change has occurred in the database for $complaint_class property 'value' on object ID $this_pass_obj_id from '9' to '10'. At the same time, this application has made a change to that value to '11'/,
         'Exception message looks correct');
    is($thing->value, 11, 'Value is 11');
}





 




sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing (thing_id integer PRIMARY KEY, value integer)"),
        'created thing table');

    ok($dbh->do("create table fruit (thing_id integer PRIMARY KEY, fruitvalue integer) "),
         'created fruit table');

    ok($dbh->do("create table apple(thing_id integer PRIMARY KEY references fruit(thing_id), value integer)"),
         'created apple table');

    ok($dbh->do("create table vehicle (thing_id integer PRIMARY KEY, value integer) "),
         'created vehicle table');

    my $sth = $dbh->prepare('insert into thing values (?,?)');
    ok($sth, 'Prepared insert statement');
    foreach my $val ( 1,2,3,4,5 ) {   # We need one item for each class under test at the top
        $sth->execute($val,1);
    }
    $sth->finish;

    my $fruitsth = $dbh->prepare('insert into fruit values (?,?)');
    ok($fruitsth, 'Prepared fruit insert statement');
    my $applesth = $dbh->prepare('insert into apple values (?,?)');
    ok($applesth, 'Prepared apple insert statement');
    my $vehiclesth = $dbh->prepare('insert into vehicle values (?,?)');
    ok($vehiclesth, 'Prepared vehicle insert statement');
    foreach my $val ( 1,2,3,4,5 ) {   # one item for each class here, too
        $fruitsth->execute($val,1);
        $applesth->execute($val,1);
        $vehiclesth->execute($val,1);
    }
    $fruitsth->finish;
    $applesth->finish;
    $vehiclesth->finish;

    ok($dbh->commit(), 'DB commit');

    # A class we can load directly
    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => [ 'value' ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );

    # A pair of classes, one that inherits from another.  The child class
    # has a table that gets joined
    sub URT::Fruit::resolve_subclass_name {
        return 'URT::Apple';    # All are Apples for this test
    }
    UR::Object::Type->define(
        class_name => 'URT::Fruit',
        sub_classification_method_name => 'resolve_subclass_name',
        id_by => 'thing_id',
        has => [ 'fruitvalue' ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'fruit',
        is_abstract => 1,
    );

    UR::Object::Type->define(
        class_name => 'URT::Apple',
        is => 'URT::Fruit',
        id_by => 'thing_id',
        has => [ 'value' ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'apple',
    );


    # Another pair of classes.  This time, the child class does not have its own table.
    sub URT::Vehicle::resolve_subclass_name {
        return 'URT::Car';    # All are Cars for this test
    }
    UR::Object::Type->define(
        class_name => 'URT::Vehicle',
        sub_classification_method_name => 'resolve_subclass_name',
        id_by => 'thing_id',
        has => [ 'value' ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'vehicle',
        is_abstract => 1,
    );

    UR::Object::Type->define(
        class_name => 'URT::Car',
        is => 'URT::Vehicle',
    );

    return $dbh;
}
        
   


