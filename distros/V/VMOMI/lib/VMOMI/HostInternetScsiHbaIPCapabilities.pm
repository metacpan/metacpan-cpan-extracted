package VMOMI::HostInternetScsiHbaIPCapabilities;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['addressSettable', 'boolean', 0, ],
    ['ipConfigurationMethodSettable', 'boolean', 0, ],
    ['subnetMaskSettable', 'boolean', 0, ],
    ['defaultGatewaySettable', 'boolean', 0, ],
    ['primaryDnsServerAddressSettable', 'boolean', 0, ],
    ['alternateDnsServerAddressSettable', 'boolean', 0, ],
    ['ipv6Supported', 'boolean', 0, 1],
    ['arpRedirectSettable', 'boolean', 0, 1],
    ['mtuSettable', 'boolean', 0, 1],
    ['hostNameAsTargetAddress', 'boolean', 0, 1],
    ['nameAliasSettable', 'boolean', 0, 1],
    ['ipv4EnableSettable', 'boolean', 0, 1],
    ['ipv6EnableSettable', 'boolean', 0, 1],
    ['ipv6PrefixLengthSettable', 'boolean', 0, 1],
    ['ipv6PrefixLength', undef, 0, 1],
    ['ipv6DhcpConfigurationSettable', 'boolean', 0, 1],
    ['ipv6LinkLocalAutoConfigurationSettable', 'boolean', 0, 1],
    ['ipv6RouterAdvertisementConfigurationSettable', 'boolean', 0, 1],
    ['ipv6DefaultGatewaySettable', 'boolean', 0, 1],
    ['ipv6MaxStaticAddressesSupported', undef, 0, 1],
);

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
