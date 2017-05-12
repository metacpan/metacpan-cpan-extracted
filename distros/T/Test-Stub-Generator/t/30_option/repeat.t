use strict;
use warnings;

use Test::More;
use Test::Stub::Generator qw(make_subroutine make_repeat_subroutine);

subtest 'use option' => sub {
    my $repeat = make_subroutine(
        { expects => [0], return => 1 },
        { is_repeat => 1 },
    );
    is( &$repeat(0), 1, 'repeat 1' );
    is( &$repeat(0), 1, 'repeat 2' );
};

subtest 'use method' => sub {
    my $repeat = make_repeat_subroutine { expects => [0], return => 1 };
    is( &$repeat(0), 1, 'repeat 1' );
    is( &$repeat(0), 1, 'repeat 2' );
};

done_testing;
