use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Timeout::Queue;

# Fake timer 
my $time = time;

pass "Skiped at the moment";
exit;

use Time::HiRes qw(gettimeofday usleep);

# TODO: To use highres we need to implement support for expires in arrays??

my ($seconds, $microseconds) = gettimeofday;
print "$seconds, $microseconds\n";
($seconds, $microseconds) = gettimeofday;
print "$seconds, $microseconds\n";

my $timeouts = new Timeout::Queue( Time => sub { return  gettimeofday; } );
my $id1 = $timeouts->queue(
  timeout => 1, # time out in 1 seconds.
  text => 'First item',
);

use Data::Dumper;
foreach my $item (@{$timeouts->timeouts()}) {
    print Dumper($item);
}
