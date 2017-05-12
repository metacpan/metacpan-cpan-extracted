use strict;
use warnings;
use Test::More tests=> 15;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use Test::Exception;

# the initial code is from test 91b, to set-up some joinable data

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

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
        primary_car         => { is => 'URT::Car', via => 'cars', to => '__self__', where => ['is_primary true' => 1], is_optional => 1 },     # direct where
        big_cars            => { is => 'URT::Car', via => 'cars', to => '__self__', where => [ 'engine_size >=' => 400 ], }, # indirect where
        car_colors          => { via => 'cars', to => 'color', is_many => 1 },
        primary_car_color   => { via => 'primary_car', to => 'color' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'Created class for people');

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
            engine_size     => { is => 'Number', via => 'engine', to => 'size' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for Car");

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
    "Created class for Engine");

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
    'Created a subscription for query');

#$DB::single = 1;

throws_ok { URT::Person->define_boolexpr('primary_car.bogus' => 'foo') }
        qr/Some parts from property 'primary_car.bogus' of class URT::Person didn't resolve/,
        'Chaining to a non-existent property throws exception';

# chain property equiv
my $bx1 = URT::Person->define_boolexpr('primary_car.color' => 'red');
ok($bx1, "got bx with property chain");

my @p1 = URT::Person->get('primary_car.color' => 'red');
is(scalar(@p1), 1, "got one person with a primary car color of red using a property chain");

my @p2 = URT::Person->get('primary_car_color' => 'red');
is(scalar(@p2),1,"got one person with a primary car color of red using a custom accessor");

is($p1[0], $p2[0], "result matches");

my @p3 = URT::Person->get('primary_car.color' => ['red']);
is(scalar(@p3), 1, "got one person with a primary car color of red using a property chain and the \"in\" operator");

my $bx5 = URT::Person->define_boolexpr('cars.color' => 'blue', 'cars.engine.size' => '400');

my @p5 = URT::Person->get($bx5);
ok("@p5", "regular query works for " . scalar(@p5) . " objects");

__END__

my $bx4i = URT::Person->define_boolexpr('big_cars.color' => 'red');
my $bx4f = $bx4i->flatten;
print "$bx4i\n$bx4f\n";
my @p4f = URT::Person->get($bx4f);
ok("@p4f", "flat query $bx4f works for " . scalar(@p4f) . " objects");

# we must flatten before query for this to work, and currently constant_values need support
my @p4i = URT::Person->get($bx4i);
ok("@p4i", "indirect query works");
is("@p4i", "@p4f", "indirect and flat query results match");

# the bx "operator" could be named "subquery" or we turn "matches" into "matches-bx" and "matches-regex"
#my @p = URT::Person->get('primary_car.color' => 'red');
my $rule1 = URT::Car->define_boolexpr(color => 'red');
ok($rule1, "made a 'car has color red' rule");
note("$rule1");

#$DB::single = 1;
my $rule2 = URT::Person->define_boolexpr('cars bx' => $rule1->id);
ok($rule2, "made a 'person has primary_car with color is red'");
note("$rule2");

my @p = URT::Person->get($rule2);
is(scalar(@p), 1, "got one person with a red primary car");
is($p[0]->id, 13, "got the expected person");


