use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

use Data::Dumper;
use Test::More;
use URT::DataSource::SomeSQLite;

plan tests => 14;

&setup_files_and_classes();

my $obj1 = URT::Things->get(thing_id => 1);
ok($obj1, 'Loaded thing_id 1');

$obj2 = URT::Things::Ghost->get(thing_id => 2);
ok (!$obj2, "Correctly couldn't load a ghost with thing_id 2");

ok($UR::Context::all_objects_loaded->{'URT::Things'}->{'1'}, 'thing_id 1 is in the cache');
ok(! $UR::Context::all_objects_loaded->{'URT::Things'}->{'2'}, 'thing_id 2 is not in the cache');
ok(! $UR::Context::all_objects_loaded->{'URT::Things::Ghost'}->{'1'}, 'thing_id 1 ghost is not in the cache');
ok(! $UR::Context::all_objects_loaded->{'URT::Things::Ghost'}->{'2'}, 'thing_id 2 ghost is not in the cache');

ok($obj1->delete(), 'thing_id 1 object deleted');

my $delobj = URT::Things->get(thing_id => 1);
ok(! $delobj, 'thing_id 1 object no longer exists');

$delobj = URT::Things::Ghost->get(thing_id => 1);
ok($delobj, 'thing_id 1 ghost object does exist');


1;



sub setup_files_and_classes {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok( $dbh->do('create table things (thing_id integer, thing_value varchar)'),
       'created table things');

    ok($dbh->do("insert into things (thing_id, thing_value) values (1, 'foo')"),
       'insert row 1 into things');

    ok($dbh->do("insert into things (thing_id, thing_value) values (2, 'bar')"),
       'insert row 2 into things');

    ok($dbh->do("insert into things (thing_id, thing_value) values (3, 'foo')"),
       'insert row 3 into things');

    my $meta = UR::Object::Type->define(
        class_name => 'URT::Things',
        id_by => [
           'thing_id' => { is => 'Integer' },
        ],
        has => [
            thing_value => { is => 'String' },
        ],
        table_name => 'THINGS',
        data_source => 'URT::DataSource::SomeSQLite',
    );
    ok($meta, 'Created class for URT::Things');
}
