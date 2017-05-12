#! perl

use strict;
use warnings;

use Test::Lib;
use Test::More;
use Test::Trap;

use pkg::tests;

# test inclusion and exclusion of inner packages by looking for the results
# of a class import.  see inner/import.t for details of how the import affects
# the tattle method.


use pkg 'A' => -inner, -include => qr/A::C/;

for my $pkg ( qw[ A::C A::C::E ] ) {

    test_tattle_called_ok( $pkg, $pkg, "${pkg}::import() called" );
}



for my $pkg ( grep {  $_ ne 'A::C' && $_ ne 'A::C::E' } @A::inner_packages,  @A::other_packages) {

    test_tattle_called_ok( $pkg, 'A::Base', "${pkg}::import() not called" );
}

done_testing;
