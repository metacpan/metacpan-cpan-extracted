#!perl
use Test::More;
use Test::Exception;

use_ok 'WebService::GetSongBPM';

throws_ok { WebService::GetSongBPM->new }
    qr/Missing required arguments: api_key/, 'api_key required';

done_testing();
