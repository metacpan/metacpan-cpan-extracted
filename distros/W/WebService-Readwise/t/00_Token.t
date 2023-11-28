use Test2::V0;

use lib './lib';
use WebService::Readwise;

local %ENV = %ENV;

$ENV{WEBSERVICE_READWISE_TOKEN} = 'foobarbaz';

my $rw = WebService::Readwise->new();
is $rw->token, 'foobarbaz', 'Base url from environment variable';

$rw = WebService::Readwise->new(
    token => 'foo',
);
is $rw->token(), 'foo',  'Token: foo';


done_testing;