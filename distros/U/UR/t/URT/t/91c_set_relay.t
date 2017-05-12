use strict;
use warnings;
use Test::More tests=> 15;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar, is_cool integer, age integer )'),
   'created person table');
ok($dbh->do('create table CAR
            ( car_id int NOT NULL PRIMARY KEY, color varchar, is_primary int, owner_id integer references PERSON(person_id))'),
   'created car table');
ok($dbh->do('create table CAR_ENGINE
            (engine_id int NOT NULL PRIMARY KEY, car_id integer references CAR(car_id), size number)'),
   'created car_engine table');

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    table_name => 'PERSON',
    id_by => [
        person_id           => { is => 'Number' },
    ],
    has => [
        name                => { is => 'Text' },
        is_cool             => { is => 'Boolean' },
        age                 => { is => 'Integer' },
        cars                => { is => 'URT::Car', reverse_as => 'owner', is_many => 1, is_optional => 1 },
        primary_car         => { is => 'URT::Car', via => 'cars', to => '__self__', where => ['is_primary true' => 1] },
        car_colors          => { via => 'cars', to => 'color', is_many => 1 },
        primary_car_color   => { via => 'primary_car', to => 'color' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'created class for people');

ok(UR::Object::Type->define(
        class_name => 'URT::Car',
        table_name => 'CAR',
        id_by => [
            car_id          => { is => 'Number' },
        ],
        has => [
            color           => { is => 'String' },
            is_primary      => { is => 'Boolean' },
            owner           => { is => 'URT::Person', id_by => 'owner_id' },
            engine          => { is => 'URT::Car::Engine', reverse_as => 'car', is_many => 1 },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "created class for Car");

ok(UR::Object::Type->define(
        class_name => 'URT::Car::Engine',
        table_name => 'CAR_ENGINE',
        id_by => [
            engine_id   => { is => 'Number' },
        ],
        has => [
            size        => { is => 'Number' },
            car         => { is => 'URT::Car', id_by => 'car_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "created class for Engine");

# Insert some data
# Bob and Mike have red cars, Fred and Joe have blue cars.  Frank has no car.  Bob, Joe and Frank are cool
# Bob also has a yellow car that's his primary car
my $insert = $dbh->prepare('insert into person values (?,?,?,?)');
foreach my $row ( [ 11, 'Bob',1, 25 ], [12, 'Fred',0, 30], [13, 'Mike',0, 35],[14,'Joe',1, 40], [15,'Frank', 1, 45] ) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into car values (?,?,?,?)');
foreach my $row ( [ 1,'red',0,  11], [ 2,'blue',1, 12], [3,'red',1,13],[4,'blue',1,14],[5,'yellow',1,11] ) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into car_engine values (?,?,?)');
foreach my $row ( [100, 1, 350], [ 200, 2, 400], [300, 3, 428], [400, 4, 429], [500, 5, 289] ) {
    $insert->execute(@$row);
}
$insert->finish();

my $query_count = 0;
my $query_text = '';
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_text = $_[0]; $query_count++}),
    'created a subscription for query');

#$DB::single = 1;

my $bx1 = URT::Person->define_boolexpr(
    'is_cool' => 1,
    'cars.color' => 'red',
    'cars.engine.size' => 428,
    'cars.is_primary true' => 1,
);

my $s1 = URT::Person->define_set($bx1);
ok($s1, "made an initial set $s1");

my $bx1r1 = $bx1->reframe('primary_car')->normalize;
my $s2 = $s1->primary_car_set;
is($s2->id, $bx1r1->id, "the expected reframed id on related set $s2");

my $bx1r2 = $bx1->reframe('primary_car.engine')->normalize;
my $s3 = $s2->engine_set;
is($s3->id, $bx1r2->id, "the expected reframed id on related set $s3");

my $s5 = $s1->__related_set__('cars.engine');
is($s5->id, $s3->id, "reframed set two steps away persons's cars.engine");

my $s6 = $s5->car_set->owner_set;
ok($s6, "went back from the engine set to the car to the owner");
is($s6->id, $s1->id, "the owner set from the engine matches the original");

#$DB::single = 1;
my $bx4 = $s2->rule->reframe("color");
ok($bx4, "got color reframe $bx4");

my $bx7 = URT::Car::Engine->define_boolexpr('car.owner_id' => 1234);
my $bx7r = $bx7->reframe('car.owner');

#$DB::single = 1;
my $z1 = URT::Car->define_boolexpr("color" => "red");
print "$z1\n";
my $z2 = $z1->reframe("owner");
print "$z2\n";
my $z4 = $z1->reframe("engine");
print "$z4\n";
my $z3 = $z1->reframe("color");
print "$z3\n";

__END__
my $s4 = $s2->color_set();
ok($s4, "got a set of colors: $s4");

__END__
note("******** or *********");

my $bx5 = URT::Person->define_boolexpr(
    -or => [
        ['is_cool' => 1],
        ['primary_car.color' => 'red'],
    ]
);
ok($bx5, "created an 'or' boolexpr $bx5");

my $s5 = URT::Person->define_set($bx5);
ok($s5, "made a set for it $s5");
is($s5->rule->id, $bx5->id, "id is correct");

my $bx6 = $bx5->reframe('primary_car');
ok($bx6, "$bx6");

my $s6 = $s5->primary_car_set();
ok($s6, "$s6");
is($s6->id, $bx6->id, "id is correct");




