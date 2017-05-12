use strict;
use warnings;
use Test::More tests => 9;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

my ($p1,$p2,$p3,$p4,$p5,$p6,$p7,@obj,@got,@expected);

use UR;

UR::Object::Type->define(
    class_name => 'Acme::Product',
    has => [qw/name manufacturer_name/]
);

$p1 = Acme::Product->create(name => "jet pack",     manufacturer_name => "Lockheed Martin");
ok($p1, 'Created a jet pack');
$p2 = Acme::Product->create(name => "hang glider",  manufacturer_name => "Boeing");
ok($p2, 'Created a hang glider');
$p3 = Acme::Product->create(name => "mini copter",  manufacturer_name => "Boeing");
ok($p2, 'Created a mini copter');
$p4 = Acme::Product->create(name => "firecracker",  manufacturer_name => "Explosives R US");
ok($p2, 'Created a firecracker');
$p5 = Acme::Product->create(name => "dynamite",     manufacturer_name => "Explosives R US");
ok($p2, 'Created a dynamite');
$p6 = Acme::Product->create(name => "plastique",    manufacturer_name => "Explosives R US");
ok($p2, 'Created a plastique');

@obj = Acme::Product->get(manufacturer_name => "Boeing");
is(scalar(@obj), 2, 'Two objects have manufacturer_name => "Boeing"');

#

@obj = Acme::Product->get();
is(scalar(@obj), 6, 'There were six objects total');

@got        = sort @obj;
@expected   = sort ($p1,$p2,$p3,$p4,$p5,$p6);
is_deeply(\@got,\@expected, 'They are in the expected order');

