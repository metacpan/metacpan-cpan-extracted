package t::anyevent;
use Test::Requires qw(AnyEvent AnyEvent::Impl::Perl);
use parent qw(Test::Class);
use Test::More;
use Test::MockTime::HiRes qw(mock_time);
use Time::HiRes;

use AnyEvent;
use AnyEvent::Impl::Perl;

sub anyevent : Tests {
    my $now = Time::HiRes::time;
    my $called = 0;

    my $cv = AnyEvent->condvar;

    $cv->begin;

    mock_time {
        $cv->begin;
        my $w1; $w1 = AnyEvent->timer(after => 2, cb => sub {
            is $called++, 1;
            $cv->end;
            undef $w1;
        });

        $cv->begin;
        my $w2; $w2 = AnyEvent->timer(after => 1, cb => sub {
            is $called++, 0;
            $cv->end;
            undef $w2;
        });
        sleep(3);
        is Time::HiRes::time(), $now + 3;
    } $now;

    cmp_ok Time::HiRes::time - $now, '<', 2, 'no wait';

    $cv->end;

    mock_time {
        $cv->recv;
    } $now + 3;

    is $called, 2;
    cmp_ok Time::HiRes::time - $now, '<', 2, 'no wait';
}

__PACKAGE__->runtests;
