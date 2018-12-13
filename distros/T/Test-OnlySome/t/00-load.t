#!perl
package T0;

use rlib 'lib';
use DTest;

# Do everything in the BEGIN per perldoc Test::More, which says
# that 'the notion of "compile-time" is relative.'
BEGIN {
    use_ok( 'Test::OnlySome' ) || print "Bail out!\n";

    diag( "Testing Test::OnlySome $Test::OnlySome::VERSION, Perl $], $^X" );

    ok(T0->can('__TOS_all'), '__TOS_all() was imported');

    done_testing();
}
