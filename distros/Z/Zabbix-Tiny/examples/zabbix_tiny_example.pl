#!/usr/bin/env perl
use strict;
use warnings;
use lib "../lib/";
use Zabbix::Tiny;
use IO::Socket::SSL;

use Data::Dumper;

my $url      = $ARGV[0];
my $username = $ARGV[1];
my $password = $ARGV[2];

# Create a new Zabbix::Tiny object
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
);


# Send a JSON-RPC request to the zabbix server (host.get in this case)
my $hosts = $zabbix->do(
    'host.get',  # First argument is the Zabbix API method
    output    => [qw(hostid name host)], # Remaining paramters to 'do' are the params for the zabbix method.
	monitored_hosts	=> 1,
    limit		=> 1,
);

print "JSON request:\n" . $zabbix->json_request . "\n\n";	# Print the json data sent in the last request.
print "JSON response:\n" . $zabbix->json_response . "\n\n";	# Print the json data received in the last response.
print "Auth is: ". $zabbix->auth . "\n";

print "\$zabbix->last_response:\n";
#print Dumper $zabbix->last_response;


print "JSON request:\n" . $zabbix->json_request . "\n"; 
# Very verbose:
#print Dumper $zabbix->post_response;

