use strict;
use warnings;

use Test::More tests => 3;
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

# Fake sleep for timeout
$time += $timeouts->timeout();

is($timeouts->timeout(), 0, "Timeout was correct after sleep"); 

foreach my $item ($timeouts->handle()) {
  $item->{callme}->();
}

