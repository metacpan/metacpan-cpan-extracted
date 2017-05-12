use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use URT::DataSource::SomeSQLite;

use Test::More tests => 102;

UR::Object::Type->define(
    class_name => 'Acme',
    is => ['UR::Namespace'],
);

note('Tests for subclassing by regular property');

our $calculate_called = 0;
UR::Object::Type->define(
    class_name => 'Acme::Employee',
    subclassify_by => 'subclass_name',
    is_abstract => 1,
    has => [
        name => { type => "String" },
        subclass_name => { type => 'String' },
    ],
);

UR::Object::Type->define(
    class_name => 'Acme::Employee::Worker',
    is => 'Acme::Employee',
);

UR::Object::Type->define(
    class_name => 'Acme::Employee::Boss',
    is => 'Acme::Employee',
);

my $e1 = eval { Acme::Employee->create(name => 'Bob') };
ok(! $e1, 'Unable to create an object from the abstract class without a subclass_name');
like($@, qr/Can't use undefined value as a subclass name/, 'The exception was correct');

$e1 = Acme::Employee->create(name => 'Bob', subclass_name => 'Acme::Employee::Worker');
ok($e1, 'Created an object from the base class and specified subclass_name');
isa_ok($e1, 'Acme::Employee::Worker');
is($e1->name, 'Bob', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Worker', 'subclass_name is correct');

$e1 = Acme::Employee::Worker->create(name => 'Bob2');
ok($e1, 'Created an object from a subclass without subclass_name');
isa_ok($e1, 'Acme::Employee::Worker');
is($e1->name, 'Bob2', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Worker', 'subclass_name is correct');

$e1 = Acme::Employee->create(name => 'Fred', subclass_name => 'Acme::Employee::Boss');
ok($e1, 'Created an object from the base class and specified subclass_name');
isa_ok($e1, 'Acme::Employee::Boss');
is($e1->name, 'Fred', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Boss', 'subclass_name is correct');

$e1 = Acme::Employee::Boss->create(name => 'Fred2');
ok($e1, 'Created an object from a subclass without subclass_name');
isa_ok($e1, 'Acme::Employee::Boss');
is($e1->name, 'Fred2', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Boss', 'subclass_name is correct');

$e1 = Acme::Employee::Boss->create(name => 'Fred3', subclass_name => 'Acme::Employee::Boss');
ok($e1, 'Created an object from a subclass and specified the same subclass_name');
isa_ok($e1, 'Acme::Employee::Boss');
is($e1->name, 'Fred3', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Boss', 'subclass_name is correct');



$e1 = eval { Acme::Employee::Worker->create(name => 'Joe', subclass_name => 'Acme::Employee') };
ok(! $e1, 'Creating an object from a subclass with the base class as subclass_name did not work');
like($@,
     qr/Value for subclassifying param 'subclass_name' \(Acme::Employee\) does not match the class it was called on \(Acme::Employee::Worker\)/,
     'Exception was correct');

$e1 = eval { Acme::Employee::Worker->create(name => 'Joe', subclass_name => 'Acme::Employee::Boss') };
ok(! $e1, 'Creating an object from a subclass with another subclass as subclass_name did not work');
like($@,
     qr/Value for subclassifying param 'subclass_name' \(Acme::Employee::Boss\) does not match the class it was called on \(Acme::Employee::Worker\)/,
     'Exception was correct');

$e1 = eval { Acme::Employee::Boss->create(name => 'Joe', subclass_name => 'Acme::Employee::Worker') };
ok(! $e1, 'Creating an object from a subclass with another subclass as subclass_name did not work');
like($@,
     qr/Value for subclassifying param 'subclass_name' \(Acme::Employee::Worker\) does not match the class it was called on \(Acme::Employee::Boss\)/,
     'Exception was correct');

$e1 = eval { Acme::Employee->create(name => 'Mike', subclass_name => 'Acme::Employee::NonExistent') };
ok(! $e1, 'Creating an object from the base class and gave invalid subclass_name did not work');
like($@,
     qr/Class Acme::Employee::NonExistent is not a subclass of Acme::Employee/,
     'Exception was correct');



note('Tests for default value subclassing');

UR::Object::Type->define(
    class_name => 'Acme::Tool',
    is_abstract => 1,
    subclassify_by => 'subclass_name',
    has => [
        sku => { is => 'Number'},
        subclass_name => { is => 'String', default_value => 'Acme::Tool::Generic' },
    ],
);

UR::Object::Type->define(
    class_name => 'Acme::Tool::Hammer',
    is => 'Acme::Tool',
);

UR::Object::Type->define(
    class_name => 'Acme::Tool::Generic',
    is => 'Acme::Tool',
);

my $t = eval { Acme::Tool->create(sku => 123) };
ok($t, 'Created an Acme::Tool without subclass_name');
ok(! $@, 'No exception during create');
is($t->subclass_name, 'Acme::Tool::Generic', 'subclass_name took the default value');
isa_ok($t, 'Acme::Tool::Generic');
isa_ok($t, 'Acme::Tool');

$t = eval { Acme::Tool->create(sku => 234, subclass_name => 'Acme::Tool::Generic') };
ok($t, 'Created an Acme::Tool with subclass_name');
ok(! $@, 'No exception during create');
is($t->subclass_name, 'Acme::Tool::Generic', 'subclass_name has the correct value');
isa_ok($t, 'Acme::Tool::Generic');
isa_ok($t, 'Acme::Tool');

$t = eval { Acme::Tool::Generic->create(sku => 456) };
ok($t, 'Created an Acme::Tool::Generic without subclass_name');
ok(! $@, 'No exception during create');
is($t->subclass_name, 'Acme::Tool::Generic', 'subclass_name has the correct value');
isa_ok($t, 'Acme::Tool::Generic');
isa_ok($t, 'Acme::Tool');

$t = eval { Acme::Tool::Generic->create(sku => 456, subclass_name => 'Acme::Tool::Generic') };
ok($t, 'Created an Acme::Tool::Generic with subclass_name');
ok(! $@, 'No exception during create');
is($t->subclass_name, 'Acme::Tool::Generic', 'subclass_name has the correct value');
isa_ok($t, 'Acme::Tool::Generic');
isa_ok($t, 'Acme::Tool');

$t = eval { Acme::Tool::Generic->create(sku => 567, subclass_name => 'Acme::Tool::Broken') };
ok(! $t, 'Did not create an Acme::Tool::Generic with a non-matching subclass_name');
like($@,
     qr/Value for subclassifying param 'subclass_name' \(Acme::Tool::Broken\) does not match the class it was called on \(Acme::Tool::Generic\)/,
     'Exception was correct');

$t = eval { Acme::Tool->create(sku => 678, subclass_name => 'Acme::Tool::Hammer') };
ok($t, 'Created an Acme::Tool with subclass_name Acme::Tool::Hammer');
ok(! $@, 'No exception during create');
is($t->subclass_name, 'Acme::Tool::Hammer', 'subclass_name has the correct value');
isa_ok($t, 'Acme::Tool::Hammer');
isa_ok($t, 'Acme::Tool');

$t = eval { Acme::Tool::Hammer->create(sku => 789, subclass_name => 'Acme::Tool::Hammer') };
ok($t, 'Created an Acme::Tool::Hammer with subclass_name Acme::Tool::Hammer');
ok(! $@, 'No exception during create');
is($t->subclass_name, 'Acme::Tool::Hammer', 'subclass_name has the correct value');
isa_ok($t, 'Acme::Tool::Hammer');
isa_ok($t, 'Acme::Tool');

$t = eval { Acme::Tool::Hammer->create(sku => 678, subclass_name => 'Acme::Tool::Generic') };
ok(! $t, 'Did not create an Acme::Tool::Hammer with a non-matching subclass_name');
like($@,
     qr/Value for subclassifying param 'subclass_name' \(Acme::Tool::Generic\) does not match the class it was called on \(Acme::Tool::Hammer\)/,
     'Exception was correct');


note('Tests for indirect property subclassing');
UR::Object::Type->define(
    class_name => 'Acme::Rank',
    has => [
        name => { is => 'String' },
        soldier_subclass => { is_calculated => 1,
            calculate => q( return 'Acme::Soldier::'.ucfirst($self->name) )
        },
    ]
);

UR::Object::Type->define(
    class_name => 'Acme::Soldier',
    is_abstract => 1,
    subclassify_by => 'subclass_name',
    has => [
        name => { is => 'String' },
        rank => { is => 'Acme::Rank', id_by => 'rank_id' },
        subclass_name => { via => 'rank', to => 'soldier_subclass' },
    ],
);

UR::Object::Type->define(
    class_name => 'Acme::Soldier::Private',
    is => 'Acme::Soldier',
);

UR::Object::Type->define(
    class_name => 'Acme::Soldier::General',
    is => 'Acme::Soldier',
);

my $private = Acme::Rank->create(name => 'Private');
my $general = Acme::Rank->create(name => 'General');

is($private->soldier_subclass, 'Acme::Soldier::Private', 'Private Rank returns correct soldier subclass');
is($general->soldier_subclass, 'Acme::Soldier::General', 'General Rank returns correct soldier subclass');

my $s = eval { Acme::Soldier->create(name => 'Pyle') };
ok(!$s, 'Unable to create an object from the abstract class without a subclass_name');
like($@, qr/Infering a value for property 'subclass_name' via rule.*returned multiple values/, 'Exception is correct');

$s = eval { Acme::Soldier->create(name => 'Pyle', rank => $private) };
ok($s, 'Created object from abstract parent, subclassed via an indirect object property');
is($s->subclass_name, 'Acme::Soldier::Private', 'subclass_name is correct');
isa_ok($s, 'Acme::Soldier::Private');

$s = eval { Acme::Soldier->create(name => 'Pyle', rank_id => $private->id) };
ok($s, 'Created object from abstract parent, subclassed via an indirect object ID');
is($s->subclass_name, 'Acme::Soldier::Private', 'subclass_name is correct');
isa_ok($s, 'Acme::Soldier::Private');

$s = Acme::Soldier->create(name => 'Pyle', subclass_name => 'Acme::Soldier::Private');
ok($s, 'Created object from abstract parent with subclass_name');
isa_ok($s, 'Acme::Soldier::Private');
is($s->rank, $private, 'Rank object was filled in properly');

$s = Acme::Soldier::Private->create(name => 'Beetle');
ok($s, 'Created object from child class');
isa_ok($s, 'Acme::Soldier::Private');
is($s->rank_id, $private->id, 'Its rank_id points to the Private Rank object');

$s = eval { Acme::Soldier::Private->create(name => 'Patton', rank => $general) };
ok(! $s, 'Unable to create an object from a child class when its rank indicates a different subclass');
like($@, qr/Conflicting values for property 'rank_id'/, 'Exception is correct');


note('Tests for calculated subclassing');

# First, setup a table we'll use in the next section of tests...
my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
$dbh->do(q(create table vehicle (vehicle_id integer NOT NULL PRIMARY KEY, color varchar NOT NULL, wheels integer NOT NULL)));

$calculate_called = 0;
UR::Object::Type->define(
    class_name => 'Acme::Vehicle',
    is_abstract => 1,
    subclassify_by => 'subclass_name',
    id_by => 'vehicle_id',
    has => [
        color => { is => 'String' },
        wheels => { is => 'Integer' },
        subclass_name => { calculate_from => ['wheels'],
                           calculate => sub { my $wheels = shift;
                                              $calculate_called = 1;
                                              no warnings 'uninitialized';
                                              if (! defined $wheels) {
                                                  return;
                                              } elsif ($wheels == 2) {
                                                  return 'Acme::Motorcycle';
                                              } elsif ($wheels == 4) {
                                                  return 'Acme::Car';
                                              } elsif ($wheels == 0) {
                                                  return 'Acme::Sled';
                                              } else {
                                                 die "Can't create a vehicle with $wheels wheels";
                                              }
                                        },
                             },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'vehicle',
);

UR::Object::Type->define(
    class_name => 'Acme::Motorcycle',
    is => 'Acme::Vehicle',
);

UR::Object::Type->define(
    class_name => 'Acme::Car',
    is => 'Acme::Vehicle',
);

UR::Object::Type->define(
    class_name => 'Acme::Sled',
    is => 'Acme::Vehicle',
);

$calculate_called = 0;
my $v = eval { Acme::Vehicle->create(color => 'blue') };
ok(! $v, 'Unable to create an object from the abstract class without a subclass_name');
like($@, qr/Class Acme::Vehicle subclassify_by calculation property 'subclass_name' requires 'wheels' in the create\(\) params/, 'Exception was correct');
ok(! $calculate_called, 'The calculation function was called');

$calculate_called = 0;
$v = Acme::Vehicle->create(color => 'blue', wheels => 2, subclass_name => 'Acme::Motorcycle');
ok($v, 'Created an object from the base class by specifying subclass_name');
isa_ok($v, 'Acme::Motorcycle');
ok(! $calculate_called, 'The calculation function was not called');

$calculate_called = 0;
$v = Acme::Vehicle->create(color => 'green', wheels => 3, subclass_name => 'Acme::Motorcycle');
ok($v, 'Created another object from the base class');
isa_ok($v, 'Acme::Motorcycle');
ok(! $calculate_called, 'The calculation function was not called');

$calculate_called = 0;
$v = Acme::Vehicle->create(color => 'red', wheels => 4);
ok($v, 'Created an object from the base class by specifying wheels');
isa_ok($v, 'Acme::Car');
ok($calculate_called, 'The calculation function was called');
$calculate_called = 0;
is($v->subclass_name, 'Acme::Car', "It's subclass_name property is filled in");
ok(! $calculate_called, "Reading the subclass_name property didn't call the calculation sub");


note('Tests for loading with calculated subclassing');
$dbh->do(q(insert into vehicle(vehicle_id, color, wheels) values (99, 'blue', 2)));
$dbh->do(q(insert into vehicle(vehicle_id, color, wheels) values (98, 'green', 3)));
$dbh->do(q(insert into vehicle(vehicle_id, color, wheels) values (97, 'red', 4)));

$calculate_called = 0;
$v = Acme::Vehicle->get(99);
ok($v, 'Get an Acme::Vehicle out of the DB');
ok($calculate_called, 'The calculation function was called');
isa_ok($v, 'Acme::Motorcycle');


$calculate_called = 0;
$v = eval { Acme::Vehicle->get(98) };
ok(! $v, 'Acme::Vehicle with 3 wheels failed to load');
ok($calculate_called, 'The calculation function was called');
like($@, qr/Can't create a vehicle with 3 wheels/, 'Exception was correct');
