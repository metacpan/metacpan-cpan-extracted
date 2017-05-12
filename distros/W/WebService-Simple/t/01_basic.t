use strict;
use Test::More;

my ($flickr_api_key);
BEGIN
{
    $flickr_api_key = $ENV{FLICKR_API_KEY};
    if (! $flickr_api_key ) {
        plan( skip_all => "Please set FLICKR_API_KEY to enable this test" );
    } else {
        plan( tests => 13 );
    }

    use_ok("WebService::Simple");
}

{
    my $simple = WebService::Simple->new(
        base_url => "https://api.flickr.com/services/rest/",
        params   => {
            api_key => $flickr_api_key
        },
    );

    ok($simple, "object created ok");
    isa_ok( $simple, "WebService::Simple", "object isa WebService::Simple" );
    ok( $simple->response_parser, "parser ok" );
    isa_ok( $simple->response_parser, "WebService::Simple::Parser::XML::Simple", "parser isa WebService::Simple::Parser::XML::Simple" );

    my $response = $simple->get( { method => "flickr.test.echo", name => "value" } );

    ok( $response );
    isa_ok( $response, "WebService::Simple::Response" );

    my $h = $response->parse_response;
    ok($h);
    isa_ok($h, 'HASH');

    is( $h->{name}, 'value' );

    # Make sure the response is NOT cached by default
    {
        my $tmp = $simple->get( { method => "flickr.test.echo", name => "value" } );
        isnt( $tmp, $response, "response is NOT cached ($response <=> $tmp)" );
    }
}

SKIP: {
    eval { require Cache::Memory };
    if ($@) {
        skip("Cache::Memory not installed", 2);
    }

    my $called = 0;
    my $simple = WebService::Simple->new(
        base_url => "http://api.flickr.com/services/rest/",
        params   => {
            api_key => $flickr_api_key
        },
        cache => {
            module => 'Cache::Memory',
        }
    );

    my $response;
    for (1..3) {
        my $tmp = $simple->get( { method => "flickr.test.echo", name => "value" } );
        if ($response) {
            is( $tmp, $response, "got cached $response by $tmp" );
        } else {
            $response = $tmp;
        }
    }
}

