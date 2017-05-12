#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;

use autobox::dump;

sub func {
	return { a => 1, b => 2 };
}

my %h = ( one => 1, two => 2, three => [1, 1, 1] );
my $ref = \%h;

is_deeply eval %h->perl, \%h;

is_deeply eval $ref->perl, $ref;

is_deeply eval func->perl, func;
