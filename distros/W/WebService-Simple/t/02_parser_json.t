use strict;
use Test::More ( tests => 4 );

my $flickr_api_key = $ENV{FLICKR_API_KEY};
BEGIN
{
    use_ok("WebService::Simple");
}

{
    my $service = WebService::Simple->new(
        base_url => "https://api.flickr.com/services/rest/",
        response_parser => 'JSON',
        params   => {
            api_key => $flickr_api_key
        },
    );

    isa_ok( $service->response_parser, "WebService::Simple::Parser::JSON");

    SKIP: {
        if (! $flickr_api_key ) {
            skip( "Please set FLICKR_API_KEY to enable this test", 2 );
        }
    
        my $response = $service->get( { method => "flickr.test.echo", name => "value", format => "json" } );

        # XXX - This is a hack. Flickr returns values as JSONP construct,
        # not as a pure JSON. for our parse_response() to work properly,
        # we need to fix the result first
        ${ $response->content_ref } =~ s/jsonFlickrApi\((.+)\)/$1/;

        my $json = $response->parse_response;
    
        isa_ok( $json, 'HASH' );
        is_deeply(
            $json,
            {
                'name' => { _content => 'value' },
                'method' => { _content => 'flickr.test.echo' },
                'api_key' => { _content => $flickr_api_key },
                'stat' => 'ok',
                'format' => { _content => 'json' },
            }
        );
    }
}
