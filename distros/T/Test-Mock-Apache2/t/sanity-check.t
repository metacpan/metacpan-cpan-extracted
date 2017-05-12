use strict;
use warnings;

BEGIN {
    use Test::Mock::Apache2;
}

use Test::More tests => 8;

# Check that our Apache request mockery is working
# according to the usual API

my $r = Apache2::RequestUtil->request();
ok($r, 'Apache2::RequestUtil->request() returns an object');
isa_ok($r, 'Apache2::RequestRec');

my $apr_ap2 = APR::Request::Apache2->handle($r);
ok($apr_ap2, 'APR::Request::Apache2->handle($r) works');
isa_ok($apr_ap2, 'APR::Request::Apache2');

Test::Mock::Apache2->cookie_jar({ cookie1 => 'value1' });

my $jar = $apr_ap2->jar;
ok($jar, 'Got an object from APR::Request::Apache2->jar()');
isa_ok($jar, "APR::Request::Cookie::Table", "looks like a cookie table");
ok(exists $jar->{cookie1}, "quacks like one too");
is($jar->{cookie1}, 'value1', "got back our fake cookie value");

# End

