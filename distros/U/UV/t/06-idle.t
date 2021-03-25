use strict;
use warnings;

use UV::Loop ();
use UV::Idle ();

use Test::More;

my $idle_cb_called = 0;

sub idle_cb {
    my $self = shift;
    $idle_cb_called++;
    $self->stop();
    $self->close();
}

my $idle = UV::Idle->new(on_idle => \&idle_cb);
isa_ok($idle, 'UV::Idle');
my $ret = $idle->start();
is($ret, $idle, '$idle->start returns $idle');

is(UV::Loop->default()->run(), 0, 'Default loop ran');

is($idle_cb_called, 1, "The Idle callback was run");

done_testing();
