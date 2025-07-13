use strict;
use Test::More;

BEGIN {
    eval { require XML::Feed; };
    if ($@) {
        plan( skip_all => "XML::Feed not installed" );
    }
    else {
        plan( tests => 3 );
    }
    use_ok("WebService::Simple");
}

# Mock RSS content for testing
my $mock_rss = q{<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
<title>Test RSS Feed</title>
<description>Test feed for WebService::Simple</description>
<item>
<title>Test Item</title>
<description>Test description</description>
</item>
</channel>
</rss>};

{
    my $service = WebService::Simple->new(
        response_parser => 'XML::Feed',
        base_url        => "http://example.com/",
    );

    isa_ok( $service->response_parser,
        "WebService::Simple::Parser::XML::Feed" );

    # Create a mock HTTP::Response for testing
    my $mock_response = HTTP::Response->new(200, 'OK');
    $mock_response->content($mock_rss);
    $mock_response->content_type('application/rss+xml');

    # Convert to WebService::Simple::Response
    my $ws_response = WebService::Simple::Response->new_from_response(
        response => $mock_response,
        parser   => $service->response_parser
    );

    my $feed = $ws_response->parse_response();
    like( ref($feed), qr/^(?:XML::Feed::RSS|XML::Feed::Format::RSS)$/ );
}

