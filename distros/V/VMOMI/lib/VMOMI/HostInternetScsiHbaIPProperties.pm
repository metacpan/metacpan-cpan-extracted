package VMOMI::HostInternetScsiHbaIPProperties;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['mac', undef, 0, 1],
    ['address', undef, 0, 1],
    ['dhcpConfigurationEnabled', 'boolean', 0, ],
    ['subnetMask', undef, 0, 1],
    ['defaultGateway', undef, 0, 1],
    ['primaryDnsServerAddress', undef, 0, 1],
    ['alternateDnsServerAddress', undef, 0, 1],
    ['ipv6Address', undef, 0, 1],
    ['ipv6SubnetMask', undef, 0, 1],
    ['ipv6DefaultGateway', undef, 0, 1],
    ['arpRedirectEnabled', 'boolean', 0, 1],
    ['mtu', undef, 0, 1],
    ['jumboFramesEnabled', 'boolean', 0, 1],
    ['ipv4Enabled', 'boolean', 0, 1],
    ['ipv6Enabled', 'boolean', 0, 1],
    ['ipv6properties', 'HostInternetScsiHbaIPv6Properties', 0, 1],
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
