use strict;
use warnings;
use lib 'lib';
$| = 1;

use Data::Dumper;
use Time::HiRes qw(sleep usleep);

use EventBroker;

my $broker = EventBroker->new;
my $event_sock = $broker->client_socket;

print "Client ready, sending a bunch of events...\n";

my $total = 0;
for (1..100000) {
  my $work = rand(0.1);
  $event_sock->send($work);
  $total += $work;
  usleep(10); # a message every ~10 microseconds (plus overhead)
}
print "Sent a total of $total seconds of work!\n";
sleep 1; # allow for 0MQ to catch up? (FIXME there must be a better way)


