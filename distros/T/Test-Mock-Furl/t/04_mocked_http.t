use strict;
use warnings;
use Test::More;

use Test::Mock::Furl::HTTP;

use Furl::HTTP;

isa_ok $Mock_furl_http, 'Test::MockObject';

is $Furl::HTTP::VERSION, 'Mocked';

done_testing;