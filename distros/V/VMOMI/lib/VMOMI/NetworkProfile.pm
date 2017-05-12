package VMOMI::NetworkProfile;
use parent 'VMOMI::ApplyProfile';

use strict;
use warnings;

our @class_ancestors = ( 
    'ApplyProfile',
    'DynamicData',
);

our @class_members = ( 
    ['vswitch', 'VirtualSwitchProfile', 1, 1],
    ['vmPortGroup', 'VmPortGroupProfile', 1, 1],
    ['hostPortGroup', 'HostPortGroupProfile', 1, 1],
    ['serviceConsolePortGroup', 'ServiceConsolePortGroupProfile', 1, 1],
    ['dnsConfig', 'NetworkProfileDnsConfigProfile', 0, 1],
    ['ipRouteConfig', 'IpRouteProfile', 0, 1],
    ['consoleIpRouteConfig', 'IpRouteProfile', 0, 1],
    ['pnic', 'PhysicalNicProfile', 1, 1],
    ['dvswitch', 'DvsProfile', 1, 1],
    ['dvsServiceConsoleNic', 'DvsServiceConsoleVNicProfile', 1, 1],
    ['dvsHostNic', 'DvsHostVNicProfile', 1, 1],
    ['netStackInstance', 'NetStackInstanceProfile', 1, 1],
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
