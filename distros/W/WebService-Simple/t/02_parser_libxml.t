use strict;
use Test::More;

my $flickr_api_key = $ENV{FLICKR_API_KEY};
BEGIN
{
    eval { require XML::LibXML };
    if ($@) {
        plan(skip_all => "XML::LibXML not installed");
    } else {
        plan(tests => 7);
    }
    use_ok("WebService::Simple");
}

{
    my $service = WebService::Simple->new(
        base_url => "https://api.flickr.com/services/rest/",
        response_parser => 'XML::LibXML',
        params   => {
            api_key => $flickr_api_key
        }
    );
    isa_ok( $service->response_parser, "WebService::Simple::Parser::XML::LibXML");

    SKIP: {
        if (! $flickr_api_key ) {
            skip( "Please set FLICKR_API_KEY to enable this test", 5 );
        }
    
        my $response = $service->get( { method => "flickr.test.echo", name => "value" } );
        my $xml = $response->parse_response;
    
        isa_ok( $xml, 'XML::LibXML::Document' );
        is( $xml->findvalue( '/rsp/@stat' ), 'ok', '/rsp/@stat' );
        is( $xml->findvalue( '/rsp/api_key' ), $flickr_api_key, '/rsp/api_key', );
        is( $xml->findvalue( '/rsp/name' ), "value", '/rsp/name' );
        is( $xml->findvalue( '/rsp/method' ), 'flickr.test.echo', '/rsp/method' );
    }
}
