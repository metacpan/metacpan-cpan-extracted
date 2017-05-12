package VMOMI::DVPortgroupConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['configVersion', undef, 0, 1],
    ['name', undef, 0, 1],
    ['numPorts', undef, 0, 1],
    ['portNameFormat', undef, 0, 1],
    ['defaultPortConfig', 'DVPortSetting', 0, 1],
    ['description', undef, 0, 1],
    ['type', undef, 0, 1],
    ['scope', 'ManagedObjectReference', 1, 1],
    ['policy', 'DVPortgroupPolicy', 0, 1],
    ['vendorSpecificConfig', 'DistributedVirtualSwitchKeyedOpaqueBlob', 1, 1],
    ['autoExpand', 'boolean', 0, 1],
    ['vmVnicNetworkResourcePoolKey', undef, 0, 1],
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
