#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

use_ok( 'Test::Memory::Cycle' );

diag( "Testing Test::Memory::Cycle $Test::Memory::Cycle::VERSION under Perl $] and Test::More $Test::More::VERSION" );
