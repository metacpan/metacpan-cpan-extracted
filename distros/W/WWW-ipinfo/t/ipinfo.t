use strict;
use warnings;
use Test::More;
use Test::RequiresInternet 0.03 ( 'ipinfo.io' => 80 );

BEGIN { use_ok 'WWW::ipinfo' }

ok my $info = get_ipinfo(), 'get_ipinfo works';
like $info->{ip}, qr/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/,
    'ip address in expected format';

# other parameters like postal code, region are not always provided by ipinfo
ok exists $info->{ip}, 'has ip';
ok exists $info->{country}, 'has country';

ok my $other_info = get_ipinfo('FE80::0202:B3FF:FE1E:8329'), 'get IPv6 address';
ok exists $info->{ip}, 'has IP';

done_testing();
