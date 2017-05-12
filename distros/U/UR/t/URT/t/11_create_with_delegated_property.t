use strict;
use warnings;
use Test::More 'no_plan';

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

UR::Object::Type->define(
    class_name => 'Acme::Manufacturer',
    is => 'UR::Object',
    has => [qw/name/],
);

UR::Object::Type->define(
    class_name => 'Acme::Product',
    has => [
        'name',
        'manufacturer' => { is => 'Acme::Manufacturer', id_by => 'manufacturer_id' },
        'genius' 
    ]
);


my $m1 = Acme::Manufacturer->create(name => "Lockheed Martin");
my $m2 = Acme::Manufacturer->create(name => "Boeing");
my $m3 = Acme::Manufacturer->create(name => "Explosives R US");

my $p = Acme::Product->create(name => "jet pack", genius => 6, manufacturer => $m1);
ok($p, "created a product");
is($p->manufacturer_id,$m1->id,"manufacturer on product is correct");
is($p->manufacturer,$m1,"manufacturer on product is correct");

__END__

Acme::Product->create(name => "hang glider",  genius => 4, manufacturer => $m2);
Acme::Product->create(name => "mini copter",  genius => 5, manufacturer => $m2); 
Acme::Product->create(name => "firecracker",  genius => 6, manufacturer => $m3);
Acme::Product->create(name => "dynamite",     genius => 7, manufacturer => $m3);
Acme::Product->create(name => "plastique",    genius => 8, manufacturer => $m3);

print Data::Dumper::Dumper(Acme::Product->get(name => 'jet pack'));
exit;

is(Acme::Product->get(name => "jet pack")->manufacturer->name, "Lockheed Martin");
is(Acme::Product->get(name => "dynamite")->manufacturer->name, "Explosives R US");

