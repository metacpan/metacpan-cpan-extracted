use strict;
use warnings;
use WebService::Simple;
use Data::Dumper;

my $hatenastar = WebService::Simple->new(
    base_url        => "http://s.hatena.ne.jp/blog.json/",
    response_parser => 'JSON',
);

my $response = $hatenastar->get( "http://d.hatena.ne.jp/hatenastar/",
			     { callback => "callback" } );

print Dumper $response->parse_response;
