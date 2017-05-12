#!/usr/bin/perl

use strict;
use warnings;

use WebService::Linode;
use LWP::Simple;

# yourname.com is a master zone with a resource record of type A named home
# that should point to home IP.

my $apikey = 'your api key';
my $domain = 'yourname.com';
my $record = 'home';
my $ipfile = '/home/username/.lastip';    # file to store last IP between runs

# get public ip
my $pubip = get('http://ip.thegrebs.com/') or exit 1;
my $oldip = `cat  $ipfile`;

for ( $pubip, $oldip ) { chomp if $_ }

# exit if no change
exit 0 if $oldip eq $pubip;

# still running so update A record $record in $domain to point to current
# public ip
my $api = WebService::Linode->new( apikey => $apikey );

my ($domainrec) = grep { $_->{domain} eq $domain } @{ $api->domain_list };
die "Couldn't find domain $domain\n" unless $domainrec;

my ($resourcerec)
    = grep { $_->{name} eq $record }
    @{ $api->domain_resource_list( domainid => $domainrec->{domainid} ) };
die "Couldn't find resource for $record\n" unless $resourcerec;

my $result = $api->domain_resource_update(
    domainid   => $domainrec->{domainid},
    resourceid => $resourcerec->{resourceid},
    target     => $pubip
);
die "Error updating RR :<"
    unless $result->{resourceid} == $resourcerec->{resourceid};

system "echo '$pubip' > $ipfile";
