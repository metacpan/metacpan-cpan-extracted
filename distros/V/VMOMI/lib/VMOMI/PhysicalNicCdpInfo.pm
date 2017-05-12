package VMOMI::PhysicalNicCdpInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['cdpVersion', undef, 0, 1],
    ['timeout', undef, 0, 1],
    ['ttl', undef, 0, 1],
    ['samples', undef, 0, 1],
    ['devId', undef, 0, 1],
    ['address', undef, 0, 1],
    ['portId', undef, 0, 1],
    ['deviceCapability', 'PhysicalNicCdpDeviceCapability', 0, 1],
    ['softwareVersion', undef, 0, 1],
    ['hardwarePlatform', undef, 0, 1],
    ['ipPrefix', undef, 0, 1],
    ['ipPrefixLen', undef, 0, 1],
    ['vlan', undef, 0, 1],
    ['fullDuplex', 'boolean', 0, 1],
    ['mtu', undef, 0, 1],
    ['systemName', undef, 0, 1],
    ['systemOID', undef, 0, 1],
    ['mgmtAddr', undef, 0, 1],
    ['location', undef, 0, 1],
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
