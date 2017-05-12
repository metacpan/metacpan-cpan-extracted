#! perl

use strict;
use warnings;

use Test::Lib;
use Test::More;
use Test::Trap;

use pkg::tests;

# test calling of the inner packages' import routines
#
# The inner & other packages in A.pm are all derived classes of
# A::Base.  Because of the way the test classes are constructed, their
# specialized routines are only created when their import routines are invoked.
#
# if a classes' import routine has not been called, $class->tattle will
# default to the parent's (A::Base) version and will return 'A::Base'

use pkg 'A' => -inner;

for my $pkg (@A::inner_packages) {

    test_tattle_called_ok( $pkg, $pkg, "${pkg}::import() called" );

}

for my $pkg (@A::other_packages) {

    test_tattle_called_ok( $pkg, 'A::Base', "${pkg}::import() not called" );

}

done_testing;
