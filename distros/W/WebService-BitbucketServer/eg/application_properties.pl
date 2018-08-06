#!/usr/bin/env perl

use warnings FATAL => 'all';
use strict;

use Data::Dumper;
use WebService::BitbucketServer;

my $host = shift or die 'Need server url';
my $user = shift or die 'Need username';
my $pass = shift or die 'Need password';

my $api = WebService::BitbucketServer->new(
    base_url => $host,
    username => $user,
    password => $pass,
);

my $response = $api->core->get_application_properties;

if (my $err = $response->error) {
    my $raw = $response->raw;
    print STDERR "Call failed: $raw->{status} $raw->{reason}\n";
    print STDERR Dumper($err);
    exit 1;
}

my $app_info = $response->data;
print "Making API calls to: $app_info->{displayName} $app_info->{version}\n";

