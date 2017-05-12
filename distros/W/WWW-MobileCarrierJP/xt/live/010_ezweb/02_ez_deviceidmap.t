use strict;
use warnings;
use utf8;
use Test::More;
use WWW::MobileCarrierJP::EZWeb::DeviceID;
use LWP::Online ':skip_all';

plan skip_all => "BROKEN";

plan tests => 10;

my $dat = WWW::MobileCarrierJP::EZWeb::DeviceID->scrape;
ok scalar(@$dat) > 30;
is scalar(grep { $_->{device_id} =~ /HTTP/ } @$dat), 0;
is scalar(grep { $_->{device_id} eq '' } @$dat), 0;
is(get_device_id('W43T'), 'TS36', 'single');
is_deeply(get_device_id('W32S'), [qw/SN33 SN35/], 'double');
is(get_device_id('W53SA'), 'ST32', 'single');
is(get_device_id('C3002K'), 'KC21', 'single');
is(get_device_id('C3001H'), 'HI21', 'single');
is(get_device_id('B01K'), 'KC26', 'single');
is(get_device_id('INFOBAR 2'), 'ST33', 'single');

sub get_device_id {
    my $model = shift;
    my ($ret, ) = map { $_->{device_id} } grep { $_->{model} eq $model } @$dat;
    $ret;
}
