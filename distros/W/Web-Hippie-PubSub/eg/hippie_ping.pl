#!/usr/bin/env perl

# posts a "ping" message on your hippie server.
# to see if your clients are receiving the message, do:
#   curl -v http://localhost:4000/_hippie/mxhr/ping
# and watch.

use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use Data::Dumper;

# set to your hippie server
my $root = "http://localhost:4000/_hippie";

# connect
my $ua = LWP::UserAgent->new;
my $res = $ua->get("$root/mxhr/ping", ':content_cb' => \&init);

my $boundary;
sub init {
    my ($body) = @_;

    # first chunk is the boundary
    unless ($boundary) {
        $boundary = $body;
        return;
    }

    # parse response parts, get client_id
    my ($init_part) = split($boundary, $body);
    my (undef, $init) = split("\n\n", $init_part);
    my $init_parsed = eval { JSON::from_json($init); };
    my $client_id = $init_parsed->{client_id} or die "Failed to get client_id";

    # post ping message
    my $message = JSON::to_json({ type => 'ping', 'time' => time() });
    my $post_ua = LWP::UserAgent->new;
    my $res2 = $post_ua->post("$root/pub/ping", { 'message' => $message, client_id => $client_id });
    print $res2->content . "\n";

    exit 0;
}
