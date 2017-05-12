use strict;
use warnings;

use Test::More tests => 2;

use Timeout::Queue;

# Fake timer 
my $time = time;

my $timeouts = new Timeout::Queue( Time => sub { return $time; });
$timeouts->queue(
  timeout => 1, # time out in 1 seconds.
  callme => sub {
      pass "I timed out!!\n";
  }
);

# Fake sleep for 1 sec
$time += 1;

is($timeouts->timeout(), 0, "We don't need to sleep anymore");

foreach my $item ($timeouts->handle()) {
  $item->{callme}->();
}

