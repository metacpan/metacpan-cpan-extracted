use strict;
use warnings;

use UV::Loop ();
use UV::Signal ();

use Test::More;

use POSIX qw(SIGHUP);

my $signal_cb_called = 0;

sub signal_cb {
    my $self = shift;
    $signal_cb_called++;
    $self->stop();
    $self->close();
}

my $signal = UV::Signal->new(signal => SIGHUP, on_signal => \&signal_cb);
isa_ok($signal, 'UV::Signal');
$signal->start();

kill SIGHUP => $$;
is(UV::Loop->default()->run(), 0, 'Default loop ran');

is($signal_cb_called, 1, "The Signal callback was run");

done_testing();
