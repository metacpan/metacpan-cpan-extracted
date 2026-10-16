#!/usr/bin/env perl
# random_key() / random_value(): return *some* key/value from a hashref.
# (Despite the name these are not randomized; they return the first pair
# hash iteration yields. The tests only assert membership.)
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Util::Con;

my %h = ( a => 1, b => 2, c => 3 );

my $k = random_key(\%h);
ok( exists $h{$k}, "random_key returned a real key ($k)" );

my $v = random_value(\%h);
ok( (grep { $_ == $v } values %h), "random_value returned a real value ($v)" );

# The iterator is left at the start, so an each() loop afterwards sees every
# pair.  It used to be left one pair in, and the loop skipped the first.
my %five = map { $_ => 1 } 'a' .. 'e';
for my $sub ([random_key => \&random_key], [random_value => \&random_value]) {
	$sub->[1]->(\%five);
	my $n = 0;
	while (my ($k) = each %five) { $n++ }
	is( $n, 5, "an each() loop after $sub->[0] sees all 5 pairs" );
}

# Single-element hash: the answer is deterministic.
my %one = ( only => 'val' );
is( random_key(\%one),   'only', 'random_key on a 1-element hash' );
is( random_value(\%one), 'val',  'random_value on a 1-element hash' );

# Empty hash: nothing to return.
# scalar() forces scalar context: these subs fall off the end returning an
# empty list, which is undef in scalar context.
my %empty;
is( scalar random_key(\%empty),   undef, 'random_key on empty hash is undef' );
is( scalar random_value(\%empty), undef, 'random_value on empty hash is undef' );

done_testing;
