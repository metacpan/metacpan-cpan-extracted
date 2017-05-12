package t::core;
use parent qw(Test::Class);
use Test::More;
use Test::MockTime::HiRes qw(mock_time);

sub core : Tests {
    my $now = time;

    mock_time {
        is time, $now;
        sleep 1;
        is time, $now + 1;
    } $now;

    cmp_ok time - $now, '<', 1, 'no wait';
}

__PACKAGE__->runtests;
