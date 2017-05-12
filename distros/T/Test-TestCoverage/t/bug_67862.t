#!perl

use strict;
use warnings;

use File::Basename;
use Test::More;
use Test::TestCoverage;

my $dir;

BEGIN {
    $dir = dirname __FILE__;
};

use lib $dir;

my $moose_ok = eval "use Moose; 1;" ? 1 : 0;

diag "used Moose: $moose_ok";

SKIP: {
    skip "No Moose", 5 if !$moose_ok;
    
    my $class = 'TestCoverage::Foobar';
    test_coverage($class);
    test_coverage_except( $class, qw( BUILD meta ) );
    
    use_ok($class);
    
    my $obj = new_ok( $class => [] );
    
    is( $obj->attr, 'foobar', 'attr is foobar' );
    
    $obj->change;
    is( $obj->attr, 'foobarfoobar', 'attr is foobarfoobar' );
    
    ok_test_coverage($class);
    
}
done_testing();

