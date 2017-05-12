#!/usr/bin/perl
#
# publish.pl
#

use WebSphere::MQTT::Client;
#use WebSphere::MQTT::Persist::File;
use Data::Dumper;
use strict;

sub getline($;$);

#
my $mqtt = new WebSphere::MQTT::Client(
	Hostname => 'smartlab.combe.chem.soton.ac.uk',
	Port => 1883,
	Debug => 1,
	#Clientid => 'MyFixedClientId',
	#Clean_start = 0,
        #Persist => WebSphere::MQTT::Persist::File->new('/tmp/wmqtt'),
	#Async => 1,
);

my $qos = 0; # 1

# Connect to Broker
my $res = $mqtt->connect();
die "Failed to connect: $res\n" if ($res);

print Dumper( $mqtt );

while (1) {
  my $data = getline($mqtt, "Enter data:\n");
  last unless $data;
  my $topic = getline($mqtt, "Enter topic:\n");
  last unless $topic;
  my $res = $mqtt->publish($data, $topic, $qos);
  print "Failed to publish: $res\n" if ($res);
}

print "status=".$mqtt->status()."\n";

# Clean up
$mqtt->terminate();

print Dumper( $mqtt );

exit 0;

# Note: we must call the API periodically (and not block on read), otherwise
# the connection will time out

sub getline($;$) {
  my $mqtt = shift;
  my $prompt = shift;

  while(1) {
    $mqtt->status();
    print $prompt if defined $prompt;
    my $rin = '';
    vec($rin,fileno(STDIN),1) = 1;
    my $timeout = 5;
    my ($nfound,$timeleft) = select($rin, undef, undef, $timeout);
    last if $nfound > 0;
  }
  $res = <>;
  chomp($res);
  return $res;
}
