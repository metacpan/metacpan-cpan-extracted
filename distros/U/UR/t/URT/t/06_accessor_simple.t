use strict;
use warnings;
use Test::More tests => 4;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

my ($obj,$same_obj);

use UR;

UR::Object::Type->define(
    class_name => 'Acme::Product',
    has => [qw/name manufacturer_name/]
);

$obj = Acme::Product->create(name => "dynamite", manufacturer_name => "Explosives R US");
ok($obj, 'Created object with name and manufacturer_name');

is($obj->name, "dynamite", 'name accessor works');
is($obj->manufacturer_name, "Explosives R US", 'manufacturer_name accessor works');

#

$same_obj = Acme::Product->get(name => "dynamite");

is($obj,$same_obj, 'Get same object returns the same reference');

