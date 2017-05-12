use Test::More tests => 11;
use strict;
$^W = 1;

BEGIN { use_ok( 'WWW::HostipInfo' ); }

my $hostip = WWW::HostipInfo->new ();
isa_ok ($hostip, 'WWW::HostipInfo');

for my $ip (qw/127.0.0.1 192.168.0.1 172.16.0.1 172.31.0.1 10.0.0.1/){
	my $info = $hostip->get_info($ip);
	ok($info->is_private);
}

my $info = $hostip->get_info('239.0.0.0');
ok(!$info->is_private);
ok($info->has_unknown_country);
ok($info->has_unknown_city);
is($info->code,'XX');
