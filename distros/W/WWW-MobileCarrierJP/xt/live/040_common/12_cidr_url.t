use strict;
use warnings;
use Test::More;
use LWP::Online ":skip_all";
plan skip_all => "BROKEN";
plan tests => 4*1;

my @carrier = qw/EZWeb DoCoMo AirHPhone Softbank/;
for my $carrier (@carrier) {
    my $class = "WWW::MobileCarrierJP::${carrier}::CIDR";

    eval "use $class"; ## no critic.
    die $@ if $@;

    my $url = $class->url;
    ok $url =~ /^http/;
;
}
