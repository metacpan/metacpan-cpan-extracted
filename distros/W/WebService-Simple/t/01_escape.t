use strict;
use Test::More ( tests => 2 );
use utf8;

BEGIN
{
    use_ok("WebService::Simple");
}


{
    my $service = WebService::Simple->new(
        base_url => "http://example.com/api",
    );

    is(
        "?param=%E7%8C%AB",
        $service->request_url( params => { param => "猫" }, ),
        "param is uri escaped",
    );
}

