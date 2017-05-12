=pod

Based on the "Weather update client" from the 'zguide' at http://zguide.zeromq.org/pl:wuclient

Connects SUB socket to tcp://localhost:5556

Collects weather updates and finds avg temp in zipcode

Original author: Alexander D'Archangel (darksuji) <darksuji(at)gmail(dot)com>

=cut

use strict;
use warnings;

use ZeroMQ qw/:all/;
use ZMQ::Declare;
my $spec = ZMQ::Declare::ZDCF->new(tree => 'weather.zdcf');
my $device = $spec->application("weather")->device('client');

print "Collecting updates from weather server...\n";

$|=1;

my $samples = $ARGV[0]||10;
my $nclients = $ARGV[1]||1;

# Subscribe to a particular zipcode, default is random (after fork)
# set random ZIP code if none supplied
my $filter = sprintf('%05u', $ARGV[2] || rand(100000));

$device->implementation(\&fetch_loop);
$device->run(nforks => $nclients);

sub fetch_loop {
  my ($runtime) = @_;
  my $subscriber = $runtime->get_socket_by_name("subscriber");

  # set subscription filter based on CLI (could be an option in the ZDCF otherwise)
  print "Subscribing to weather updates for ZIP code '$filter'\n";
  $subscriber->setsockopt(ZMQ_SUBSCRIBE, $filter);


  # Process 100 updates
  my $total_temp = 0;
  for (1 .. $samples) {
    print "Fetching sample $_\n";
    my ($zipcode, $temperature, $relhumidity) = split(/ /, $subscriber->recv->data);
    #warn $zipcode;
    $total_temp += $temperature;
  }

  print "Average temperature for zipcode '$filter' was "
        . int($total_temp / $samples) . "\n";
}
