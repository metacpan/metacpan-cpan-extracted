use warnings;
use strict;

use Test::More;
use Test::Warnings qw< :no_end_test had_no_warnings >;

use_ok('Test::OpenID::Server');
my $s   = Test::OpenID::Server->new;
my $URL = $s->started_ok("start server");

use_ok('Test::WWW::Mechanize');
my $mech = Test::WWW::Mechanize->new;

$mech->get_ok( "$URL/unknown", "fetch non-identity page" );
$mech->content_lacks( "OpenID identity page for identity", "got non-identity page" );
$mech->content_lacks( "$URL/openid.server", "doesn't include server URL" );

$mech->get_ok( "$URL/test", "fetch identity page" );
$mech->content_contains( "OpenID identity page for test", "got identity page" );
$mech->content_contains( "$URL/openid.server", "contains correct server URL" );

$mech->get_ok( "$URL/openid.server", "fetch openid server endpoint" );
$mech->content_contains( "OpenID Endpoint", "got openid server endpoint" );

had_no_warnings("Caught no warnings");
done_testing();
