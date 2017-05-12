use strict;
use warnings;

use Test::More tests => 6;

use Timeout::Queue;

# Fake timer 
my $time = time;

my $timeouts = new Timeout::Queue( Time => sub { return $time; });
my $id1 = $timeouts->queue(
  timeout => 1, # time out in 1 seconds.
  text => 'First item',
);
my $id2 = $timeouts->queue(
  timeout => 1, # time out in 1 seconds.
  text => 'Second item',
);
my $id3 = $timeouts->queue(
  timeout => 1, # time out in 1 seconds.
  text => 'Third item',
);
ok($id1 == 1, "First timeout_id is 1");
ok($timeouts->handle() == 0, "Nothing has timeout yet");
$timeouts->delete(timeout_id => $id2);
ok(@{$timeouts->timeouts()}[1]->{expires} == 0, "Item $id2 has been marked for deletion");
$timeouts->delete(timeout_id => $id1);
ok(@{$timeouts->timeouts()} == 1, "Both delete items was removed from the queue");
$timeouts->delete(timeout_id => 10);
ok(@{$timeouts->timeouts()} == 1, "Delete on non existing item worked");
$timeouts->delete(timeout_id => $id3);
ok(@{$timeouts->timeouts()} == 0, "Delete with only one worked");

#use Data::Dumper;
#foreach my $item (@{$timeouts->timeouts()}) {
#    print Dumper($item);
#}
