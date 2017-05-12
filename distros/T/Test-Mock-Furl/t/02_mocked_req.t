use strict;
use warnings;
use Test::More;

use Test::Mock::Furl::Request;

use Furl::Request;

isa_ok $Mock_furl_req, 'Test::MockObject';
isa_ok $Mock_furl_request, 'Test::MockObject';

is $Furl::Request::VERSION, 'Mocked';

done_testing;
