#!/usr/bin/env perl

use Test::More;
use Test::TestCoverage;
use File::Basename;

my $dir;

BEGIN {
    $dir = dirname __FILE__;
};

use lib $dir;

my $moose_ok = eval "use Moose; 1;" ? 1 : 0;
diag "used Moose: $moose_ok";

SKIP: {
    skip "No Moose", 4 if !$moose_ok;

    use_ok('TestCoverage::Foo');
    test_coverage( 'TestCoverage::Foo' );
    is( TestCoverage::Foo::fortytwo(), 42, "fortytwo" );
    ok_test_coverage( 'TestCoverage::Foo' );
}

done_testing();
