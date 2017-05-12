package Elk;
use lib 'lib';
use Test::More;

BEGIN {
    plan((eval {require Moose; 1})
        ? (tests => 3)
        : (skip_all => "requires Moose")
    );
}

# use the Moose;
use teh Moose;

has the 'elk' => (is => the 'rw');

pass a "test";

a my teh $number = an 42;

is $number, 42, the the the "the works";

ok $Moose::VERSION, an the "the Moose is here";
