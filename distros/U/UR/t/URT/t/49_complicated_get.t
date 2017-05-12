use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 17;
use URT::DataSource::SomeSQLite;

# This tests a get() with several unusual properties....
#     - The subclass we're get()ting has no table of its own; it inherits one from its parent
#     - The property we're get()ting with isn't a column in its inherited table, it's delegated
#     - That delegated property is 'via' another subclass with no table of its own
#     - The delegated property is 'to' another delegated property
#
# UR::DataSource::RDBMS was modified to properly determine table/column when the subclass
# inherits that table/column from a parent.  It also needed to traverse delegated properties
# to arbitrary depth to know what the final accessor is.

&setup_classes_and_db();

my $thing = URT::Thing::Person->get(job => 'cook');
ok($thing, 'get() returned an object');
isa_ok($thing, 'URT::Thing::Person');
is($thing->name, 'Bob', 'The expected object was returned');
is($thing->job, 'cook', 'the delegated property has the expected value');




sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing_type (type_id integer, type_name varchar)"),
       'Created type table');

    ok( $dbh->do("create table thing (thing_id integer, name varchar, type_id integer REFERENCES thing_type(type_id))"),
       'Created thing table');


    ok( $dbh->do("create table param (param_id integer, type varchar, value varchar, type_id integer REFERENCES thing_type(type_id))"),
       'Created param table');

    my $ins_type = $dbh->prepare("insert into thing_type (type_id, type_name) values (?,?)");
    foreach my $row ( ( [1, 'person'], [2, 'car'] ) ) {
        ok( $ins_type->execute(@$row), 'Inserted a type');
    }

    my $ins_thing = $dbh->prepare("insert into thing (thing_id, name, type_id) values (?,?,?)");
    foreach my $row ( ( [1, 'Bob',1], [2, 'Christine',2]) ) {
        ok( $ins_thing->execute(@$row), 'Inserted a thing');
    }
    $ins_thing->finish;

    my $ins_params = $dbh->prepare("insert into param (param_id, type, value, type_id) values (?,?,?,?)");
    foreach my $row ( ( [1, 'alignment', 'good', 1],
                        [2, 'job', 'cook', 1], 
                        [3, 'alignment', 'evil', 2],
                        [4, 'color', 'red', 2] ) ) {
        ok($ins_params->execute(@$row), 'Inserted a param');
    }
    
    ok($dbh->commit(), 'DB commit');
           
 
    UR::Object::Type->define(
        class_name => 'URT::ThingType',
        id_by => [
            type_id => { is => 'Integer' },
        ],
        has => [
            type_name => { is => 'String' },
            params => { is => 'URT::Param', reverse_as => 'type_obj', is_many => 1 },
            alignment => { via => 'params', to => 'value', where => [param_type => 'alignment'] },
        ],
        is_abstract => 1,
        sub_classification_method_name => '_type_resolve_subclass_name',
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing_type',
    );
    UR::Object::Type->define(
        class_name => 'URT::ThingType::Person',
        is => 'URT::ThingType',
        has => [
            job => { via => 'params', to => 'value', where => [type => 'job'] },
        ]
    );
    UR::Object::Type->define(
        class_name => 'URT::ThingType::Car',
        is => 'URT::ThingType',
        has => [
            color => { via => 'params', to => 'value', where => [type => 'color'] },
        ]
    );

        
     UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => [
            name => { is => 'String' },
            type_obj => { is => 'URT::ThingType', id_by => 'type_id' },
            type => { via => 'type_obj', to => 'type_name' },
            params => { via => 'type_obj' },
            alignment => { via => 'params' },
        ],
        is_abstract => 1,
        #sub_classification_property_name => 'type',
        sub_classification_method_name => '_thing_resolve_subclass_name',
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );
    UR::Object::Type->define(
        class_name => 'URT::Thing::Person', 
        is => 'URT::Thing',
        has => [ 
            type_obj => { is => 'URT::ThingType::Person', id_by => 'type_id' },
            job => { via => 'type_obj' },
        ],
    );
    UR::Object::Type->define(
        class_name => 'URT::Thing::Car', 
        is => 'URT::Thing',
        has => [ 
            type_obj => { is => 'URT::ThingType::Car', id_by => 'type_id' },
            color => { via => 'type_obj' },
        ],
    );


           

    UR::Object::Type->define(
        class_name => 'URT::Param',
        id_by => 'param_id', 
        has => [
            type => { is => 'String' },
            value => { is => 'String' },
            type_obj => { is => 'URT::ThingType', id_by => 'type_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'param',
    );
           
}

sub URT::Thing::_thing_resolve_subclass_name {
    my($class,$obj) = @_;
    return $class . '::' . ucfirst($obj->type);
}

sub URT::ThingType::_type_resolve_subclass_name {
    my($class,$obj) = @_;
    return $class . '::' . ucfirst($obj->type_name);
}

