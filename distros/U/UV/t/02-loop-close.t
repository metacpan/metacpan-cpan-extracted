use v5.14;
use warnings;

use Test::More;
use UV;
use UV::Loop;
use UV::Timer;

{
    my $loop = UV::Loop->new();
    isa_ok($loop, 'UV::Loop', 'UV::Loop->new(): got a new Loop');

    my $timer = UV::Timer->new(loop => $loop);
    isa_ok($timer, 'UV::Timer', 'timer: got a new timer');

    $timer->start(100, 100, sub {
        my $self = shift;
        isa_ok($self, 'UV::Timer', 'Got our timer in the callback');
        $self->loop()->stop();
    });

    #is($loop->close(), UV::UV_EBUSY, 'loop->close: Returns EBUSY');

    #$loop->run();

    $timer->close(undef);

    is($loop->run(), 0, 'loop run: got zero');
}
done_testing();
