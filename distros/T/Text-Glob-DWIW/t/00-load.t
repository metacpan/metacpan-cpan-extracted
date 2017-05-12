#! /usr/bin/perl -Tw

use strict; use warnings;
use Test::More tests => 1;

BEGIN { use_ok( 'Text::Glob::DWIW' ) || print "Bail out!\n"; }

diag( "Testing Text::Glob::DWIW $Text::Glob::DWIW::VERSION, Perl $], $^X" );
