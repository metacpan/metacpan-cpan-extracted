use strict;
use Test::More;

my $flickr_api_key = $ENV{FLICKR_API_KEY};
BEGIN
{
    eval {
        require XML::Parser::Lite::Tree;
        require XML::Parser::Lite::Tree::XPath;
    };
    if ($@) {
        plan(skip_all => "XML::Parser::Lite::Tree not installed");
    } else {
        plan(tests => 7);
    }
    use_ok("WebService::Simple");
}

{
    my $service = WebService::Simple->new(
        base_url => "https://api.flickr.com/services/rest/",
        response_parser => 'XML::Lite',
        params   => {
            api_key => $flickr_api_key
        }
    );
    isa_ok( $service->response_parser, "WebService::Simple::Parser::XML::Lite");

    SKIP: {
        if (! $flickr_api_key ) {
            skip( "Please set FLICKR_API_KEY to enable this test", 5 );
        }
    
        my $response = $service->get( { method => "flickr.test.echo", name => "value" } );
        my $xml = $response->parse_response;
    
        isa_ok( $xml, 'XML::Parser::Lite::Tree::XPath' );
        is( $xml->select_nodes( '/rsp' )->[-1]{attributes}{stat}, 'ok', '/rsp and @stat' );
        is( $xml->select_nodes( '/rsp/api_key' )->[-1]{children}[0]{content}, $flickr_api_key, '/rsp/api_key', );
        is( $xml->select_nodes( '/rsp/name' )->[-1]{children}[0]{content}, "value", '/rsp/name' );
        is( $xml->select_nodes( '/rsp/method' )->[-1]{children}[0]{content}, 'flickr.test.echo', '/rsp/method' );
    }
}
