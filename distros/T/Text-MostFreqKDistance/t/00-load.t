#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Text::MostFreqKDistance') || print "Bail out!\n"; }

diag( "Testing Text::MostFreqKDistance $Text::MostFreqKDistance::VERSION, Perl $], $^X" );
