#!/usr/bin/env perl

use uni::perl;
use lib::abs '../lib';
use Test::More tests => 2;
use Test::NoWarnings;
BEGIN { use_ok( 'Variable::Eject' ); }
diag( "Testing Variable::Eject $Variable::Eject::VERSION, Perl $], $^X" );
