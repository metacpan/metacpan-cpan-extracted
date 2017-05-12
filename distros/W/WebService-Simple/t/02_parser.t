use strict;
use Test::More (tests => 3);

BEGIN
{
    use_ok("WebService::Simple");
}


{
    my $service = WebService::Simple->new(
        base_url => "http://example.com/api",
    );

    isa_ok( $service->{response_parser}, "WebService::Simple::Parser::XML::Simple" );
}

{
    my $service = WebService::Simple->new(
        base_url => "http://example.com/api",
        response_parser => 'JSON'
    );

    isa_ok( $service->{response_parser}, "WebService::Simple::Parser::JSON" );
}