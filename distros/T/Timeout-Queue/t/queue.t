use strict;
use warnings;

use Test::More tests => 4;

use Timeout::Queue;

my $timeouts = new Timeout::Queue();
my $id1 = $timeouts->queue(
  timeout => 1, # time out in 1 seconds.
  text => 'First item',
);
my $id2 = $timeouts->queue(
  timeout => 5, # time out in 1 seconds.
  text => 'Last item',
);
my $id3 = $timeouts->queue(
  timeout => 3, # time out in 1 seconds.
  text => 'Second item',
);
my $id4 = $timeouts->queue(
  timeout => 3, # time out in 1 seconds.
  text => 'Third item',
);

ok(@{$timeouts->timeouts()}[0]->{timeout_id} == $id1, 
    "First item was where it should be");
ok(@{$timeouts->timeouts()}[1]->{timeout_id} == $id3, 
    "Second item was where it should be");
ok(@{$timeouts->timeouts()}[2]->{timeout_id} == $id4, 
    "Third item was where it should be");
ok(@{$timeouts->timeouts()}[3]->{timeout_id} == $id2, 
    "Last item was where it should be");

#use Data::Dumper;
#foreach my $item (@{$timeouts->timeouts()}) {
#    print Dumper($item);
#}
