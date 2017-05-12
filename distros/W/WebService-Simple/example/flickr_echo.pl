use strict;
use warnings;
use WebService::Simple;
use Data::Dumper;

my $api_key = $ARGV[0] || "your_api_key";

my $flickr = WebService::Simple->new(
    base_url => "http://api.flickr.com/services/rest/",
    param    => { api_key => $api_key, }
);

my $response =
  $flickr->get( { method => "flickr.test.echo", name => "value" } );
my $ref = $response->parse_response;
print Dumper $ref;
