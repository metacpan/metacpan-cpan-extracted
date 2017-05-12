package VMOMI::HostVirtualNicSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['ip', 'HostIpConfig', 0, 1],
    ['mac', undef, 0, 1],
    ['distributedVirtualPort', 'DistributedVirtualSwitchPortConnection', 0, 1],
    ['portgroup', undef, 0, 1],
    ['mtu', undef, 0, 1],
    ['tsoEnabled', 'boolean', 0, 1],
    ['netStackInstanceKey', undef, 0, 1],
    ['opaqueNetwork', 'HostVirtualNicOpaqueNetworkSpec', 0, 1],
    ['externalId', undef, 0, 1],
    ['pinnedPnic', undef, 0, 1],
    ['ipRouteSpec', 'HostVirtualNicIpRouteSpec', 0, 1],
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
