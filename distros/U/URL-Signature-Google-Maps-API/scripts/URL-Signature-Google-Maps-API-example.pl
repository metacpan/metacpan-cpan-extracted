#!/usr/bin/perl
use strict;
use warnings;
use URL::Signature::Google::Maps::API;

my $signer     = URL::Signature::Google::Maps::API->new();
my $server     = "http://maps.googleapis.com";
my $path_query = "/maps/api/staticmap?size=600x300&markers=Clifton,VA&sensor=false";
my $url        = $signer->url($server => $path_query);
print "URL: $url\n"
