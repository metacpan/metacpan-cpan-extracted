#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Text::Chomped;

sub sentence { chomped <<_END_ }
A quick brown fox jumped over the lazy dog
_END_

is( sentence, "A quick brown fox jumped over the lazy dog" );
is( chopped "Xyzzy", "Xyzz" );
cmp_deeply( scalar chomped [ "A\n", "b", "c\n" ], [qw/ A b c /] );
cmp_deeply( scalar chopped [ "A\n", "b", "c\n" ], [ 'A', '', 'c' ] );

cmp_deeply( [ map { chomped $_ } "A\n", "b", "c\n" ], [qw/ A b c /] );

1;
