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
      pass "I timed out!!";
  }
);

is($timeouts->timeout(), 1, "Timeout was correct");

# Fake sleep for 1 sec
$time += 1;

foreach my $item ($timeouts->handle()) {
  $item->{callme}->();
}

