#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Types::XMLSchema' );
}

diag( "Testing Types::XMLSchema $Types::XMLSchema::VERSION, Perl $], $^X" );
