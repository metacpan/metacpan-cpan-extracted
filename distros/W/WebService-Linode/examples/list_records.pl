#!/usr/bin/perl

use strict;
use warnings;

use WebService::Linode;

my $api = WebService::Linode->new(
    apikey => 'your api key',
    fatal  => 1,
);

for my $domain ( @{ $api->domain_list } ) {
    print "$domain->{domain} $domain->{type}\n";
    next if $domain->{type} eq 'slave';

    print "Records:\n";
    my $rrs = $api->domain_resource_list( domainid => $domain->{domainid} );
    for my $rr (@$rrs) {
        printf( "\t%-10s %5s %-20s\n",
            $rr->{name}, $rr->{type}, $rr->{target} );
    }
}
