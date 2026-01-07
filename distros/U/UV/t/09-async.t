use v5.14;
use warnings;

use UV::Loop ();
use UV::Async ();

use Test::More;

my $async_cb_called = 0;

sub async_cb {
    my $self = shift;
    $async_cb_called++;
    $self->close();
}

my $async = UV::Async->new(on_async => \&async_cb);
isa_ok($async, 'UV::Async');

$async->send;

is(UV::Loop->default()->run(), 0, 'Default loop ran');

is($async_cb_called, 1, "The async callback was run");

done_testing();
