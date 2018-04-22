use strict;
use warnings;

use UV::Loop ();
use UV::Check ();
use UV::Timer ();

use Test::More;

my $check_cb_called = 0;
my $timer_cb_called = 0;

sub check_cb {
    my $self = shift;
    $check_cb_called++;
    $self->stop;
    $self->close;
}
sub timer_cb {
    my $self = shift;
    $timer_cb_called++;
    $self->stop();
    $self->close();
}

my $check = UV::Check->new(on_check => \&check_cb);
isa_ok($check, 'UV::Check');
is($check->start(), 0, 'check started');
my $timer = UV::Timer->new(on_timer => \&timer_cb);
is($timer->start(0.1, 0), 0, 'Timer started');
is(UV::Loop->default()->run(), 0, 'Loop run');
is($check_cb_called, 1, 'Got the right number of checks');

done_testing();
