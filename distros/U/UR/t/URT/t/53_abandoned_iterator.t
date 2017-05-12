use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 15;
use URT::DataSource::SomeSQLite;

&setup_classes_and_db();

my $iter = URT::Thing->create_iterator(thing_value => { operator => '<', value => 15});
my @objects;
for (my $i = 1; $i < 10; $i++) {
    push @objects, $iter->next();
}
is(scalar(@objects), 9, 'Loaded 9 objects through the (still open) iterator');

my @objects2 = URT::Thing->get(thing_value => { operator => '<', value => 15 } );
is(scalar(@objects2), 14, 'get() with same params loads all relevant objects from the DB');

$iter = undef;
@objects2 = URT::Thing->get(thing_value => { operator => '<', value => 15 } );
is(scalar(@objects2), 14, 'get() with same params loads all relevant objects from the DB after undeffing the iterator');



URT::Thing->unload();
$iter = undef;



$iter = URT::Thing->create_iterator();
ok($iter, 'Created iterator with no filters');
@objects = ();
for ( my $i = 0; $i < 9; $i++) {
    my $o = $iter->next();
    unless ($o) {
        ok(0, 'calling next() on the iterator did not return an object');
    }
    push @objects, $o;
}

is(scalar(@objects), 9, 'Loaded only the first 9 objects from the iterator');

$iter = undef;

# Now try to get all the objects
@objects2 = URT::Thing->get();
is(scalar(@objects2), 19, 'get() with no filters returns all the objects after undefining the iterator');



URT::Thing->unload();



$iter = URT::Thing->create_iterator(thing_value => { operator => 'like', value => '%1%' });
ok($iter, 'Created iterator with filter on thing_value');
@objects = ();
for ( my $i = 0; $i < 9; $i++) {
    my $o = $iter->next();
    unless ($o) {
        ok(0, 'calling next() on the iterator did not return an object');
    }
    push @objects, $o;
}
is(scalar(@objects), 9, 'Loaded only the first 9 objects from the iterator');

$iter = undef;
@objects2 = URT::Thing->get(thing_value => { operator => 'like', value => '%1%' });
is(scalar(@objects2), 11, 'get() with the same filter on thing_value returns all the objects');


URT::Thing->unload();


$iter = URT::Thing->create_iterator(thing_one => 1);
ok($iter, 'Created iterator with filter on thing_one');
@objects = ();
for ( my $i = 0; $i < 9; $i++) {
    my $o = $iter->next();
    unless ($o) {
        ok(0, 'calling next() on the iterator did not return an object');
    }
    push @objects, $o;
}
is(scalar(@objects), 9, 'Loaded only the first 9 objects from the iterator');

$iter = undef;

@objects2 = URT::Thing->get(thing_one => 1);
is(scalar(@objects2), 19, 'get() with the same filter on thing_one returns all the objects');





sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing (thing_id integer, thing_value integer, thing_one integer)"),
       'Created thing table');

    my $insert = $dbh->prepare("insert into thing (thing_id, thing_value, thing_one) values (?,?,1)");
    for (my $i = 1; $i < 20; $i++) {
        unless($insert->execute($i,$i)) {
            ok(0, 'Failed in insert test data to DB');
            exit;
        }
    }
    $insert->finish;
    ok(1, 'Inserted test data to DB');
 
    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => [
            thing_value => { is => 'Integer' },
            thing_one   => { is => 'Integer' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );
}

