#!/usr/bin/perl

use Test::More tests => 1;

BEGIN { use_ok( 'Text::CSV::Pivot' ) || print "Bail out!"; }
diag( "Testing Text::CSV::Pivot $Text::CSV::Pivot::VERSION, Perl $], $^X" );
