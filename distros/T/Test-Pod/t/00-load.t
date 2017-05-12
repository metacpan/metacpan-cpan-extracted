#!perl -T

use warnings;
use strict;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Test::Pod' );
    use_ok( 'Pod::Simple' );
}

diag( "Testing Test::Pod $Test::Pod::VERSION, Perl $], $^X" );
diag( "Using Pod::Simple $Pod::Simple::VERSION" );
