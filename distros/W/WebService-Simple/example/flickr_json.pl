use strict;
use warnings;
use WebService::Simple;
use Data::Dumper;

my $flickr = WebService::Simple->new(
    base_url        => "http://api.flickr.com/services/rest/",
    response_parser => 'JSON',
    params          => { api_key => $ARGV[0], format => "json" }
);

my $response =
  $flickr->get( { method => "flickr.photos.search", text => "cat" } );
print Dumper $response->parse_response;
