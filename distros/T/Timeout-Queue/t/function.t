use strict;
use warnings;

use Test::More tests => 1;

# Fake timer 
my $time = time;

use Timeout::Queue qw(queue_timeout handle_timeout get_timeout);

my @timeouts;
my $timeout;
my $timeout_id = 0;

queue_timeout(\@timeouts, time,
  timeout_id => ++$timeout_id,
  timeout => 1, # time out in 1 seconds.
  callme => sub {
      pass "I timed out!!\n";
  }
);

# Get the first timeout
$timeout = get_timeout(\@timeouts, $time);

# Fake sleep 1 sec
$time += 1;

foreach my $item (handle_timeout(\@timeouts, $time)) {
  $item->{callme}->();
}

# Get the next timeout 
$timeout = get_timeout(\@timeouts, $time);
