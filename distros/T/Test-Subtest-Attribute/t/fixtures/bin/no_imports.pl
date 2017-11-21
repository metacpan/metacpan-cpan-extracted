use strict;
use warnings;

use Test::More;
use Test::Subtest::Attribute qw();


sub subtest_foo :Subtest {
    ok( 1, 'Dummy subtest foo' );
    return 1;
}

sub subtest_bar :Subtest( 'name for bar' ) {
    ok( 1, 'Dummy subtest bar' );
    return 1;
}

Test::Subtest::Attribute->run();

done_testing();
