use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 20;
use URT::DataSource::SomeSQLite;

# There was a bug where after a software transaction rollback, a previously
# run query would die because the joins used by a query had been unloaded by
# the rollback().  Since UR::Object::Join has its own caching, the unloaded
# joins hung around as DeletedRefs.  Those later queries would re-use these
# cached lists of (now unloaded/deleted) joins and crash in QueryPlan
#
# The fix was to override unload() in UR::Object::Join

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, 'Got DB handle');

ok( $dbh->do("create table owner (owner_id integer PRIMARY KEY, name varchar)"),
   'Created owner table');
ok( $dbh->do("create table thing (thing_id integer PRIMARY KEY, name varchar, owner_id integer REFERENCES owner(owner_id))"),
   'Created thing table');

ok( $dbh->do("insert into owner values (1, 'Bob')"),
    'Insert owner Bob');
ok( $dbh->do("insert into thing values (1, 'car', 1)"),
    "insert Bob's car");
ok( $dbh->do("insert into thing values (2, 'truck', 1)"),
    "insert Bob's truck");
ok( $dbh->do("insert into thing values (3, 'boat', 1)"),
    "insert Bob's boat");
ok($dbh->commit(), 'DB commit');

UR::Object::Type->define(
    class_name => 'URT::Owner',
    id_by => ['owner_id'],
    has => [
        name => { is => 'String' },
        things => { is => 'URT::Thing', reverse_as => 'owner', is_many => 1 },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'owner',
);
UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => [
        thing_id => { is => 'Integer' },
    ],
    has => [
        name => { is => 'String' },
        owner => { is => 'URT::Owner', id_by => 'owner_id' },
        owner_name => { via => 'owner', to => 'name' },
        owner_name2 => { via => 'owner', to => 'name' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'thing',
);

my $t = UR::Context::Transaction->begin();
ok($t, 'Start transaction');

my $meta = URT::Thing->__meta__;
ok($meta, 'Class object for URT::Thing');
my $prop = $meta->property_meta_for_name('owner_name');
ok($prop, 'Property meta for owner_name');

my @joins = $prop->_resolve_join_chain();
foreach (@joins) {
    isa_ok($_, 'UR::Object');
}

ok($t->rollback, 'Rollback');
@joins = $prop->_resolve_join_chain();
foreach (@joins) {
    isa_ok($_, 'UR::Object');
}

# Another related problem is that UR::DataSource::Default objects were
# getting unloaded
$t = UR::Context::Transaction->begin();
ok($t, 'Start another transaction');
my @things = URT::Thing->get(owner_name => 'Bob');
ok(scalar(@things), "Get Bob's things");

ok($t->rollback(), 'Rollback');

@things = URT::Thing->get(owner_name2 => 'Bob');
ok(scalar(@things), "Get Bob's again");
