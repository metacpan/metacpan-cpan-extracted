#!perl

use strict;
use warnings;


=head1 NAME

get_thing.pl - Get Information about a Flattr Thing

=head1 USAGE

    perl get_thing <id>

Where I<< id >> represents the numeric ID of the thing.

=cut

binmode STDOUT, ':utf8';

use WebService::Flattr ();

use Data::Dumper;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = 1;

my $flattr = WebService::Flattr->new;
my $response = $flattr->get_thing($ARGV[0]);
my $thing = $response->data;
#print Dumper $response->http_response;
print Dumper $thing;
print $thing->{description}. "\n";
print "Requests left: ". $response->limit_remaining. "\n";
