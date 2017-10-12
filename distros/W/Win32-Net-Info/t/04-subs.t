use strict;
use warnings;

use Test::More tests => 14;

use Win32::Net::Info qw ( :subs );

my ( $ret, $ret1, $ret2 );

is( ref ( $ret = Win32::Net::Info->interfaces ), 'ARRAY', "Win32::Net::Info->interfaces return ARRAY" );
is( ref ( $ret1 = Win32::Net::Info::interfaces ), 'ARRAY', "Win32::Net::Info::interfaces return ARRAY" );
is( ref ( $ret2 = interfaces ), 'ARRAY', "interfaces return ARRAY" );

my $i = 0;
#for my $i ( 0 .. $#{$ret} ) {
    is( $ret->[$i], $ret1->[$i], "return [$i]: -> = ::" );
    is( $ret->[$i], $ret2->[$i], "return [$i]: -> = [sub]" );
#}

SKIP: {
    skip "developer-only tests - set W32NI_INTERFACE to interface name", 9 unless $ENV{W32NI_INTERFACE};

    my $if;
    is( ref ( $if = Win32::Net::Info->new($ENV{W32NI_INTERFACE}) ), 'Win32::Net::Info', "interface $ENV{W32NI_INTERFACE}" );
    like( $if->mac, qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "interface mac" );

    my $addr;
    # WARN - Net::IPv4Addr bug sends undefined to Carp
    # DIE  - Net::IPv4Addr croaks on error, I prefer to handle nicely
    local $SIG{__WARN__} = sub { return; };
    local $SIG{__DIE__}  = sub { return; };

    like( $if->ipv4_gateway_mac, qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "interface ipv4_gateway_mac" );
    like( $if->ipv4, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "interface ipv4" );
    like( $if->ipv4_default_gateway, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "interface ipv4_default_gateway" );

    SKIP: {
        skip "developer-only tests - set W32I_IPv6", 4 unless $ENV{W32I_IPv6};

        # IPv6:  requires Net::IPv6Addr
        SKIP: {
            eval "use Net::IPv6Addr;";
            skip "use Net::IPv6Addr required", 4 if $@;

            like( $if->ipv6_gateway_mac, qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "interface ipv6_gateway_mac" );
              eval { $addr = Net::IPv6Addr::ipv6_parse($if->ipv6); };
            is( $if->ipv6, $addr, "interface ipv6" );
              eval { $addr = Net::IPv6Addr::ipv6_parse($if->ipv6_link_local); };
            is( $if->ipv6_link_local, $addr, "interface ipv6_link_local" );
              eval { $addr = Net::IPv6Addr::ipv6_parse($if->ipv6_default_gateway); };
            is( $if->ipv6_default_gateway, $addr, "interface ipv6_default_gateway" );
        }
    }
}
