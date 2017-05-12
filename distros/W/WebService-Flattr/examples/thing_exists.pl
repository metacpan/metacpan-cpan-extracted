#!perl

use strict;
use warnings;

=head1 NAME

thing_exists.pl - Discover whether Flattr already knows about a URL

=head1 USAGE

    perl thing_exists <url>

Where I<< url >> represents the URL of the thing.

=cut

binmode STDOUT, ':utf8';

use WebService::Flattr ();

use Data::Dumper;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = 1;

my $flattr = WebService::Flattr->new;
my $response = $flattr->thing_exists($ARGV[0]);
my $thing = $response->data;
#print Dumper $response->http_response;
print Dumper $thing;
print "Requests left: ". $response->limit_remaining. "\n";
