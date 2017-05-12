#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 19;
use Test::Exception;
use autobox::Closure::Attributes;

my ($inc, $double) = do {
    my $x = 10;
    (sub { ++$x }, sub { $x *= 2 });
};

is($inc->x, 10);
is($inc->(), 11);
is($inc->x, 11);
is($inc->x(50), 50);
is($inc->(), 51);

throws_ok { $inc->y } qr/CODE\(0x[0-9a-fA-F]+\) does not close over \$y at/;

my $copy = $inc;

is($copy->x, 51);
is($inc->(), 52);
is($copy->x, 52);
is($copy->(), 53);
is($inc->x, 53);

is($double->x, 53);
is($double->x(10), 10);
is($copy->x, 10);
is($inc->x, 10);

is($double->(), 20);
is($double->x, 20);
is($copy->x, 20);
is($inc->x, 20);

