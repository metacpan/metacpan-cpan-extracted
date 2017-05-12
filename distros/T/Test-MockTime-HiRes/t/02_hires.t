package t::hires;
use parent qw(Test::Class);
use Test::More;
use Test::MockTime::HiRes qw(mock_time);

sub hires__time_and_sleep : Tests {
    require Time::HiRes;

    subtest 'original' => sub {
        my $now = Time::HiRes::time;
        Time::HiRes::sleep 0.1;
        cmp_ok $now, '<', Time::HiRes::time;
    };

    subtest 'mock' => sub {
        my $now = Time::HiRes::time;

        mock_time {
            is Time::HiRes::time(), $now;
            sleep 1;
            is Time::HiRes::time(), $now + 1, "sleep() works";
            Time::HiRes::sleep 1;
            is Time::HiRes::time(), $now + 2, "Time::HiRes::sleep() works";
            Time::HiRes::usleep(1_000_000);
            cmp_ok Time::HiRes::time() - ($now + 3), '<', 0.000_005, "Time::HiRes::usleep() works";
            Time::HiRes::nanosleep(1_000_000_000);
            cmp_ok Time::HiRes::time() - ($now + 4), '<', 0.000_005, "Time::HiRes::nanosleep() works";
        } $now;

        cmp_ok Time::HiRes::time() - $now, '<', 2, 'no wait';
    };
}

sub hires__gettimeofday : Tests {
    require Time::HiRes;

    subtest 'original' => sub {
        my $core_time = time;
        Time::HiRes::sleep 0.1;
        my $scalar_context = Time::HiRes::gettimeofday();
        my $array_context = [ Time::HiRes::gettimeofday() ];

        cmp_ok $scalar_context, '>', $core_time;
        cmp_ok $array_context->[0], '>=', $core_time;
        is $array_context->[0], int($array_context->[0]), 'integer part';
        cmp_ok $array_context->[1], '<', 1_000_000;

        like $array_context->[1], qr/\A[0-9]+\Z/, 'fraction part is integer';

        Time::HiRes::sleep 0.3;
        like [ Time::HiRes::gettimeofday() ]->[1], qr/\A[0-9]+\Z/, 'fraction part is still integer after sleep';
    };

    subtest 'mock' => sub {
        my $now = Time::HiRes::time;

        mock_time {
            my $core_time = time;
            my $scalar_context = Time::HiRes::gettimeofday();
            my $array_context = [ Time::HiRes::gettimeofday() ];

            is $scalar_context, $now;
            is $array_context->[0], $core_time;
            is $array_context->[0], int($array_context->[0]), 'integer part';
            ok (($array_context->[1] > 1_000_000 * ($now - $core_time) - 1) && ($array_context->[1] < 1_000_000 * ($now - $core_time) +1), 'fraction part' );
            like $array_context->[1], qr/\A[0-9]+\Z/, 'fraction part is integer';

            Time::HiRes::sleep 0.3;
            my $array_context_after_sleep = [ Time::HiRes::gettimeofday() ];
            is Time::HiRes::tv_interval($array_context, $array_context_after_sleep), 0.3,
                'increases by 0.3 secs.';
        } $now;
    };
}

__PACKAGE__->runtests;
