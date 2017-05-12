use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 64;
use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
&setup_classes_and_db($dbh);

foreach my $class ( 'URT::Thing', 'URT::SubclassedThing' ) {
    # try load() as an object method
    my $thing = $class->get(1);
    ok($thing, 'get() returned an object');
    isa_ok($thing, $class);
    is($thing->name, 'Bob', 'name is correct');
    is($thing->color, 'green', 'color is correct');

    my $table_name = $class->__meta__->table_name;
    my $sth = $dbh->prepare("update $table_name set color = 'purple' where thing_id = 1");
    ok($sth->execute(), 'updated the color');
    $sth->finish;
    $dbh->commit;
    
    is($thing->color, 'green', 'Before load() it still has the old color');
   
    my $cx = UR::Context->current; 
    ok($cx->reload($thing), 'Called load()');
    
    is($thing->color, 'purple', 'After load() it has the new color');

    # try load() as a class method()
    my @things = $class->get(name => 'Fred');
    is(scalar(@things),1, 'Got one thing named Fred');
    is($things[0]->color, 'black', 'color is correct');
    
    $sth = $dbh->prepare("update $table_name set color = 'yellow' where name = 'Fred'");
    ok($sth->execute(), 'updated the color');
    $sth->finish;
    $dbh->commit;
    
    @things = $cx->reload($class, name => 'Fred');
    is(scalar(@things),1, 'Again, got one thing named Fred');
    is($things[0]->color, 'yellow', 'new color is correct');
    
    
    # try updating both the object and DB, and see if it'll reload
    @things = $class->get(3);
    is(scalar(@things),1, 'Got one thing with id 3');
    is($things[0]->color, 'red', 'its color is red');
    
    $sth = $dbh->prepare("update $table_name set color = 'orange' where thing_id = 3");
    ok($sth->execute(), 'updated the color in the DB');
    $sth->finish;
    $dbh->commit;
    
    ok($things[0]->color('blue'), 'updated the color on the object');
    my $worked = eval { $cx->reload($things[0]) };
    ok(! $worked, 'calling load() on the changed object correctly fails');
    
    my $message = $@;
    $message =~ s/\s+/ /gm;
    like($message,
         qr/A change has occurred in the database for $class property 'color' on object ID 3 from 'red' to 'orange'. At the same time, this application has made a change to that value to 'blue'./,
         'Error message looks correct');
    is($things[0]->color, 'blue', 'color remains what we set it to');
    #is($things[0]->{'db_committed'}->{'color'}, 'orange', 'db_committed for the color was updated to what we set the database to');
    is(UR::Context->_get_committed_property_value($things[0],'color'),
       'orange',
       'db_committed for the color was updated to what we set the database to');
    
    # We now have to make that last object look like it's unchanged or the next get() will
    # also throw an exception
    $things[0]->color($things[0]->{'db_committed'}->{'color'});
    
    @things = $class->get();
    is(scalar(@things), 3, 'get() with no filters returns all the things');
    $sth = $dbh->prepare("update $table_name set color = 'white'");
    ok($sth->execute(), 'updated the color for all things');
    $sth->finish;
    $dbh->commit;
    $thing = $cx->reload($class, 1);
    is($thing->color, 'white', 'load() for thing_id 1 has the changed color');
    @things = $cx->reload($class);
    foreach my $thing ( @things ) {
        is($thing->color, 'white', 'load() for all things has the changed color for this object');
    }
} 


sub setup_classes_and_db {
    my $dbh = shift;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing (thing_id integer, name varchar, color varchar, type varchar)"),
       'Created thing table');

    my $ins_things = $dbh->prepare("insert into thing (thing_id, name, type, color) values (?,?,?,?)");
    foreach my $row ( ( [1, 'Bob', ,'Person', 'green' ],
                        [2, 'Fred', 'Person', 'black' ],
                        [3, 'Christine', 'Car', 'red' ] )) {
        ok($ins_things->execute(@$row), 'Inserted a thing');
    }

    ok( $dbh->do("create table subclassed_thing (thing_id integer, name varchar, color varchar, type varchar)"),
       'Created subclassed_thing table');

    $ins_things = $dbh->prepare("insert into subclassed_thing (thing_id, name, type, color) values (?,?,?,?)");
    foreach my $row ( ( [1, 'Bob', ,'Person', 'green' ],
                        [2, 'Fred', 'Person', 'black' ],
                        [3, 'Christine', 'Car', 'red' ] )) {
        ok($ins_things->execute(@$row), 'Inserted a subclassed_thing');
    }
    
    ok($dbh->commit(), 'DB commit');
           
    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => ['name', 'color', 'type' ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );

    UR::Object::Type->define(
        class_name => 'URT::SubclassedThing',
        id_by => 'thing_id',
        has => ['name', 'color', 'type' ],
        is_abstract => 1,
        sub_classification_method_name => '_resolve_subclass_name',
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'subclassed_thing',
    );
    UR::Object::Type->define(
        class_name => 'URT::SubclassedThing::Person',
        is => 'URT::SubclassedThing',
        data_source => 'URT::DataSource::SomeSQLite',
    );
    UR::Object::Type->define(
        class_name => 'URT::SubclassedThing::Car',
        is => 'URT::SubclassedThing',
        data_source => 'URT::DataSource::SomeSQLite',
    );

}


sub URT::SubclassedThing::_resolve_subclass_name {
    my($class,$obj) = @_;
    return $class . '::' . ucfirst($obj->type);
}

