use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 50;
use URT::DataSource::SomeSQLite;

&setup_classes_and_db();

#UR::DBI->monitor_sql(1);

my $query_count;
ok(URT::DataSource::SomeSQLite->create_subscription(
                                   method => 'query',
                                   callback => sub { $query_count++ }),
    'Created subscription to count queries');
#$DB::single = 1;
$query_count = 0;
my $thing = URT::Thing->get(name => 'Bob', -hints => [ 'attribs' ]);
ok($thing, 'get() returned an object');
is($thing->name, 'Bob', 'object name is correct');
is($thing->thing_id, 1, 'ID is correct');
is($query_count, 1, 'Correctly made 1 query');

$query_count = 0;
my @attribs = URT::Attrib->is_loaded();
is(scalar(@attribs), 2, 'The last get() also loaded 2 attribs');
@attribs = sort { $a->attrib_id <=> $b->attrib_id } @attribs;  # Just in case, but they should already be in this order...
is($query_count, 0, 'Correctly made no queries');


is($attribs[0]->name, 'alignment', 'First attrib name is correct');
is($attribs[0]->value, 'good', 'First attrib value is correct');
is($attribs[1]->name, 'job', 'Second attrib name is correct');
is($attribs[1]->value, 'cook', 'Second attrib value is correct');


$query_count = 0;
@attribs = $thing->attribs();
is(scalar(@attribs), 2, 'accessing attribs through the delegated property returned 2 things');
is($query_count, 0, 'Correctly made no queries');

is($attribs[0]->name, 'alignment', 'First attrib name is correct');
is($attribs[0]->value, 'good', 'First attrib value is correct');
is($attribs[1]->name, 'job', 'Second attrib name is correct');
is($attribs[1]->value, 'cook', 'Second attrib value is correct');


$query_count = 0;
my $person = URT::Person->get(name => 'Frank', -hints => ['params']);
ok($person, 'get() returned an object');
is($person->name, 'Frank', 'object name is correct');
is($person->person_id, 2, 'ID is correct');
is($query_count, 1, 'Correctly made 1 query');

my @bridges = URT::Bridge->is_loaded();
is(scalar(@bridges), 3, '3 bridges were loaded from the above query');

my @params = URT::Param->is_loaded();
is(scalar(@params), 3, '3 params were loaded from the above query');


$query_count = 0;
@bridges = $person->bridges();
is(scalar(@bridges), 3, 'got 3 bridges through the delegated accessor');
is($query_count, 0, 'Correctly made no queries');

$query_count = 0;
@params = $person->params();
is(scalar(@params), 3, 'got 3 params through the delegated accessor');
is($query_count, 0, 'Correctly made no queries');




sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    # attribs belong to one thing
    ok( $dbh->do("create table thing (thing_id integer, name varchar)"),
       'Created thing table');
    ok( $dbh->do("create table attrib (attrib_id integer, name varchar, value varchar, thing_id integer REFERENCES thing(thing_id))"),
       'Created attrib table');

    my $insert = $dbh->prepare("insert into thing (thing_id, name) values (?,?)");
    foreach my $row ( ( [1, 'Bob'], [2, 'Christine']) ) {
        ok( $insert->execute(@$row), 'Inserted a thing');
    }
    $insert->finish;

    $insert = $dbh->prepare("insert into attrib (attrib_id, name, value, thing_id) values (?,?,?,?)");
    foreach my $row ( ( [1, 'alignment', 'good', 1],
                        [2, 'job', 'cook', 1], 
                        [3, 'alignment', 'evil', 2],
                        [4, 'color', 'red', 2] ) ) {
        ok($insert->execute(@$row), 'Inserted an attrib');
    }
    $insert->finish;

    # params are many-to-many with people
    ok( $dbh->do("create table person (person_id integer, name varchar)"), 
        'created table foo');
    ok( $dbh->do("create table param (param_id integer, name varchar, value varchar)"),
        'created param table');
    ok( $dbh->do("create table person_param_bridge (person_id integer REFERENCES person(person_id), param_id integer REFERENCES param(param_id), PRIMARY KEY (person_id, param_id))"
),
        'created bridge table');

 
    $insert = $dbh->prepare("insert into person (person_id, name) values (?,?)");
    foreach my $row ( ( [ 1, 'Joe'],
                        [ 2, 'Frank'] )) {
        ok($insert->execute(@$row), 'inserted a person');
    }
    $insert->finish;
            
    $insert = $dbh->prepare("insert into param (param_id, name, value) values (?,?,?)");
    foreach my $row ( ( [ 1, 'rank', 'cog' ],
                        [ 2, 'status', 'single' ],
                        [ 3, 'title', 'capn' ],
                        [ 4, 'tag', 'xyzzy' ] )) {
        ok($insert->execute(@$row), 'inserted a param');
    }
    $insert->finish;

    $insert = $dbh->prepare("insert into person_param_bridge (person_id, param_id) values (?,?)");
    foreach my $row ( ( [ 1, 1 ],
                        [ 2, 1 ],
                        [ 2, 2 ],
                        [ 2, 4 ] )) {
        ok($insert->execute(@$row), 'inserted a bridge');
    }
    $insert->finish;

    
    ok($dbh->commit(), 'DB commit');
           
 
    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => [
            name => { is => 'String' },
            attribs => { is => 'URT::Attrib', reverse_as => 'thing', is_many => 1 },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );

    UR::Object::Type->define(
        class_name => 'URT::Attrib',
        id_by => 'attrib_id', 
        has => [
            name => { is => 'String' },
            value => { is => 'String' },
            thing => { is => 'URT::Thing', id_by => 'thing_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'attrib',
    );

    UR::Object::Type->define(
        class_name => 'URT::Person',
        id_by => 'person_id',
        has => 'name',
        has_many_optional => [
           bridges => { is => 'URT::Bridge', reverse_as => 'persons' },
           params => { via => 'bridges', to => 'params' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'person',
    );
    UR::Object::Type->define(
        class_name => 'URT::Param',
        id_by => 'param_id',
        has => ['name','value'],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'param',
    );
    UR::Object::Type->define(
        class_name => 'URT::Bridge',
        id_by => [ 'person_id', 'param_id' ],
        has => [
            persons => { is => 'URT::Person', id_by => 'person_id' },
            params  => { is => 'URT::Param', id_by => 'param_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'person_param_bridge',
    );

        
           
}

