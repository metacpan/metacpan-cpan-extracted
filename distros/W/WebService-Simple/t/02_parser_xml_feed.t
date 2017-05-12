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

{
    my $service = WebService::Simple->new(
        response_parser => 'XML::Feed',
        base_url        => "http://search.cpan.org/uploads.rdf",
    );

    isa_ok( $service->response_parser,
        "WebService::Simple::Parser::XML::Feed" );

    my $response = $service->get( {} );
    my $feed = $response->parse_response;
    like( ref($feed), qr/^(?:XML::Feed::RSS|XML::Feed::Format::RSS)$/ );
}

