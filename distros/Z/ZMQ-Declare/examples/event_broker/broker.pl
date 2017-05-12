use strict;
use warnings;
use lib 'lib';
$| = 1;

use ZeroMQ qw(:all);

use EventBroker;

my $eb = EventBroker->new;
my $device = $eb->broker;

$device->implementation(\&main_broker_loop);
$device->run;

my $messages = 0;
sub main_broker_loop {
  my ($runtime) = @_;
  my $listener = $runtime->get_socket_by_name("event_listener");
  my $work_dist = $runtime->get_socket_by_name("work_distributor");

  my $poller = ZeroMQ::Poller->new({
    socket    => $listener,
    events    => ZMQ_POLLIN,
  });

  print "Broker ready, listening for events...\n";
  while (1) {
    $poller->poll();
    my $message = $listener->recv();
    $work_dist->send($message);
    $messages++;
    print "Processed $messages messages.\n" if not $messages % 1000;

    # Instead, if there are multi-part messages:
    # while (1) {
    #   # Process all parts of the message
    #   my $message = $listener->recv();
    #   my $more = $listener->getsockopt(ZMQ_RCVMORE);
    #   $work_dist->send($message, $more ? ZMQ_SNDMORE : 0);
    #   last unless $more;
    # }
  }
}
