#!/usr/bin/perl
#
# subscribe.pl
#
# Subscribe to a MQTT topic
# and display message to STDOUT
#

use WebSphere::MQTT::Client;
use Data::Dumper;
use strict;


# 
my $mqtt = new WebSphere::MQTT::Client(
	Hostname => 'smartlab.combe.chem.soton.ac.uk',
	Port => 1883,
	Debug => 1,
);


# Connect to Broker
my $res = $mqtt->connect();
die "Failed to connect: $res\n" if ($res);

print Dumper( $mqtt );


sleep 1;
print "status=".$mqtt->status()."\n";
sleep 1;
print "status=".$mqtt->status()."\n";

# Subscribe to topic
my $res = $mqtt->subscribe( '#' );
print "Subscribe result=$res\n";


sleep 2;
print "status=".$mqtt->status()."\n";
sleep 2;


# Get Messages
while( 1 ) {

	my @res = $mqtt->receivePub();
	#errors can be caught by eval { }
	
	print Dumper(@res);
}



# Unsubscribe from topic
my $res = $mqtt->unsubscribe( '#' );
print "Unubscribe result=$res\n";


sleep 2;

print "status=".$mqtt->status()."\n";

# Clean up
$mqtt->terminate();

print Dumper( $mqtt );

