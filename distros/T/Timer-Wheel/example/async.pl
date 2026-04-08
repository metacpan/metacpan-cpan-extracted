# IO::Async integration
use feature qw/say/;
use Timer::Wheel;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;

my $loop = IO::Async::Loop->new;
my $tw   = new Timer::Wheel;
my $tick = IO::Async::Timer::Periodic->new(
    interval => 0.1,
    on_tick  => sub { $tw->tick },
);

$tw->every(5, sub { say "heartbeat" });
$tw->in(30, sub { say "timeout"; $tw->cancel_all; $loop->stop });

$tick->start;
$loop->add($tick);
$loop->run;

