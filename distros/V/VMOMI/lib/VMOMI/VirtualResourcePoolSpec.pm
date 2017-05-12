package VMOMI::VirtualResourcePoolSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vrpId', undef, 0, 1],
    ['vrpName', undef, 0, 1],
    ['description', undef, 0, 1],
    ['cpuAllocation', 'VrpResourceAllocationInfo', 0, ],
    ['memoryAllocation', 'VrpResourceAllocationInfo', 0, ],
    ['rpList', 'ManagedObjectReference', 1, 1],
    ['hubList', 'ManagedObjectReference', 1, 1],
    ['rootVRP', 'boolean', 0, 1],
    ['staticVRP', 'boolean', 0, 1],
    ['changeVersion', undef, 0, 1],
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
