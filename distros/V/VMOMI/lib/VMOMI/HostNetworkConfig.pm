package VMOMI::HostNetworkConfig;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vswitch', 'HostVirtualSwitchConfig', 1, 1],
    ['proxySwitch', 'HostProxySwitchConfig', 1, 1],
    ['portgroup', 'HostPortGroupConfig', 1, 1],
    ['pnic', 'PhysicalNicConfig', 1, 1],
    ['vnic', 'HostVirtualNicConfig', 1, 1],
    ['consoleVnic', 'HostVirtualNicConfig', 1, 1],
    ['dnsConfig', 'HostDnsConfig', 0, 1],
    ['ipRouteConfig', 'HostIpRouteConfig', 0, 1],
    ['consoleIpRouteConfig', 'HostIpRouteConfig', 0, 1],
    ['routeTableConfig', 'HostIpRouteTableConfig', 0, 1],
    ['dhcp', 'HostDhcpServiceConfig', 1, 1],
    ['nat', 'HostNatServiceConfig', 1, 1],
    ['ipV6Enabled', 'boolean', 0, 1],
    ['netStackSpec', 'HostNetworkConfigNetStackSpec', 1, 1],
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
