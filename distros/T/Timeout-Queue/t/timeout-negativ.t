use strict;
use warnings;

use Test::More tests => 1;
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

# Fake sleep for 1 sec
$time += 2;

is($timeouts->timeout(), 0, "Timeout was correct");
