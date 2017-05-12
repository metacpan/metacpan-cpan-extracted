=pod

Based on the "Weather update server" from the 'zguide' at http://zguide.zeromq.org/pl:wuserver

Binds PUB socket to tcp://*:5556

Publishes random weather updates

Original author: Alexander D'Archangel (darksuji) <darksuji(at)gmail(dot)com>

=cut

use strict;
use warnings;

use ZeroMQ qw/:all/;
use ZMQ::Declare;
use Time::HiRes qw(sleep);

sub within {
  my ($upper) = @_;
  return int(rand($upper)) + 1;
}

# Prepare our context and publisher
my $spec = ZMQ::Declare::ZDCF->new(tree => 'weather.zdcf');
my $device = $spec->application("weather")->device('server');

$| = 1;
print "Serving...\n";

$device->implementation(\&server_loop);
$device->run();

sub server_loop {
  my ($runtime) = @_;
  my $publisher = $runtime->get_socket_by_name("publisher");
  
  while (1) {
    # Get values that will fool the boss
    my $zipcode     = within(100000);
    my $temperature = within(215) - 80;
    my $relhumidity = within(50) + 10;

    # Send message to all subscribers
    my $update = sprintf('%05d %d %d', $zipcode, $temperature, $relhumidity);
    #print "Sending update $update\n";
    $publisher->send($update);
    #sleep 0.001;
  }
}
