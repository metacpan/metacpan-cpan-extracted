#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Vue::Crud' ) || print "Bail out!\n";
}

diag( "Testing Vue::Crud $Vue::Crud::VERSION, Perl $], $^X" );
