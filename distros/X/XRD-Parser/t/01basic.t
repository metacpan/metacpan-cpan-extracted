use Test::More tests => 2;
BEGIN { use_ok('XRD::Parser') };

is( XRD::Parser::host_uri('http://example.com/foo/bar'), XRD::Parser::host_uri('example.com'), "host_uri working as expected" );


