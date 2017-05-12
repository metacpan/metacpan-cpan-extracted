package VMOMI::HostNetworkInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vswitch', 'HostVirtualSwitch', 1, 1],
    ['proxySwitch', 'HostProxySwitch', 1, 1],
    ['portgroup', 'HostPortGroup', 1, 1],
    ['pnic', 'PhysicalNic', 1, 1],
    ['vnic', 'HostVirtualNic', 1, 1],
    ['consoleVnic', 'HostVirtualNic', 1, 1],
    ['dnsConfig', 'HostDnsConfig', 0, 1],
    ['ipRouteConfig', 'HostIpRouteConfig', 0, 1],
    ['consoleIpRouteConfig', 'HostIpRouteConfig', 0, 1],
    ['routeTableInfo', 'HostIpRouteTableInfo', 0, 1],
    ['dhcp', 'HostDhcpService', 1, 1],
    ['nat', 'HostNatService', 1, 1],
    ['ipV6Enabled', 'boolean', 0, 1],
    ['atBootIpV6Enabled', 'boolean', 0, 1],
    ['netStackInstance', 'HostNetStackInstance', 1, 1],
    ['opaqueSwitch', 'HostOpaqueSwitch', 1, 1],
    ['opaqueNetwork', 'HostOpaqueNetworkInfo', 1, 1],
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
