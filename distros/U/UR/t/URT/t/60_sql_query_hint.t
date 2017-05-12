use strict;
use warnings;
use Test::More tests=> 12;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

# Make sure query_hint and join_hint in class metadata appear in the generated SQL

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar, is_cool integer )'),
   'created person table');
ok($dbh->do('create table CAR
            ( car_id int NOT NULL PRIMARY KEY, color varchar, is_primary int, owner_id integer references PERSON(person_id))'),
   'created car table');

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    table_name => 'PERSON',
    select_hint => '/* person hint */',
    id_by => [
        person_id => { is => 'NUMBER' },
    ],
    has => [
        name      => { is => 'String' },
        is_cool   => { is => 'Boolean' },
        cars       => { is => 'URT::Car', reverse_as => 'owner', is_many => 1, is_optional => 1 },
        car_colors => { via => 'cars', to => 'color', is_many => 1, },
        primary_car => { is => 'URT::Car', reverse_as => 'owner', where => ['is_primary true' => 1], is_many => 1 },
        primary_car_color => { via => 'primary_car', to => 'color' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'Created class for people');

ok(UR::Object::Type->define(
        class_name => 'URT::Car',
        table_name => 'CAR',
        query_hint => '/* car hint */',   # query_hint is an alias for select_hint
        join_hint => '/* car join hint */',
        id_by => [
            car_id =>           { is => 'NUMBER' },
        ],
        has => [
            color   => { is => 'String' },
            is_primary => { is => 'Boolean' },
            owner   => { is => 'URT::Person', id_by => 'owner_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for Car");


# Insert some data
# Bob and Mike have red cars, Fred and Joe have blue cars.  Frank has no car.  Bob, Joe and Frank are cool
# Bob also has a yellow car that's his primary car
my $insert = $dbh->prepare('insert into person values (?,?,?)');
foreach my $row ( [ 1, 'Bob',1 ], [2, 'Fred',0], [3, 'Mike',0],[4,'Joe',1], [5,'Frank', 1] ) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into car values (?,?,?,?)');
foreach my $row ( [ 1,'red',0,  1], [ 2,'blue',1, 2], [3,'red',1,3],[4,'blue',1,4],[5,'yellow',1,1] ) {
    $insert->execute(@$row);
}
$insert->finish();


my $query_count = 0;
my $query_text = '';
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {
                                my($ds, $method, $query) = @_;
                                $query_text = $query; $query_count++
                    }),
    'Created a subscription for query');


my @p = URT::Person->get(1);
is(scalar(@p), 1, 'Got one person');
like($query_text, qr(/\* person hint \*/), 'Saw the person hint');


@p = URT::Person->get(id => 2, -hint => ['cars']);
is(scalar(@p), 1, 'Got a different person');
like($query_text, qr(/\* person hint car join hint \*/), 'Saw both hints');

my @c = URT::Car->get(id => 5);
is(scalar(@c), 1, 'Got one car');
like($query_text, qr(/\* car hint \*/), 'Saw the car hint');
