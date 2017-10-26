#!/usr/bin/env perl

use warnings FATAL => 'all';
use strict;

use Data::Dumper;
use Mojo::IOLoop;
use Mojo::UserAgent;
use WebService::BitbucketServer;

my $host = shift or die 'Need server url';
my $user = shift or die 'Need username';
my $pass = shift or die 'Need password';

my $api = WebService::BitbucketServer->new(
    base_url => $host,
    username => $user,
    password => $pass,
    ua       => Mojo::UserAgent->new,
);

my $future = $api->core->get_application_properties;

$future->on_done(sub {
    my $app_info = shift->data;
    print "Making API calls to: $app_info->{displayName} $app_info->{version}\n";
});

$future->on_fail(sub {
    my $response = shift;
    my $raw = $response->raw;
    print STDERR "Call failed: $raw->{status} $raw->{reason}\n";
    print STDERR Dumper($response->error);
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
