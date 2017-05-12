use strict;
use warnings;
use lib 'lib';
$| = 1;

use ZeroMQ qw(:all);
use Time::HiRes qw(sleep);
use EventBroker;

my $nforks = $ARGV[0] || 1;
print "Spawning $nforks workers!\n";

my $eb = EventBroker->new;
my $device = $eb->worker;

$device->implementation(\&main_worker_loop);
$device->run(nforks => $nforks);

sub main_worker_loop {
  my ($runtime) = @_;
  my $queue = $runtime->get_socket_by_name("work_queue");

  warn "[$$] Worker ready to receive work...\n";

  my $messages = 0;
  my $proc_callback = sub {
    my $msgdata = $queue->recv->data;
    #warn "[$$] Processing work ($msgdata)...";
    # Use the sleep for testing N workers on a small machine:
    sleep($msgdata);
    # Or try some real CPU work:
    #my $start = Time::HiRes::time;
    #while (1) { last if Time::HiRes::time > $start + $msgdata }

    ++$messages;
    print "[$$] Processed $messages messages.\n" if not $messages % 1000;
  };

  my $timeout = 2_000_000; # micro seconds
  while (1) {
    ZeroMQ::Raw::zmq_poll(
      [{
          socket => $queue->socket,
          events => ZMQ_POLLIN,
          callback => $proc_callback,
      }],
      $timeout # any large timeout will be fine, see while(1)
    );
  }
}
