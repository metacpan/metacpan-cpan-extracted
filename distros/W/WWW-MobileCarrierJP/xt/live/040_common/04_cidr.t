use t::Utils;
use Test::More;
use LWP::Online ":skip_all";
use Data::Dumper;
plan skip_all => "BROKEN";

my %dat = ();
for my $class (modules('CIDR')) {
    subtest $class => sub {
        note "Testing $class";
        my $dat = $class->scrape;
        is ref($dat), 'ARRAY', "$class : type check";
        ok( scalar(@$dat) >= 3, 'cidr should be higher than 4' )
          or diag( Dumper( $class->url(), $dat ) );
        is scalar(grep /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/, map { $_->{ip} } @$dat), scalar(@$dat);
        is scalar(grep m{^/[0-9]+$}, map { $_->{subnetmask} } @$dat), scalar(@$dat);
        $dat{$class} = $dat;
    };
}

my $e = $dat{'WWW::MobileCarrierJP::EZWeb::CIDR'};
is scalar(grep { $_->{ip} eq '61.117.0.128'} @$e), 0, '廃止されたものは無視';

my $d = $dat{'WWW::MobileCarrierJP::DoCoMo::CIDR'};
is scalar(grep { $_->{ip} eq '210.153.87.0' && $_->{subnetmask} eq '/24'} @$d), 0, 'WEBアクセスは除外';
is scalar(grep { $_->{ip} eq '203.138.181.0' && $_->{subnetmask} eq '/24'} @$d), 0, 'メール送信IP-1除外';
is scalar(grep { $_->{ip} eq '203.138.181.0' && $_->{subnetmask} eq '/24'} @$d), 0, 'メール送信IP-2除外';
is scalar(grep { $_->{ip} eq '203.138.203.0' && $_->{subnetmask} eq '/24'} @$d), 0, 'メール受信IP除外';

subtest 'airh' => sub {
    my @airh = map { "$_->{ip}$_->{subnetmask}" } @{$dat{'WWW::MobileCarrierJP::AirHPhone::CIDR'}};
    for my $expected (qw(
        61.198.139.128/27
        221.119.8.0/24
        221.119.9.0/24
        210.255.190.0/24
    )) {
        is scalar(grep { $_ eq $expected } @airh), 1, "exists $expected"
            or diag(join "\n", @airh);
    }
    for my $ip (qw(
        114.21.255.0/27
    )) {
        is scalar(grep { $_ eq $ip } @airh), 0, "removed $ip";
    }
};

done_testing;

