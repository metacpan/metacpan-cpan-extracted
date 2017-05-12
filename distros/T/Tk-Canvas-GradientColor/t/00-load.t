#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tk::Canvas::GradientColor' ) || print "Bail out!\n";
}

diag( "Testing Tk::Canvas::GradientColor $Tk::Canvas::GradientColor::VERSION, Perl $], $^X" );
