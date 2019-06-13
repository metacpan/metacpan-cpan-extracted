#!perl -T

use warnings;
use strict;

use Test::More tests => 6;

use Test::Taint;

taint_checking_ok();
ok( tainted($^X), '$^X is tainted' );

my $foo = 43;
ok( !tainted($foo), '43 is not tainted' );

RESET_SIG_DIE: {
    my $counter = 0;

    local $SIG{__DIE__} = sub { $counter++ };

    ok( tainted($^X), '$^X is tainted' );
    is($counter, 0, 'counter was not incremented (our die did not fire)');

    eval { die 'validly' };
    is($counter, 1, 'counter was incremented (our die fired properly)');
}
