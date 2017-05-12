use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 42;
use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, 'Got DB handle');

ok( $dbh->do("create table person (person_id integer PRIMARY KEY, name varchar NOT NULL)"), 'Created person table');
ok( $dbh->do("create table car (car_id integer PRIMARY KEY, make varchar NOT NULL, owner_id integer NOT NULL REFERENCES person(person_id))"),
        'Created car table');


ok( $dbh->do("insert into person values(1, 'Henry')"),     'Insert person 1');
ok( $dbh->do("insert into person values(2, 'Louis')"),     'Insert person 2');
ok( $dbh->do("insert into person values(3, 'Walter')"),    'Insert person 3');
ok( $dbh->do("insert into person values(4, 'Frederick')"), 'Insert person 4');

ok( $dbh->do("insert into car values(1, 'Ford', 1)"),     'Insert car 1');
ok( $dbh->do("insert into car values(2, 'GM', 2)"),       'Insert car 2');
ok( $dbh->do("insert into car values(3, 'Chrysler', 3)"), 'Insert car 3');
ok( $dbh->do("insert into car values(4, 'Duesenberg', 4)"), 'Insert car 4');

ok($dbh->commit(), 'DB commit');

UR::Object::Type->define(
    class_name => 'URT::Person',
    id_by => [ 'person_id' ],
    has => [
        'name' => { is => 'String' },
        'mark' => { via => '__self__', to => 'name' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'person',
);

UR::Object::Type->define(
    class_name => 'URT::Car',
    id_by => [
        car_id => { is => 'Integer' },
    ],
    has_mutable => [
        make => { is => 'UR::Value::Text' },
        manufacturer => { is => 'String', via => '__self__', to => 'make' },
        owner => { is => 'URT::Person', id_by => 'owner_id' },
        titleholder => { via => '__self__', to => 'owner' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'car',
);

# Try calling the alias methods

my $car = URT::Car->get(manufacturer => 'GM');
ok($car, 'Got car 2 filtered by manufacturer');
is($car->id, 2, 'It is the correct car');

$car = URT::Car->get(make => 'Ford');
ok($car, 'Got car 1 via "make"');

my $another_car = URT::Car->get(manufacturer => 'Ford');
ok($another_car, 'Got car 1 via "manufacturer');
is($car, $another_car, 'They are the same car');

ok($car->make('Honda'), 'Change make');
is($car->make, 'Honda', '"make" is updated');
is($car->manufacturer, 'Honda', '"manufacturer" is the same');

ok($car->manufacturer('Toyota'), 'Change manufacturer');
is($car->make, 'Toyota', '"make" is updated');
is($car->manufacturer, 'Toyota', '"manufacturer" is the same');


# Try querying by different kinds of properties

$car = URT::Car->get('owner.name' => 'Walter');
ok($car, 'Got a car via owner.name');
is($car->make, 'Chrysler', 'It is the right car');

$car = URT::Car->get('titleholder.mark', 'Frederick');
ok($car, 'Got a car via titleholder.mark');
is($car->make, 'Duesenberg', 'It is the right car');


# Try creating something new

my $bmw_car = URT::Car->create(id => 10, make => 'BMW', owner_id => 1);
ok($bmw_car, 'Created new car with "make"');
is($bmw_car->make, 'BMW', '"make" returns correct value');
is($bmw_car->manufacturer, 'BMW', '"manufacturer" returns correct value');

my $audi_car = URT::Car->create(id => 11, manufacturer => 'Audi', owner_id => 1);
ok($audi_car, 'Created new car with "manufacturer"');
is($audi_car->make, 'Audi', '"make" returns correct value');
is($audi_car->manufacturer, 'Audi', '"manufacturer" returns correct value');

ok(UR::Context->commit(), 'Commit changes');

my $sth = $dbh->prepare('select * from car');
$sth->execute();
my $results = $sth->fetchall_hashref('car_id');
is_deeply($results,
        {   1 => { car_id => 1, make => 'Toyota', owner_id => 1 },
            2 => { car_id => 2, make => 'GM', owner_id => 2 },
            3 => { car_id => 3, make => 'Chrysler', owner_id => 3 },
            4 => { car_id => 4, make => 'Duesenberg', owner_id => 4 },
            10 => { car_id => 10, make => 'BMW', owner_id => 1 },
            11 => { car_id => 11, make => 'Audi', owner_id => 1 } },
        'Data was saved to the DB properly');




# Try with some non-standard property definitions

UR::Object::Type->define(
    class_name => 'URT::Owner',
    id_by => 'owner_id',
    has => ['name'],
);

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => 'thing_id',
    has => [
        name => { is => 'String'},
        owner => { is => 'URT::Owner' },  # no id_by
        titleholder => { via => '__self__', to => 'owner' },
    ],
);

my $owner = URT::Owner->create(name => 'Bob');
ok($owner, 'Created an Owner');
my $thing = URT::Thing->create(name => 'Thingy');
ok($thing, 'Created a Thing');

ok($thing->owner($owner), 'Assigned an owner to the thing');

# The next get() will generate an error message, suppress it
URT::Thing->__meta__->property('owner')->dump_error_messages(0);
my $thing2 = URT::Thing->get('owner.name' => 'Bob');
ok($thing2, 'Got a thing via owner.name');
is($thing2->id, $thing->id, 'It is the right Thing');

$thing2 = URT::Thing->get('titleholder.name' => 'Bob');
ok($thing2, 'Got a thing via titleholder.name');
is($thing2->id, $thing->id, 'It is the right Thing');

