use strict;
use warnings;

use UV::Loop ();
use UV::Signal qw(SIGHUP);

use Test::More;

my $signal_cb_called = 0;

sub signal_cb {
    my $self = shift;
    $signal_cb_called++;
    $self->stop();
    $self->close();
}

my $signal = UV::Signal->new(signal => SIGHUP, on_signal => \&signal_cb);
isa_ok($signal, 'UV::Signal');
my $ret = $signal->start();
is($ret, $signal, '$signal->start returns $signal');

kill SIGHUP => $$;
is(UV::Loop->default()->run(), 0, 'Default loop ran');

is($signal_cb_called, 1, "The Signal callback was run");

done_testing();
