#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use autobox::Closure::Attributes;

sub accgen {
    my $n = shift;
    return sub { $n += shift || 1 }
}

my $from_3 = accgen(3);
my $from_5 = accgen(5);

is($from_3->n, 3);
is($from_5->n, 5);

$from_3->();

is($from_3->n, 4);
is($from_5->n, 5);

$from_3->n(10);

is($from_3->n, 10);
is($from_5->n, 5);

$from_5->();

is($from_3->n, 10);
is($from_5->n, 6);

$from_5->n(20);

is($from_3->n, 10);
is($from_5->n, 20);

