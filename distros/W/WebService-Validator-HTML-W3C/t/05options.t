# $Id$

use Test::More tests => 6;
use WebService::Validator::HTML::W3C;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new( agent => "test/1.0" );

my $v = WebService::Validator::HTML::W3C->new(
            validator_uri   =>  'http://example.com/',
            http_timeout    =>  10,
        );

ok($v, 'object created');
is($v->validator_uri(), 'http://example.com/', 'correct uri set');
is($v->http_timeout(), 10, 'correct http timeout set');

$v = WebService::Validator::HTML::W3C->new(
            validator_uri   =>  'http://example.com/',
            http_timeout    =>  10,
            ua              =>  $ua,
     );

ok($v, 'object created with custom user agent');
is($v->ua()->agent(), 'test/1.0', 'correct user agent set');
is($v->ua()->timeout(), 180, 'timeout argument not used when user agent set');

