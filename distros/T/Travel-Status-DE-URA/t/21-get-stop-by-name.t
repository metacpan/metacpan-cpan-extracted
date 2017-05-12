#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use utf8;

use Encode qw(decode);
use List::Util qw(first);
use Test::More tests => 5;

BEGIN {
	use_ok('Travel::Status::DE::URA');
}
require_ok('Travel::Status::DE::URA');

my $s      = Travel::Status::DE::URA->new(
	ura_base  => 'file:t/in',
	ura_version => 1,
	hide_past => 0
);

# fuzzy matching: bushof should return Aachen Bushof, Eschweiler Bushof,
# Eupon Bushof

my @fuzzy = $s->get_stop_by_name('bushof');

is_deeply(\@fuzzy, ['Aachen Bushof', 'Eschweiler Bushof', 'Eupen Bushof'],
'fuzzy match for "bushof" works');

# fuzzy matching: whitespaces work

@fuzzy = $s->get_stop_by_name('Aachen Bushof');

is_deeply(\@fuzzy, ['Aachen Bushof'],
'fuzzy match with exact name "Aachen Bushof" works');

# fuzzy matching: exact name only matches one, even though longer alternatives
# exist

@fuzzy = $s->get_stop_by_name('brand');

is_deeply(\@fuzzy, ['Brand'],
'fuzzy match with exact name "brand" works');
