use strict;
use warnings;
use XML::Simple;
use WebService::Simple;
use WebService::Simple::Parser::XML::Simple;
use Data::Dumper;

my $api_key = $ARGV[0] || "your_api_key";

my $xs = XML::Simple->new( keyattr => [] );
my $parser = WebService::Simple::Parser::XML::Simple->new( xs => $xs );
my $flickr = WebService::Simple->new(
    base_url => "http://api.flickr.com/services/rest/",
    param    => { api_key => $api_key, },
    response_parser   => $parser,
);

my $response =
  $flickr->get( { method => "flickr.photos.search", text => "cat" } );
print Dumper $response->parse_response;
