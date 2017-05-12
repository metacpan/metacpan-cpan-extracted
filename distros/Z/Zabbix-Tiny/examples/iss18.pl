#!/usr/bin/env perl
use strict;
use warnings;
use lib "lib/";
use Zabbix::Tiny;

use Modern::Perl;
use Data::Dumper;
use Try::Tiny;
use Data::Printer;

my $url      = $ARGV[0];
my $username = $ARGV[1];
my $password = $ARGV[2];

# Create a new Zabbix::Tiny object
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
);

my $version;
## Testing before Login.
try {
    $version = $zabbix->do(
        'apiinfo.version',
    );
}
catch {
    say "exception:\n $_";
}
finally{
    p $zabbix;
};
exit;


my $execute = $zabbix->execute();
print Dumper $version;
print Dumper $zabbix->json_response;
print $zabbix->auth . "\n";

my $hosts = $zabbix->do(
    'host.get',
    output    => [qw(hostid name host)],
    monitored_hosts => 1,
    limit      => 1,
);

print Dumper $hosts;
print $zabbix->auth . "\n";

#print "JSON request:\n" . $zabbix->json_request . "\n\n";	# Print the json data sent in the last request.
#print "JSON response:\n" . $zabbix->json_response . "\n\n";	# Print the json data received in the last response.
#print "Auth is: ". $zabbix->auth . "\n";

#print "\$zabbix->last_response:\n";
#print Dumper $zabbix->last_response;


#print "JSON request:\n" . $zabbix->json_request . "\n"; 
# Very verbose:
#print Dumper $zabbix->post_response;

