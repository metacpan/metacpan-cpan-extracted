#!/usr/bin/env perl
use strict;
use warnings;
use v5.018;
use lib "../lib/";
use Zabbix::Tiny;
use IO::Socket::SSL;

use Data::Dumper;

my $username = $ARGV[1];
my $password = $ARGV[2];
my $url      = $ARGV[0];

my $sleep = 20;

# Create a new Zabbix::Tiny object
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
);
if ($zabbix->auth) {
	say "Auth is " . $zabbix->auth;
}
else {
    say "Auth is not set yet....";
};

# Send a JSON-RPC request to the zabbix server (host.get in this case)
my $hosts = $zabbix->do(
    'host.get',  # First argument is the Zabbix API method
    output    => [qw(hostid name host)], # Remaining paramters to 'do' are the params for the zabbix method.
	monitored_hosts	=> 1,
    limit		=> 1,
);

print Dumper $hosts;

my $count = 1;
print "Sleeping for $sleep seconds\n$count";
$| = 1;
while ($count < $sleep) {
	sleep 1;
	#$count++;
	print "\r" . ++$count;
}
print "\rSending second query\n";
$| = 0;

my $hosts2 = $zabbix->do();
#    'host.get',  # First argument is the Zabbix API method
#    output    => [qw(hostid name host)], # Remaining paramters to 'do' are the params for the zabbix method.
#    monitored_hosts => 1,
#    limit       => 1,
#);

print Dumper $hosts2;


