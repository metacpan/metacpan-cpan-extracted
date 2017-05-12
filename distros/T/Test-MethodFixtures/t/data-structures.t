use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;

BEGIN {

    package Mocked::Complex;

    our $expensive_call = 0;

    sub array {
        $expensive_call++;

        my @args = @_;

        return reverse @args;
    }

    sub arrayref {
        $expensive_call++;

        my @args = @{ shift() };

        return [ reverse @args ];
    }
}

ok my $mocker
    = Test::MethodFixtures->new( { storage => '+TestMethodFixtures::Dummy' } ),
    "got mocker";

subtest array => sub {

        my @tests = (
            { in => [], out => [] },    #
            { in => [1], out => [1] },
            { in => [ 1, 2 ], out => [ 2, 1 ] },
            {   in => [ 1, 2, [qw/ a b c /] ],
                out => [ [qw/ a b c /], 2, 1 ]
            },
            {   in => [ 1, 2, { foo => 'bar', baz => [qw/ a b c /] } ],
                out => [ { foo => 'bar', baz => [qw/ a b c /] }, 2, 1 ]
            },
        );

        ok $mocker->mock('Mocked::Complex::array'), "mocked array sub";

        run_tests('Mocked::Complex::array', @tests);
};

sub run_tests {
    my ( $method, @tests ) = @_;

    no strict 'refs';

    note $method;

    ok $mocker->mode('record'), "set mode to record";

    my $count = $Mocked::Complex::expensive_call = 0;
    foreach my $test (@tests) {

        is_deeply [ $method->( @{ $test->{in} } ) ],
            $test->{out}, "call mocked function";

        is $Mocked::Complex::expensive_call, ++$count, "called once";
    }

    ok $mocker->mode('playback'), "set mode to playback";

    foreach my $test (@tests) {

        is_deeply [ $method->( @{ $test->{in} } ) ],
            $test->{out}, "call mocked function";

        is $Mocked::Complex::expensive_call, $count,
            "still only called $count times";
    }
}

done_testing();

