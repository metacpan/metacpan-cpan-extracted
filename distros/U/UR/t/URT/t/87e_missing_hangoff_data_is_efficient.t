use strict;
use warnings;
use Test::More tests=> 44;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

# Tests a class that has optional hangoff data.
# query for objects, including hints for the hangoffs, and then call the
# accessor for the hangoff data.  The accessors should not trigger additional
# DB queries, even for those with missing hangoff data.

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar )'),
   'created person table');

ok($dbh->do('create table PERSON_INFO
            (pi_id int NOT NULL PRIMARY KEY, person_id integer REFERENCES person(person_id), key varchar, value_class_name varchar, value_id varchar)'),
    'created person_info table');

$dbh->do("insert into person values (1,'Kermit')");
$dbh->do("insert into person_info values (1,1,'color', 'UR::Value::Text', 'green')");
$dbh->do("insert into person_info values (2,1,'species', 'UR::Value::Text','frog')");
$dbh->do("insert into person_info values (3,1,'food', 'UR::Value::Text','flies')");

$dbh->do("insert into person values (2,'Miss Piggy')");
$dbh->do("insert into person_info values (4,2,'color','UR::Value::Text','pink')");
$dbh->do("insert into person_info values (5,2,'species','UR::Value::Text','pig')");
$dbh->do("insert into person_info values (6,2,'sport','UR::Value::Text','karate')");
$dbh->do("insert into person_info values (7,2,'truelove','URT::Person','1')");

$dbh->do("insert into person values (3,'Fozzy')");
$dbh->do("insert into person_info values (8,3,'color','UR::Value::Text','brown')");
$dbh->do("insert into person_info values (9,3,'species','UR::Value::Text','bear')");
$dbh->do("insert into person_info values (10,3,'sport','UR::Value::Text','golf')");

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'PERSON',
    id_by => [
        person_id => { is => 'NUMBER' },
    ],
    has => [
        name        => { is => 'String' },
        infos       => { is => 'URT::PersonInfo', reverse_as => 'person', is_many => 1 },
        color       => { is => 'Text',          via => 'infos', to => 'value_id', where => [key => 'color'] },
        species     => { is => 'Text',          via => 'infos', to => 'value_id', where => [key => 'species'] },
        food        => { is => 'Text',          via => 'infos', to => 'value_id', where => [key => 'food'], is_optional => 1 },
        sport       => { is => 'Text',          via => 'infos', to => 'value_id', where => [key => 'sport'], is_optional => 1 },
        truelove    => { is => 'URT::Person',   via => 'infos', to => 'value_obj', where => [key => 'truelove'], is_optional => 1 },
    ],
),
'Created class for main');

ok(UR::Object::Type->define(
        class_name => 'URT::PersonInfo',
        table_name => 'PERSON_INFO',
        data_source => 'URT::DataSource::SomeSQLite',
        id_by => [
            pi_id               => { is => 'Number' },
        ],
        has => [
            person              => { is => 'URT::Person', id_by => 'person_id' },
            key                 => { is => 'Text' },
            value_class_name    => { is => 'Text' },
            value_id            => { is => 'Text' },
            value_obj           => { is => 'UR::Object', id_class_by => 'value_class_name', id_by => 'value_id' },
        ],
    ),
"Created class for person_info");


my $query_count = 0;
my $query_text = '';
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_text = $_[0]; $query_count++}),
    'Created a subscription for query');
my $thing;

$query_count = 0;
my $kermit = URT::Person->get(id => 1, -hints => ['color','species','food','sport','truelove']);
ok($kermit, 'Got person 1');
is($query_count, 1, 'made 1 query');

$query_count = 0;
is($kermit->name, 'Kermit', 'Name is Kermit');
is($query_count, 0, 'Made no queries for direct property');

$query_count = 0;
is($kermit->color, 'green', 'Color is green');
is($query_count, 0, 'Made no queries for indirect, hinted property');

$query_count = 0;
is($kermit->species, 'frog', 'species is frog');
is($query_count, 0, 'Made no queries for indirect, hinted property');

$query_count = 0;
is($kermit->food, 'flies', 'food is fies');
is($query_count, 0, 'Made no queries for indirect, hinted property');

$query_count = 0;
is($kermit->sport, undef, 'sport is undef');
is($query_count, 0, 'Made no queries for indirect, hinted property');

$query_count = 0;
is($kermit->truelove, undef, 'truelove is undef');
is($query_count, 0, 'Made no queries for indirect, hinted property');

$query_count = 0;
my $piggy = URT::Person->get(id => 2, -hints => ['color','sport']);
ok($piggy, 'Got person 2');
is($query_count, 1, 'made 1 query');

$query_count = 0;
is($piggy->name, 'Miss Piggy', 'Name is Miss Piggy');
is($query_count, 0, 'Made no queries for direct property');

$query_count = 0;
is($piggy->color, 'pink', 'Color is pink');
is($query_count, 0, 'Made no queries for indirect, hinted property');

$query_count = 0;
is($piggy->species, 'pig', 'species is pig');
is($query_count, 1, 'Made one query for indirect, non-hinted property');

$query_count = 0;
is($piggy->food, undef, 'food is undef');
is($query_count, 1, 'Made one query for indirect, non-hinted property');

$query_count = 0;
is($piggy->sport, 'karate', 'sport is karate');
is($query_count, 0, 'Made no queries for indirect, hinted property');

#$query_count = 0;
#is($piggy->truelove, $kermit, 'truelove is kermit!');
#is($query_count, 0, 'Made no queries for indirect, hinted property');

sub unload_everything {
  for my $o (URT::PersonInfo->is_loaded()) { $o->unload }
  for my $o (URT::Person->is_loaded()) { $o->unload }
  my @loaded = URT::PersonInfo->is_loaded();
  is(scalar(@loaded), 0, "no hangoff data loaded");
}

my (@muppets, @loaded);

unload_everything();
$query_count = 0;
@muppets = URT::Person->get('truelove.id' => 1);
is(scalar(@muppets), 1, "got one muppet that loves kermit");
is($query_count, 1, "only did one query to get the muppet: succesfully re-wrote the join chain through a generic UR::Object to one with a data source");
@loaded = URT::Person->is_loaded();
is(scalar(@loaded), 2, "only loaded the object needed and the comparison object, and not the other object in the table (successfully wrote the where clause)");

unload_everything();
$kermit = URT::Person->get(1);
$query_count = 0;
@muppets = URT::Person->get('truelove' => $kermit);
is(scalar(@muppets), 1, "got one muppet that loves kermit") or diag(\@muppets);

is($query_count, 1, "only did one query to get the muppet: succesfully re-wrote the join chain through a generic UR::Object to one with a data source");
@loaded = URT::Person->is_loaded();
is(scalar(@loaded), 2, "only found the new object and the parameter object in the cachee (succesffully wrote the where clause to exclude the other db data)");

unload_everything();
$kermit = URT::Person->get(1);
$query_count = 0;
@muppets = URT::Person->get('truelove.food' => 'flies');
is(scalar(@muppets), 1, "got one muppet that loves someone who eats flies") or diag(\@muppets);

is($query_count, 1, "only did one query to get the muppet: succesfully re-wrote the join chain through a generic UR::Object to one with a data source and beyond");
@loaded = URT::Person->is_loaded();
is(scalar(@loaded), 2, "only found the new object and the parameter object in the cachee (succesffully wrote the where clause to exclude the other db data)");

