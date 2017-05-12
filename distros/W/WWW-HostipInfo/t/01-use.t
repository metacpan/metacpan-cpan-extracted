use Test::More tests => 15;
use strict;
use Socket;

BEGIN { use_ok( 'WWW::HostipInfo' ); }

my $hostip = WWW::HostipInfo->new ();
isa_ok ($hostip, 'WWW::HostipInfo');

my $addr = gethostbyname('www.hostip.info');
my $ip   = $addr ? inet_ntoa( $addr ) : undef;

diag( 'IP : ' . $ip );
SKIP: { skip "an ip address of '$addr' can't be defined.", 10 unless $ip;

# We hope that this test can get a data from www.hostip.info.

my $info = $hostip->get_info($ip);

isa_ok($info, 'WWW::HostipInfo::Info');

is($ip, $info->ip);

ok(! $info->is_private);
ok(! $info->is_guessed);

if ( $info->country_code eq 'XX' ) {
    ok($info->has_unknown_country);
}
else {
    ok(!$info->has_unknown_country);
}

ok($info->country_code, $info->country_code);
is($info->country_code, $info->code);
is($info->country_name, $info->country);

#ok($info->city);
#ok($info->region);

#like($hostip->recent_info->country_name, qr/^.+?[^\s]*$/);
#like($info->latitude, qr/^-?[.\d]+$/);
#like($info->longitude, qr/^-?[.\d]+$/);
is($hostip->recent_info, $info);

$info->{_ipaddr} = 'aa';
is($info->ip, 'aa');
is($info->ip, $hostip->recent_info->ip);

is(WWW::HostipInfo->new($ip)->ip, $ip);

$hostip->ip("");
eval q| $hostip->get_info() |;

like($@, qr/IP address is required/i);

}
