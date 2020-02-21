#!perl

use strict;
use warnings;

use Scalar::Util qw(weaken);

use Test::Ratchet qw(ratchet clank);
use Test::MockModule;
use Test::Most 'no_plan';
use Try::Tiny;

subtest "Clank runs" => sub {
    my $clank = clank sub {
        ok "Clank runs";
    };
    $clank->();
};

subtest "Clank doesn't run" => sub {
    my $testmock = Test::MockModule->new('Test::More');
    $testmock->mock('fail', sub { like $_[0], qr/A Clank was never run/, "Test failed!" } );

    do {
        my $closure_tm = $testmock;
        weaken $closure_tm;
        my $clank = clank sub {
            $closure_tm->unmock('fail');
            fail "Clank ran!";
        }
    };

    # This seems to ensure $testmock hangs around but $clank is destroyed.
    # Otherwise I guess Perl thinks both scopes end at the same time and does
    # them in the wrong order.
    pass "Scope closed...";
};

subtest "Clank in a ratchet" => sub {
    subtest "Everything runs" => sub {
        my $ratchet = ratchet(
            clank sub { ok "Clank1" },
            clank sub { ok "Clank2" }
        );

        $ratchet->();
        $ratchet->();
    };

    subtest "One doesn't run" => sub {
        my $testmock = Test::MockModule->new('Test::More');
        $testmock->mock('fail', sub { like $_[0], qr/A Clank was never run/, "Test failed!" } );

        do {
            my $ratchet = ratchet(
                sub { note "Not a clank" }, # Can't be an ok or TODO would be sad
                clank sub { ok "Clank2" }
            );

            $ratchet->();
        };

        pass "Scope closed...";
    }
};

done_testing;
