#!/usr/bin/env perl

use Test::More;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

$ENV{'CALL_COUNT_OUTFILE'} = '/dev/null';   # so Devel::Callcount won't drop a file in the tree
plan tests => 2;
use_ok( 'UR' );
use_ok( 'UR::All' );
note( "Testing UR $UR::VERSION, Perl $], $^X" );

