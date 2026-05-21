use strict;
use warnings;

use Test::More;

use lib 't/lib';

use Test::MockModule 'nostrict';

sub runtime_loose_mock {
    my $m = Test::MockModule->new("lib");
    $m->mock( "abc" => 1 );    # Should fail under T::MM strict mode.
    return 1;
}

use Test::MockModule 'global-strict';

sub strict_off {
    eval { Test::MockModule->import('nostrict') };
    like( "$@", qr/is illegal when GLOBAL_STRICT_MODE /, "An import of Test::MockModule fails if they try to turn off strict after global-strict has been set." );
}

strict_off();

is( eval { runtime_loose_mock() }, undef, "runtime_loose_mock() fails at runtime" );
like( "$@", qr/is illegal when GLOBAL_STRICT_MODE/, "Runtime mock is caught even if nostrict is defined before global-strict is invoked" );

done_testing();
