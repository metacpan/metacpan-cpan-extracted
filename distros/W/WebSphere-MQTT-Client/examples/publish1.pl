#!/usr/bin/perl
#
# publish1.pl
#
# A test of using QOS 1 publishing with callback on successful publish.
# We also set a 'window' of the maximum number of publish messages in-transit.
# This helps avoid the IA93 "Q_FULL" error (more than 32KB in transit)
# and can be used for testing the performance benefit of overlapping publish.
#

use WebSphere::MQTT::Client;
use Data::Dumper;
use Time::HiRes qw ( sleep time );
use strict;

#
my $mqtt = new WebSphere::MQTT::Client(
	Hostname => 'smartlab.combe.chem.soton.ac.uk',
	Port => 1883,
	Debug => 1,
	#Clientid => 'MyFixedClientId',
	#Clean_start = 0,
	#Async => 1,
);

my $qos = 1;
my $window = 20;

# Connect to Broker
my $res = $mqtt->connect();
die "Failed to connect: $res\n" if ($res);

print Dumper( $mqtt );

my $t1 = time;

for (my $i=0; $i<100; $i++) {
  while ($mqtt->txQueueSize >= $window) { sleep(0.1); }
  my $data="xxx";
  my $topic="yyy";
  my $res = $mqtt->publish($data, $topic, $qos, 0, \&cb, $i);
  print "Failed to publish: $res\n" if ($res);
}

print "status=".$mqtt->status()."\n";

# Wait for remaining ACKs, disconnect and clean up
$mqtt->terminate();

my $t2 = time;
print "Time elapsed: " . ($t2-$t1) . "\n";

exit 0;

sub cb {
  my ($status, $arg) = @_;
  print "Callback: status=$status, arg=$arg\n";
}
