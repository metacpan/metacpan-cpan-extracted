use strict;
use warnings;
use Test::More;

use Test::Mock::Furl::Response;

use Furl::Response;

isa_ok $Mock_furl_res, 'Test::MockObject';
isa_ok $Mock_furl_resp, 'Test::MockObject';
isa_ok $Mock_furl_response, 'Test::MockObject';

is $Furl::Response::VERSION, 'Mocked';

done_testing;
