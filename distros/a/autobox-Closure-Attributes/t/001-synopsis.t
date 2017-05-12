#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use autobox::Closure::Attributes;

sub accgen {
    my $n = shift;
    return sub { $n += shift || 1 }
}

my $from_3 = accgen(3);

is($from_3->n, 3);
is($from_3->(), 4);
is($from_3->n, 4);
is($from_3->n(10), 10);
is($from_3->(), 11);
throws_ok { $from_3->m } qr/CODE\(0x[0-9a-fA-F]+\) does not close over \$m at/;

