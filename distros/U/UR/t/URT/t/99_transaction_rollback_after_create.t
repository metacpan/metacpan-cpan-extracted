use strict;
use warnings;

use UR;

use Test::More tests => 3;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";
use URT::Test qw(txtest);

UR::Object::Type->define(
    class_name => 'Car',
    has => [
        name => {
            is => 'Text',
        },
    ],
);

is(scalar(() = Car->get()), 0, 'no cars before txtest');

txtest 'confirm rollback works' => sub {
    plan tests => 1;
    Car->create(name => 'Christine');
    is(scalar(() = Car->get()), 1, 'got one car inside txtest');
};

is(scalar(() = Car->get()), 0, 'no cars after txtest');
