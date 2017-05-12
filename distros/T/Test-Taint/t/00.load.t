#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use Test::Taint;

diag( "Testing Test::Taint $Test::Taint::VERSION, Perl $], $^X" );

pass( 'Module loaded OK' );
