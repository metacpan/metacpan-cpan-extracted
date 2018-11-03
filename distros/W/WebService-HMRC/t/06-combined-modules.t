#!perl -T
use strict;
use warnings;
use Test::More;
use WebService::HMRC::Request;
use WebService::HMRC::Authenticate;

plan tests => 4;

# There is an interdependency between WebService::HMRC::Request and
# WebService::HMRC::Authenticate modules - Authenticate inherits from
# Request, but Request must sometimes instantiate an Authenticate class.
#
# In version 0.01, this could cause initialisation problems when both
# modules were used in the same script, depending on which order they were
# use-ed. This test exercises that condition to confirm that it has been
# fixed since version 0.02.

my $request =  WebService::HMRC::Request->new(
    base_url => 'http://request.example',
);
isa_ok($request, 'WebService::HMRC::Request', 'request object instantiated');

my $auth =  WebService::HMRC::Authenticate->new(
    base_url => 'http://authenticate.example',
);
isa_ok($auth, 'WebService::HMRC::Authenticate', 'auth object instantiated');


is($request->base_url, 'http://request.example', 'request base_url property initialised');
is($auth->base_url, 'http://authenticate.example', 'auth base_url property initialised');

