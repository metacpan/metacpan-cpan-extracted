#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

$ms = new_ok('Text::MacroScript' => [ 
				-macro => [ 
					[ ADD1 => '#0+#1' ],
				],
				-script => [ 
					[ ADD2 => '#0+#1' ],
				]]);

is $ms->expand("ADD1[ ADD1[1|2] | ADD1[3|4] ]"), " 1+2 + 3+4 ";
is $ms->expand("ADD2[ ADD2[1|2] | ADD2[3|4] ]"), "10";

done_testing;
