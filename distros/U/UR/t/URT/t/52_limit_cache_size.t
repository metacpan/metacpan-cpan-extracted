use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 25;
use URT::DataSource::SomeSQLite;

&setup_classes_and_db();

#UR::DBI->monitor_sql(1);

is(UR::Context->object_cache_size_highwater(50), 50, 'Set the max cache size to 50');
is(UR::Context->object_cache_size_lowwater(25),  25, 'Set the lowwater mark to 25');


# get a thing and hold onto a reference to it
my $thing = URT::Thing->get(thing_id => 1);
ok($thing, 'Got thing_id 1');

is( &count_things_in_cache(), 1, 'There is one object in the cache');

# Ask for an object that doesn't exist
my $not_thing = URT::Thing->get(thing_id => 99999);
ok(! $not_thing, 'get() for object that does not exist');
is( &count_things_in_cache(), 1, 'Still one object in the cache');

# We'll hold on to these, too
my @keep_datas = $thing->datas();
is(scalar(@keep_datas), 2, 'Loaded 2 hangoff datas for that thing');
is( &count_things_in_cache(), 3, 'There are three objects in the cache');



my @things = URT::Thing->get(thing_id => { operator => '<=', value => '50'} );
is(scalar(@things), 50, 'Loaded 50 things with ID <= 50');
is(&count_things_in_cache('URT::Data'), 2, '2 URT::Datas are still in the cache');
is( &count_things_in_cache(), 52, 'There are 52 objects in the cache');


@things = URT::Thing->get(thing_id => { operator => '>', value => '80'} );
is(scalar(@things), 19, 'loaded 19 things with thing_id > 80');
is( &count_things_in_cache(), 22, 'The new 19 things, plus the original thing and 2 datas are still in the cache');


$thing = undef;
is( &count_things_in_cache(), 21, 'After letting go of the original thing, there are now 21 objects in the cache');
$thing = URT::Thing->is_loaded(thing_id => 1);
ok(!$thing, 'URT::Thing id 1 is no longer loaded');


@things = ();
my @datas = URT::Data->get(id => { operator => '>', value => '80'});
is(scalar(@datas), 19, 'Loaded 19 datas with id > 80');
is(&count_things_in_cache('URT::Data'), 21, 'In total, there are 21 datas in the cache');
is(&count_things_in_cache('URT::Thing'), 19, 'Those 19 things are still loaded');
@datas = ();


@keep_datas = ();
is(&count_things_in_cache('URT::Data'), 19, 'After letting go of the original 2 datas, there are now 19 loaded');


$thing = URT::Thing->get(thing_id => 1);
ok($thing, 're-got thing_id 1 after it was purged from the cache');
$thing = undef;


@things = URT::Thing->get();
is(scalar(@things), 99, 'Got all URT::Things');
@things = ();

&count_things_in_cache();

@datas = URT::Data->get();
is(scalar(@datas), 99, 'Got all URT::Datas');
@things = URT::Thing->is_loaded();
is(scalar(@things), 0, '0 URT::Things are loaded now');
@datas = ();


&count_things_in_cache();

@things = URT::Thing->get();
is(scalar(@things), 99,'re-got all URT::Things after they were purged from the cache');









sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    # attribs belong to one thing
    $dbh->do("create table thing (thing_id integer, name varchar)");
    $dbh->do("create table hangoff (id integer, data varchar, thing_id integer REFERENCES thing(thing_id))");

    my $insert = $dbh->prepare("insert into thing (thing_id, name) values (?,?)");
    for (my $i = 1; $i < 100; $i++) {
        $insert->execute($i, $i);
    }
    $insert->finish;

    # Two of these hangoffs will be related to one thing
    $insert = $dbh->prepare("insert into hangoff (id, data, thing_id) values (?,?,?)");
    for (my $i = 1; $i < 100; $i++) {
        my $thing_id = int(($i+1)/2);
        $insert->execute($i, $i, $thing_id);
    }
    $insert->finish;

    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => [
            thing_id => { is => 'Integer' },
        ],
        has => [
            name => { is => 'String' },
            datas => { is => 'URT::Data', reverse_as => 'thing', is_many => 1 },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );

    UR::Object::Type->define(
        class_name => 'URT::Data',
        id_by => 'id', 
        has => [
            data => { is => 'String' },
            thing => { is => 'URT::Thing', id_by => 'thing_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'hangoff',
    );
}



sub count_things_in_cache {
    my $count = 0;
    
    my @classes;
    if (@_) {
        @classes = @_;
    } else {
        @classes = ( 'URT::Thing', 'URT::Data' );
    }

    foreach my $c ( @classes ) {
#        my $this = scalar(values %{$UR::Context::all_objects_loaded->{$c}});
#        print "Found $this $c objects\n";
#        foreach (values %{$UR::Context::all_objects_loaded->{$c}} ) {
#            print "\tid ",$_->id,"\n";
#        }
        $count += scalar(grep { defined } values %{$UR::Context::all_objects_loaded->{$c}});
    }
    return $count;
}
