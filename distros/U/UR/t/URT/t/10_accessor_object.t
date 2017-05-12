use strict;
use warnings;
use Test::More tests => 7;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use UR;

UR::Object::Type->define(
    class_name => 'Acme',
    is => 'UR::Namespace'
);

UR::Object::Type->define(
    class_name => 'Acme::Manufacturer',
    id_by => ['name'],
    has => [qw/name industry/],
);

my $m1 = Acme::Manufacturer->create(name => "Lockheed Martin");
my $m2 = Acme::Manufacturer->create(name => "Boeing");
my $m3 = Acme::Manufacturer->create(name => "Explosives R US");

UR::Object::Type->define(
    class_name => 'Acme::Product',
    has => [
        'name' => {},
        'manufacturer' => { type => 'Acme::Manufacturer', id_by => 'manufacturer_id' },
        'genius' => {},
        #'manufacturer_name' => { via => 'manufacturer', to => 'name' }, 
    ]
);

my $p1 = Acme::Product->create(name => "jet pack",     genius => 6, manufacturer => $m1);
my $p2 = Acme::Product->create(name => "hang glider",  genius => 4, manufacturer => $m2);
Acme::Product->create(name => "mini copter",  genius => 5, manufacturer => $m2); 
Acme::Product->create(name => "firecracker",  genius => 6, manufacturer => $m3);
Acme::Product->create(name => "dynamite",     genius => 7, manufacturer => $m3);
Acme::Product->create(name => "plastique",    genius => 8, manufacturer => $m3);

my @obj = Acme::Product->get();
is(scalar(@obj), 6, "got the expected objects");

#ok(Acme::Product->can("manufacturer"), "the object-accessor is present");

is(Acme::Product->get(name => "jet pack")->manufacturer->name, "Lockheed Martin", "object accessor works");
is(Acme::Product->get(name => "dynamite")->manufacturer->name, "Explosives R US", "object accessor works");

my $jetpack = Acme::Product->get(name => "jet pack");
ok($jetpack->manufacturer($m2), 'Change manufacturer on jet pack');
is($jetpack->manufacturer->name, 'Boeing', 'Change was successful');

eval { $jetpack->manufacturer('Boeing') };
ok($@, 'Setting the object accessor to a string throws an exception');
like($@,
     qr(Can't call method "id" without a package or object reference.  Expected an object as parameter to 'manufacturer', not the value 'Boeing'),
    'The exception was correct');


#is(Acme::Product->get(name => "jet pack")->manufacturer_name, "Lockheed Martin", "delegated accessor works");
#is(Acme::Product->get(name => "dynamite")->manufacturer_name, "Explosives R US", "delegated accessor works");


