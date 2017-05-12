#!/usr/bin/perl

# t/14-export.t

#
# Written by Sébastien Millet
# September 2016
#

#
# Test script for Text::AutoCSV: exported functions
#

use strict;
use warnings;

use utf8;

use Test::More tests => 4;
#use Test::More qw(no_plan);

	# FIXME
	# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

use Text::AutoCSV 'remove_accents';

note("");
note("[EX]ported functions");

can_ok('Text::AutoCSV', 'remove_accents');

my $r = remove_accents('Être ou ne pas être un ça (ÇA ?) élémentaire - cœur - ß');
is($r, 'Etre ou ne pas etre un ca (CA ?) elementaire - cœur - ß',
	'remove_accents: latin1 characters (encoded in UTF-8)');
$r = remove_accents('muž žena dítě');
is($r, 'muz zena dite', 'remove_accents: latin2 characters (encoded in UTF-8)');

$r = remove_accents("Français: être élémentaire, Tchèque: služba dům");
is ($r, 'Francais: etre elementaire, Tcheque: sluzba dum',
	'remove_accents: latin1+2 characters (encoded in UTF-8)');

done_testing();


