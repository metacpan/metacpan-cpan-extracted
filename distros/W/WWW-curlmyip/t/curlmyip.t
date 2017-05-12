use strict;
use warnings;
use Test::More;
use Test::RequiresInternet 0.03 ( 'curlmyip.com' => 80 );

BEGIN { use_ok 'WWW::curlmyip' }

ok my $ip = get_ip(), 'get_ip works';
like $ip, qr/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/,
    'ip address in expected format';

done_testing();
