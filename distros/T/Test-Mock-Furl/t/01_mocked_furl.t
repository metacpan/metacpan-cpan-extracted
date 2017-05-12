use strict;
use warnings;
use Test::More;

use Test::Mock::Furl;

use Furl;

isa_ok $Mock_furl, 'Test::MockObject';

is $Furl::VERSION, 'Mocked';

done_testing;
