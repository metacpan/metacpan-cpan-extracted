use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use URT::DataSource::SomeSQLite;
use Test::More tests => 9;


my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got DB handle');

ok( $dbh->do("create table things (thing_id integer, name varchar)"),
   'Created things table');
ok( $dbh->do("create table thing_params ( param_id integer, name varchar, value varchar, thing_id integer REFERENCES things(thing_id))"),
   'Created params table');

# Bob has the color green, Fred has tracking_number 12345
$dbh->do("insert into things (thing_id, name) values (99, 'Bob')");
$dbh->do("Insert into things (thing_id, name) values (100, 'Fred')");
$dbh->do("Insert into thing_params (param_id, thing_id, name,value) values (1, 99, 'color', 'green')");
$dbh->do("Insert into thing_params (param_id, thing_id, name,value) values (2, 100, 'tracking_number', '12345')");


ok($dbh->commit(), 'DB commit');

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => [
        thing_id => { is => 'Integer' },
    ],
    has_optional => [
        name   => { is => 'String' },
        params => { is => 'URT::ThingParam', is_many => 1, reverse_as => 'thing' },
        color  => { is => 'String', via => 'params', to => 'value', where => [ name => 'color' ] },
        tracking_number  => { is => 'String', via => 'params', to => 'value', where => [ name => 'tracking_number' ] },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'things',
);


UR::Object::Type->define(
    class_name => 'URT::ThingParam',
    id_by => 'param_id',
    has => [
        name   => { is => 'String' },
        value  => { is => 'String' },
        thing  => { is => 'URT::Thing', id_by => 'thing_id' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'thing_params',
);


my $thing = URT::Thing->get(color => undef);
ok($thing, 'Got thing with no color');
is($thing->name, 'Fred', 'It was the right thing');


my $new_thing = URT::Thing->create(name => 'Joe');
ok($new_thing, 'Created a new object with no color defined');

my $same_thing = URT::Thing->get(name => 'Joe', color => undef);
ok($same_thing, 'Got it back by specifying color => undef');
is($new_thing, $same_thing, 'and it was the same object');
